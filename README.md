# Nomina

**Nauka anatomii do kolokwium — kości i więzadła po łacinie i po polsku.**
Stworzone przez **Poziomka Studio**.

Aplikacja pokazuje strukturę wskazaną szpilką na rycinie, a Ty wpisujesz jej nazwę po łacinie i po polsku.

## Co potrafi

- **Szpilki** — rozpoznawanie struktur: wpisywanie nazwy, wybór z czterech albo wskazywanie szpilki na rycinie; powtórki tego, co sprawia trudność.
- **Kolokwium** — próbne stanowiska na czas, wynik i omówienie na końcu.
- **Atlas** — ryciny z ponumerowanymi strukturami, wyszukiwanie i podświetlanie (np. wszystkie kolce na miednicy).
- **Struktury** — do której kości lub stawu należy dana struktura.
- **Postępy** — co już umiesz, czego trzeba powtórzyć, historia kolokwiów.
- Dwa działy: **Kości** (osteologia) i **Więzadła** (syndesmologia).

- **Konto** (opcjonalnie) — rejestracja e-mailem i hasłem, nick, **zdjęcie profilowe**, profil z wynikami, **ranking**
  (opanowane struktury, najlepsze kolokwium, seria dni) i postępy wspólne dla telefonu i komputera.

Bez konta postępy zapisują się w przeglądarce (localStorage) na danym urządzeniu.

## Co nowego — wersja 1.0.3

- Zdjęcie profilowe: wybór zdjęcia, kadrowanie w aplikacji, widoczne w profilu, zakładce i rankingu.
- Nowy wygląd konta: zakładki Profil, Ranking i Ustawienia; postęp działów na paskach.
- Ranking ze zdjęciami, medalami dla podium i Twoim miejscem na górze.
- Podgląd hasła, ocena siły hasła i sprawdzanie wolnego nicku od razu przy wpisywaniu.

**Aktualizacja z 1.0.2:** uruchom jeszcze raz cały `supabase.sql` w Supabase (SQL Editor → Run) —
dodaje miejsce na zdjęcia. Bez tego wszystko działa dalej, tylko bez zdjęć profilowych.

### Wersja 1.0.2

- Konta (nick, e-mail, hasło) i postępy wspólne dla telefonu i komputera.
- Ranking: opanowane struktury, najlepsze kolokwium, seria dni — osobno dla kości i więzadeł.
- Profil z wynikami i ostatnimi kolokwiami.
- Pewniejszy zapis postępów: nauka bez internetu wysyła się później, zmiany z kilku urządzeń łączą się.
- Okienko „Co nowego” po każdej aktualizacji (i link „co nowego?” w stopce).

## Jak uruchomić

Wystarczy otworzyć `index.html` w przeglądarce albo opublikować repozytorium przez GitHub Pages
(Settings → Pages → Deploy from a branch → `main` / root).

## Konta i ranking — konfiguracja Supabase (jednorazowo, ok. 10 minut)

Konta działają na darmowym planie [Supabase](https://supabase.com). Dopóki `config.js` jest pusty,
aplikacja działa jak dawniej — bez zakładki **Konto**.

1. **Projekt.** Załóż konto na supabase.com → **New project**. Nazwa np. `Nomina`, region **Central EU (Frankfurt)**,
   ustaw hasło do bazy (zapisz je gdzieś, aplikacja go nie potrzebuje).
2. **Baza danych.** W projekcie: **SQL Editor** → **New query** → wklej całą zawartość pliku `supabase.sql` → **Run**.
   Powinno pojawić się „Success. No rows returned”. Jeśli Supabase zapyta o „destructive operation”, kliknij
   **Run this query** — skrypt usuwa tylko swoje stare zasady dostępu, żeby założyć je od nowa.
   (Skrypt można uruchamiać ponownie — niczego nie psuje. Uruchom go po każdej aktualizacji Nominy.)
3. **Adres strony.** **Authentication** → **URL Configuration**:
   - **Site URL**: `https://kajtulax.github.io/Nomina/`
   - **Redirect URLs** → **Add URL**: `https://kajtulax.github.io/Nomina/`

   Bez tego linki z e-maili (aktywacja konta, reset hasła) nie wrócą do aplikacji.
4. **Potwierdzanie e-maila.** **Authentication** → **Sign In / Providers** → **Email** → **Confirm email**.
   Wbudowana poczta Supabase wysyła tylko kilka wiadomości na godzinę dla całego projektu, dlatego na start
   najlepiej **wyłączyć** „Confirm email” — konto działa od razu po rejestracji. Reset hasła nadal przychodzi e-mailem.
   Gdy użytkowników będzie dużo, podłącz własną pocztę: **Authentication** → **Emails** → **SMTP Settings**
   (np. darmowy plan Resend albo Brevo) i wtedy możesz włączyć potwierdzanie z powrotem.
5. **Klucze.** **Project Settings** → **API Keys** (albo **Data API**): skopiuj **Project URL**
   (np. `https://abcdefgh.supabase.co`) oraz klucz **publishable** (`sb_publishable_…`) albo starszy **anon public**.
   **Nigdy** nie wklejaj klucza **secret** ani **service_role** — ten daje pełny dostęp do bazy.
6. **config.js.** Na GitHubie otwórz plik `config.js` → ikona ołówka → wpisz obie wartości → **Commit changes**:
   ```js
   window.NOMINA_SUPABASE = {
     url: 'https://abcdefgh.supabase.co',
     key: 'sb_publishable_…'
   };
   ```
   Po 1–2 minutach (GitHub Pages) w aplikacji pojawi się zakładka **Konto**.

**Bezpieczeństwo.** Klucz publishable/anon jest z założenia publiczny — dane chronią zasady dostępu (RLS) z `supabase.sql`:
postępy widzi tylko ich właściciel, w rankingu widać wyłącznie nick i wyniki, e-mail nigdy nie jest publiczny.
Wyniki w rankingu wylicza przeglądarka użytkownika, więc to ranking „na słowo honoru”.

**Dobrze wiedzieć.**
- Darmowy projekt Supabase usypia się po tygodniu bez żadnego ruchu — wtedy w panelu Supabase kliknij **Restore project**.
  W tym czasie aplikacja działa dalej, a postępy czekają w przeglądarce i wyślą się po ponownym połączeniu.
- Treść e-maili (aktywacja, reset hasła) zmienisz na polską w **Authentication** → **Emails** → **Templates**.
  Link musi zostać w postaci `{{ .ConfirmationURL }}`, np. dla „Reset Password”:
  ```html
  <h2>Nowe hasło do Nominy</h2>
  <p>Kliknij, aby ustawić nowe hasło: <a href="{{ .ConfirmationURL }}">ustaw nowe hasło</a></p>
  <p>Jeśli to nie Ty prosiłeś o zmianę hasła, zignoruj tę wiadomość.</p>
  ```
- Zdjęcia profilowe leżą w **Storage → avatars** (jedno małe zdjęcie JPG na osobę, ok. 5–30 KB; darmowy plan ma 1 GB).
  Nieodpowiednie zdjęcie usuniesz tam ręcznie.
- Użytkownika (np. z nieodpowiednim nickiem) usuniesz w **Authentication** → **Users** — razem z jego postępami i wpisem w rankingu.

## Ryciny i licencje

- **Ryciny kości** (pliki w `img/` bez przedrostka `lg_`, poza `sac_gl`, `sac_gs`, `tal_ga`, `tal_gi`, `cal_gl`, `cal_gm`, `cal_gi`): BodyParts3D / Anatomography,
  © The Database Center for Life Science, licencja
  [CC BY-SA 2.1 JP](https://creativecommons.org/licenses/by-sa/2.1/jp/deed.en), przez
  [Wikimedia Commons](https://commons.wikimedia.org/wiki/Category:Anatomography).
  Ryciny przycięte, część przebarwiona. Zmienione ryciny udostępniane są na tej samej licencji (CC BY-SA 2.1 JP).
- **Ryciny więzadeł** (pliki `img/lg_*`) oraz ryciny `img/sac_gl.jpg`, `img/sac_gs.jpg`, `img/tal_ga.jpg`, `img/tal_gi.jpg`, `img/cal_gl.jpg`, `img/cal_gm.jpg`, `img/cal_gi.jpg`: H. Gray, *Anatomy of the Human Body* (1918), domena publiczna, przez
  [Wikimedia Commons](https://commons.wikimedia.org/wiki/Category:Gray%27s_Anatomy_plates).
  Oryginalne podpisy usunięte.

Szpilki i podpisy są rysowane przez aplikację na rycinach.
