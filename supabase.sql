-- =====================================================================
-- Nomina — konta użytkowników (Supabase)
-- Wklej całość w Supabase: SQL Editor → New query → Run.
-- Skrypt można uruchomić ponownie: niczego nie usuwa ani nie dubluje.
-- =====================================================================

-- Profil: nick widoczny w rankingu (e-mail nigdy nie jest publiczny)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nick text not null,
  created_at timestamptz not null default now(),
  constraint nick_format check (char_length(nick) between 3 and 20 and nick ~ '^[A-Za-z0-9ĄĆĘŁŃÓŚŹŻąćęłńóśźż_.-]+$')
);
create unique index if not exists profiles_nick_unique on public.profiles (lower(nick));

-- Zdjęcie profilowe (od wersji 1.0.3): ścieżka pliku w Storage, np. <id>/avatar.jpg?v=1732712345
alter table public.profiles add column if not exists avatar text;
alter table public.profiles drop constraint if exists avatar_path;
alter table public.profiles add constraint avatar_path
  check (avatar is null or avatar ~ ('^' || id::text || '/avatar\.jpg\?v=[0-9]{1,15}$'));

-- Postępy nauki (prywatne — widzi je tylko właściciel)
create table if not exists public.progress (
  user_id uuid primary key references auth.users (id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

-- Statystyki do rankingu (jedna linia na dział: kości / więzadła)
create table if not exists public.stats (
  user_id uuid not null references auth.users (id) on delete cascade,
  sec text not null check (sec in ('kosci', 'wiezadla')),
  known int not null default 0 check (known between 0 and 5000),
  total int not null default 0 check (total between 0 and 5000),
  best_exam int not null default 0 check (best_exam between 0 and 100),
  exams int not null default 0 check (exams between 0 and 100000),
  streak int not null default 0 check (streak between 0 and 10000),
  updated_at timestamptz not null default now(),
  primary key (user_id, sec),
  constraint known_le_total check (known <= total)
);

alter table public.profiles enable row level security;
alter table public.progress enable row level security;
alter table public.stats enable row level security;

drop policy if exists "profiles: każdy czyta" on public.profiles;
create policy "profiles: każdy czyta" on public.profiles for select to anon, authenticated using (true);
drop policy if exists "profiles: właściciel zmienia" on public.profiles;
create policy "profiles: właściciel zmienia" on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

drop policy if exists "progress: tylko właściciel" on public.progress;
create policy "progress: tylko właściciel" on public.progress for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "stats: każdy czyta" on public.stats;
create policy "stats: każdy czyta" on public.stats for select to anon, authenticated using (true);
drop policy if exists "stats: właściciel dodaje" on public.stats;
create policy "stats: właściciel dodaje" on public.stats for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "stats: właściciel zmienia" on public.stats;
create policy "stats: właściciel zmienia" on public.stats for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

grant select on public.profiles, public.stats to anon, authenticated;
grant update (nick, avatar) on public.profiles to authenticated;
grant select, insert, update on public.progress to authenticated;
grant insert, update on public.stats to authenticated;

-- Ranking: nick + statystyki; seria dni liczy się tylko, jeśli ktoś uczył się w ostatnich 2 dniach
create or replace view public.ranking with (security_invoker = on) as
  select p.nick, s.sec, s.known, s.total, s.best_exam, s.exams,
         case when s.updated_at >= now() - interval '48 hours' then s.streak else 0 end as streak,
         s.updated_at, p.avatar
  from public.stats s join public.profiles p on p.id = s.user_id;
grant select on public.ranking to anon, authenticated;

-- Nowe konto → profil z nickiem podanym przy rejestracji
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, nick)
  values (new.id, coalesce(nullif(trim(new.raw_user_meta_data ->> 'nick'), ''), 'user_' || substr(new.id::text, 1, 8)));
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- Czy nick jest wolny (sprawdzane przed rejestracją)
create or replace function public.nick_available(n text) returns boolean
language sql stable security definer set search_path = '' as $$
  select not exists (select 1 from public.profiles where lower(nick) = lower(trim(n)));
$$;
grant execute on function public.nick_available(text) to anon, authenticated;

-- Usunięcie własnego konta (razem z postępami i wpisem w rankingu)
create or replace function public.delete_user() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  delete from auth.users where id = auth.uid();
end $$;
revoke execute on function public.delete_user() from public, anon;
grant execute on function public.delete_user() to authenticated;

-- Zdjęcia profilowe: publiczny folder „avatars” (każdy może obejrzeć zdjęcie, zmienić tylko własne).
-- Jeden plik na osobę: <id>/avatar.jpg, maks. 512 KB, tylko JPG (aplikacja sama kadruje i zmniejsza zdjęcie).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 524288, array['image/jpeg'])
on conflict (id) do update set public = true, file_size_limit = 524288, allowed_mime_types = array['image/jpeg'];

drop policy if exists "avatars: własne czyta" on storage.objects;
create policy "avatars: własne czyta" on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and name = (select auth.uid())::text || '/avatar.jpg');
drop policy if exists "avatars: własne dodaje" on storage.objects;
create policy "avatars: własne dodaje" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and name = (select auth.uid())::text || '/avatar.jpg');
drop policy if exists "avatars: własne zmienia" on storage.objects;
create policy "avatars: własne zmienia" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and name = (select auth.uid())::text || '/avatar.jpg')
  with check (bucket_id = 'avatars' and name = (select auth.uid())::text || '/avatar.jpg');
drop policy if exists "avatars: własne usuwa" on storage.objects;
create policy "avatars: własne usuwa" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and name = (select auth.uid())::text || '/avatar.jpg');
