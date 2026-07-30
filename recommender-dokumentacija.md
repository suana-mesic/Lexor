# Dokumentacija ML komponente — Predikcija odsustva uposlenika

> Napomena o nazivu: predmet zahtijeva da se ovaj dokument nazove `recommender-dokumentacija.md`.
> Umjesto sistema preporuke, implementiran je **drugi metod iz oblasti mašinskog učenja** —
> **binarna klasifikacija** (predviđanje odsustva uposlenika), što je u skladu sa zahtjevom 2.4
> ("...ili implementirajte neki drugi metod iz oblasti ML").

## 1. Problem

Za svaki **radni dan** i svakog **uposlenika** predviđamo hoće li uposlenik **biti odsutan** (bilo koji razlog:
godišnji, bolovanje, neopravdano). Rezultat modela je vjerovatnoća odsustva (0–1), iz koje se izvode i
agregatne prognoze:

- rizik odsustva za pojedinog uposlenika u zadatom periodu;
- **očekivani broj odsutnih** po danu, po odjelu i ukupno (zbir pojedinačnih vjerovatnoća).

## 2. Algoritam

Korišten je **FastTree** (gradient boosted decision trees) iz biblioteke **ML.NET** (`Microsoft.ML` +
`Microsoft.ML.FastTree`), kao binarni klasifikator. Radi se o poznatom algoritmu koji dobro barata
tabelarnim podacima sa miješanim (kategorijskim i numeričkim) atributima.

Pipeline:
1. one-hot enkodiranje kategorijskih atributa (uposlenik, dan u sedmici, mjesec, odjel);
2. spajanje svih atributa u jedan vektor (`Features`);
3. treniranje `FastTree` klasifikatora (`numberOfTrees`, `numberOfLeaves`, `minimumExampleCountPerLeaf`).

## 3. Atributi (features)

Jedan primjer za učenje = jedan uposlenik na jedan radni dan.

| Atribut | Opis |
|---|---|
| `Employee` | Identitet uposlenika (kategorija) — omogućava učenje **ličnih** obrazaca. |
| `DayOfWeek`, `Month` | Dan u sedmici i mjesec — sezonalnost (npr. ponedjeljak, ljetni godišnji, zimska bolovanja). |
| `Department` | Odjel uposlenika. |
| `HistoricalAbsenceRate` | Udio odsutnih dana kroz cijelu prethodnu historiju. |
| `RecentAbsenceRate` | Udio odsutnih dana u zadnjih 30 dana (trenutno stanje). |
| `MonthSeasonRate` | Lična stopa odsustva u **tom** kalendarskom mjesecu iz prošlih godina (sezonalnost po osobi). |
| `OnPlannedLeave` | 1 ako je taj dan pokriven **planiranim** odsustvom (godišnji/plaćeno/neplaćeno — poznato unaprijed). |
| `PrevWorkdayAbsent` | Da li je prethodni radni dan bio izostanak (bolest traje više dana). |
| `AbsencesInLast5Workdays` | Broj izostanaka u zadnjih 5 radnih dana. |

**Label (izlaz):** `IsAbsent` — radni dan bez evidentiranog otiska kartice u tabeli `Attendances`.

### Sprječavanje curenja podataka (data leakage)
Sve "stope" i klizni prozori računaju se **isključivo iz dana prije** posmatranog dana — nikad iz samog
dana koji se predviđa. **Bolovanja se namjerno NE koriste kao atribut** (`OnPlannedLeave` ih isključuje),
jer buduće bolovanje nije poznato unaprijed; model ih uči iz sezone i ličnog obrasca. Planirana odsustva
(godišnji) jesu poznata unaprijed (admin ih odobrava), pa su legitiman atribut.

## 4. Podaci

Model se trenira nad **stvarnim zapisima** iz baze (tabele `Attendances` i `Leaves`), a ne nad izmišljenim
signalima. Historija obuhvata 30 uposlenika kroz ~3 godine (≈ 23.340 primjera uposlenik-dan). Podaci imaju
realističnu strukturu: lični mjesec godišnjeg i lični "peak" mjesec bolovanja po uposleniku, višednevni
blokovi bolovanja i umjeren udio nepredvidivih izostanaka.

## 5. Treniranje i evaluacija

- Podaci se dijele na **80% trening / 20% test** (`TrainTestSplit`, fiksni `seed` radi ponovljivosti).
- Metrike se računaju na **test skupu** (podaci koje model nije vidio tokom učenja).
- **Podešavanje praga (threshold tuning):** model vraća vjerovatnoću; skeniramo pragove 0.05–0.95 i biramo
  onaj s najvećim **F1** (harmonijska sredina preciznosti i odziva).

### Izmjerene metrike

| Metrika | Vrijednost |
|---|---|
| AUC | 0.931 |
| F1 | 0.783 (prag 0.48) |
| Preciznost | 0.868 |
| Odziv (recall) | 0.709 |
| Tačnost (accuracy) | 0.943 |
| Broj primjera | 23.340 (≈ 18.7k trening / 4.7k test) |

Simulacijom nad generatorom podataka procijenjen je **teorijski maksimum F1 ≈ 0.82** (dio izostanaka je
suštinski nepredvidiv — nasumično razbolijevanje). Postignuti F1 od 0.78 pokriva najveći dio dostižnog
znanja iznad slučajnog pogađanja.

> Napomena o tačnosti: visoka tačnost (0.94) sama po sebi nije dovoljna, jer je klasa "odsutan" rijetka
> (~14% dana). Zato se kao glavne metrike koriste **AUC i F1**, koji mjere stvarnu sposobnost razlikovanja.

## 6. Objašnjivost i primjena

Predikcije su objašnjive kroz atribute koji ih pokreću: lični sezonski obrazac uposlenika (`MonthSeasonRate`),
trenutno stanje (`RecentAbsenceRate`, `AbsencesInLast5Workdays`) i planirana odsustva (`OnPlannedLeave`).
Npr. visok rizik u augustu za određenog uposlenika proizlazi iz njegove historijske stope odsustva baš u
augustu, a ne iz slučajnosti.

Rezultati se prikazuju u **desktop administrativnoj aplikaciji** (ekran "Predikcija odsustva"):
- graf očekivanog broja odsutnih po danu za zadati period;
- očekivana odsustva po odjelu (osobo-dani);
- rang-lista najrizičnijih uposlenika;
- metrike modela.

## 7. Upravljanje modelom

Model se trenira **na startu API-ja**, iz aktuelnih podataka u bazi, i drži u memoriji kao singleton servis
(`IAbsencePredictionService`). Time je uvijek usklađen sa trenutnim stanjem evidencije, bez potrebe za
ručnim re-treniranjem.
