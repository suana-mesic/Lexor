# lexor_mobile

Klijentska Flutter aplikacija sistema **Lexor**, za Android. Namijenjena je uposlenicima —
back-office uloge (HR, računovodstvo, administrator) koriste desktop aplikaciju.

## Funkcionalnosti

- Pregled vlastite evidencije prisustva u kalendaru (prisutan / odsustvo / neradni dan / bez evidencije)
- Slanje i praćenje zahtjeva za odsustvo, uz otkazivanje vlastitog zahtjeva
- Platne liste sa detaljima obračuna (master-details)
- Obavijesti kompanije i lične notifikacije (auto-osvježavanje na 20 sekundi)
- Chatbot za pitanja o radnim pravima, nad pravnim dokumentima kompanije
- Profil: lični podaci i fotografija, promjena lozinke
- Aktivacija naloga i reset lozinke putem koda iz e-maila

## Pokretanje

Backend mora biti pokrenut (vidi [README u korijenu repozitorija](../../../README.md)).

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5170
```

`10.0.2.2` je standardna adresa računara-domaćina iz Android emulatora, i ujedno
podrazumijevana vrijednost — `String.fromEnvironment('API_BASE_URL')` je čita iz
`lib/config/api_config.dart`, pa aplikacija radi i bez `--dart-define`.

Build za predaju:

```bash
flutter build apk --release
```

Rezultat je `build/app/outputs/flutter-apk/app-release.apk`.

> Manifest (`android/app/src/main/AndroidManifest.xml`) izričito deklariše dozvolu
> `INTERNET` i `networkSecurityConfig`. Flutter dozvolu dodaje samo u debug i profile
> manifest, a Android od API 28 blokira nešifrovani HTTP — bez oba release build ne bi
> mogao doći do API-ja.

## Struktura

```
lib/
  config/      adresa API-ja
  models/      DTO objekti odgovora
  providers/   HTTP pozivi i stanje ekrana
  screens/     ekrani i tabovi
  widgets/     dijeljene kontrole
  helpers/     keširanje slika, poruke
  api_client.dart, auth_store.dart, session.dart
```

Kod koji dijele obje aplikacije živi u paketu [`lexor_shared`](../lexor_shared/README.md).
