# Lexor — sistem za evidenciju radnog vremena, obračun plata i informisanje o radničkim pravima

Lexor objedinjuje evidenciju prisustva zasnovanu na RFID tehnologiji, obračun plata prema propisima
Federacije BiH, digitalni tok zahtjeva za odsustvo, detekciju prevara u evidenciji metodom mašinskog
učenja i chatbot koji uposlenike informiše o njihovim pravima iz radnog zakonodavstva.
Razvijen je za predmet **Razvoj softvera II** (FIT Mostar) i sastoji se od REST API-ja, pomoćnog
worker servisa, desktop administrativne aplikacije i mobilne aplikacije za uposlenike.

## Funkcionalnosti

- **Uposlenici, ugovori, odjeli, pozicije** — CRUD i referentni podaci.
- **Prisustvo (RFID)**, **zahtjevi za odsustvo** (state machine: `Pending → Approved/Rejected → Completed/Cancelled`) i **obračun plata** (`Pending → Approved → Paid`).
- **PDF izvještaji** (QuestPDF) u desktop aplikaciji — zbirni izvještaj plata i platna lista pojedinca (računovodstvo) te mjesečni izvještaj evidencije radnog vremena (HR).
- **AI chatbot** nad pravnim dokumentima (RAG: lokalni embeddingi + Groq LLM).
- **ML detekcija prevara** u evidenciji radnog vremena (binarna klasifikacija, logistička regresija) — vidi [ml-dokumentacija.md](ml-dokumentacija.md).
- **Obavijesti kompanije** i **notifikacije** uposleniku (status odsustva, odobrena i isplaćena platna lista).
- **Aktivacija naloga e-mailom, reset lozinke, zaštita od brute-force napada i rate limiting.**

## Tehnologije

- **Backend:** .NET 9, ASP.NET Core, EF Core 9, SQL Server, RabbitMQ (EasyNetQ), ML.NET, MailKit, QuestPDF, ImageSharp.
- **Desktop i mobilna aplikacija:** Flutter.
- **Infrastruktura:** Docker / docker-compose.

## Arhitektura (servisi)

| Servis | Uloga |
|---|---|
| `Lexor.WebAPI` | Glavni REST API (desktop + mobilni klijent). Objavljuje poruke na RabbitMQ. |
| `Lexor.Subscriber` | Pomoćni worker (zaseban kontejner) — sluša RabbitMQ: šalje aktivacijske e-mailove i kodove za reset lozinke, kreira notifikacije o statusu odsustva i platnih lista, indeksira pravne dokumente i automatski zatvara istekla odsustva. |
| `lexor-db` | SQL Server baza. |
| `lexor-rabbitmq` | RabbitMQ posrednik poruka. |

---

## Preduslovi

- [Docker Desktop](https://www.docker.com/)
- [.NET 9 SDK](https://dotnet.microsoft.com/) (za lokalni razvoj)
- [Flutter](https://flutter.dev/) (za desktop/mobilnu aplikaciju)

## Konfiguracija (.env)

Tajne se čuvaju u `.env` datotekama (nisu u gitu). Kopiraj priložene `.env.example` u `.env` i popuni vrijednosti:

```bash
cp Lexor/.env.example Lexor/.env
cp Lexor/Lexor.WebAPI/.env.example Lexor/Lexor.WebAPI/.env
cp Lexor/Lexor.Subscriber/.env.example Lexor/Lexor.Subscriber/.env
```

Popuni najmanje: `DB_SA_PASSWORD`, `RABBITMQ_USER`/`RABBITMQ_PASSWORD` (korijenski `.env`), `JwtToken__SecretKey`, `Groq__ApiKey` i SMTP podatke (`Smtp__*`) u `Lexor.Subscriber/.env`.

Korijenski `Lexor/.env` koristi docker-compose za `${...}` zamjene, a `Lexor.WebAPI/.env` i `Lexor.Subscriber/.env` se koriste kada servisi rade izvan Dockera.

> **Pri predaji** je svaki `.env` zamijenjen arhivom `.env-tajne.zip` u istom folderu. Šifra
> arhive predata je putem DL sistema. Postoje tri arhive i svaka sadrži jedan `.env`:
>
> | Arhiva | `.env` mora završiti ovdje |
> |---|---|
> | `Lexor/.env-tajne.zip` | `Lexor/.env` |
> | `Lexor/Lexor.WebAPI/.env-tajne.zip` | `Lexor/Lexor.WebAPI/.env` |
> | `Lexor/Lexor.Subscriber/.env-tajne.zip` | `Lexor/Lexor.Subscriber/.env` |
>
> Svaki `.env` mora stajati **uz `.env.example` u istom folderu**. Najbrže je raspakovati sve
> tri odjednom — PowerShell iz foldera `Lexor/`, `tar` je ugrađen u Windows:
>
> ```powershell
> foreach ($d in @('.', 'Lexor.WebAPI', 'Lexor.Subscriber')) {
>   tar -xf "$d\.env-tajne.zip" -C $d --passphrase 'SIFRA-IZ-DL-SISTEMA'
> }
> ```
>
> Na Linuxu i macOS-u isto radi sa `unzip -P 'SIFRA' "$d/.env-tajne.zip" -d "$d"`.
>
> Ako umjesto toga koristite Explorer i opciju „Extract All", ona pravi podfolder `.env-tajne\`
> i `.env` smjesti u njega — tada ga pomjerite jedan nivo gore. Kada `.env` nije na pravom
> mjestu, `docker compose` javlja `env file ... .env not found`.
>
> Nakon toga se aplikacija pokreće bez ikakvih dodatnih izmjena.

---

## Pokretanje

### Opcija A — Cijeli sistem u Dockeru (preporučeno za pregled)

Iz foldera `Lexor/`:

```bash
docker compose up -d --build
```

Ovim se dižu sva 4 servisa. API na startu automatski primjenjuje migracije i puni bazu demo podacima
(30 uposlenika, ~3 godine historije prisustva). API je dostupan na `http://localhost:5170`.

Zaustavljanje:

```bash
docker compose down          # zadržava podatke
docker compose down -v       # briše i bazu (čist start)
```

### Opcija B — Backend lokalno, infrastruktura u Dockeru (za razvoj)

```bash
docker compose up -d lexor-db lexor-rabbitmq
dotnet run --project Lexor.WebAPI
dotnet run --project Lexor.Subscriber
```

### Desktop aplikacija (Windows)

```bash
cd Lexor/UI/lexor_desktop
flutter run -d windows
```
API adresa se čita iz `String.fromEnvironment('API_BASE_URL')` (default `http://localhost:5170`).
Za drugačiji port: `flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5170`.

### Mobilna aplikacija (Android emulator)

```bash
cd Lexor/UI/lexor_mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5170
```
`10.0.2.2` je standardna adresa hosta iz Android emulatora.

> Napomena: docker-compose izlaže API na portu **5170** (`5170:8080`), usklađeno sa default adresom aplikacija.

---

## Korisnički podaci za pristup

Sve lozinke su `Test123!`.

| Kontekst | Rola | Korisničko ime |
|---|---|---|
| Desktop | HR menadžer | `hr.menadzer@lexor.ba` |
| Desktop | Računovodstvo | `racunovodstvo@lexor.ba` |
| Desktop | Računovodstvo (druga osoba) | `racunovodstvo2@lexor.ba` |
| Desktop | Administrator | `admin@lexor.ba` |
| Mobilna | Uposlenik | `ime.prezime@lexor.ba` (npr. `amina.hodzic@lexor.ba`) |

> Dva računovodstvena naloga postoje zbog segregacije dužnosti (maker-checker): istu platu ne mogu odobriti i isplatiti ista osoba — jedan odobrava, drugi isplaćuje.

Desktop aplikacija razdvaja ovlasti po roli:

- **HR menadžer** — uposlenici, evidencija prisustva, zahtjevi za odsustvo, detekcija prevara, izvještaji, obavijesti.
- **Računovodstvo** — obračun plata, postavke obračuna, izvještaji, pregled uposlenika bez prava izmjene.
- **Administrator** — korisnički nalozi i uloge, RFID kartice, referentni podaci, pravni dokumenti, obavijesti.

Uposlenici pristupaju isključivo mobilnoj aplikaciji.

Primjeri uposlenika: `amina.hodzic@lexor.ba`, `emir.kovacevic@lexor.ba`, `lejla.begic@lexor.ba`, `tarik.delic@lexor.ba` — svi sa lozinkom `Test123!`.

---

## Testovi

```bash
dotnet test Lexor/Lexor.Tests
```
Integracijski test provjerava rate limiting na login endpointu (11. zahtjev u minuti vraća HTTP 429).
