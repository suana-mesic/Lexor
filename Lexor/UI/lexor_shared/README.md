# lexor_shared

Lokalni Dart paket sa kodom koji dijele **lexor_desktop** i **lexor_mobile**. Nije namijenjen
objavljivanju na pub.dev — obje aplikacije ga povezuju putanjom (`path: ../lexor_shared`), pa
se jedna definicija koristi na oba mjesta umjesto da se duplira.

## Sadržaj

| Fajl | Uloga |
|---|---|
| `api_error.dart` | Parsiranje standardizovane poruke o grešci koju API vraća, sa razumljivim tekstom za korisnika. |
| `api_exception.dart` | Izuzetak koji nose HTTP pozivi kada odgovor nije uspješan. |
| `auth_service.dart` | Čitanje korisničkih uloga iz JWT tokena. |
| `contract_status.dart` | Status ugovora izveden iz datuma (ugovor nema kolonu u bazi). |
| `leave_state_type.dart` | Stanja zahtjeva za odsustvo (`Pending → Approved/Rejected → Completed/Cancelled`). |
| `salary_slip_status.dart` | Stanja platne liste (`Pending → Approved → Paid`). |
| `salary_slip_item_type.dart` | Tipovi stavki na platnoj listi (doprinosi, porez, prekovremeni). |
| `bosnian_months.dart` | Nazivi mjeseci na bosanskom, za prikaz perioda. |

## Upotreba

Sve je izloženo kroz jedan import:

```dart
import 'package:lexor_shared/lexor_shared.dart';
```

Kada se doda novi fajl u `lib/src/`, treba ga izvesti u `lib/lexor_shared.dart`.

Opis cijelog sistema nalazi se u [README-u u korijenu repozitorija](../../../README.md).
