# lexor_desktop

Administrativna (back-office) Flutter aplikacija sistema **Lexor**, za Windows. Koriste je
HR menadžer, računovodstvo i administrator; uposlenici pristupaju isključivo mobilnoj aplikaciji.

## Pokretanje

Backend mora biti pokrenut (vidi [README u korijenu repozitorija](../../../README.md)).

```bash
flutter run -d windows
```

Adresa API-ja se čita iz `String.fromEnvironment('API_BASE_URL')`, sa podrazumijevanom
vrijednošću `http://localhost:5170`. Za drugi port:

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5170
```

Build za predaju:

```bash
flutter build windows --release
```

Rezultat je u `build/windows/x64/runner/Release/`.

## Podjela po ulogama

| Uloga | Ekrani |
|---|---|
| HR menadžer | Uposlenici, prisustvo, zahtjevi za odsustvo, detekcija prevara, izvještaji, obavijesti |
| Računovodstvo | Obračun plata, postavke obračuna, izvještaji, pregled uposlenika bez izmjena |
| Administrator | Korisnički nalozi i uloge, RFID kartice, referentni podaci, pravni dokumenti, obavijesti |

Korisnički podaci za prijavu nalaze se u README-u u korijenu repozitorija.

## Struktura

```
lib/
  config/      adresa API-ja
  models/      DTO objekti odgovora
  providers/   HTTP pozivi i stanje ekrana
  screens/     ekrani i dijalozi
  widgets/     dijeljene kontrole (avatar, paginacija, referentni tab)
  helpers/     preuzimanje PDF-a, keširanje slika, nazivi uloga
  theme/       boje
```

Kod koji dijele obje aplikacije živi u paketu [`lexor_shared`](../lexor_shared/README.md).
