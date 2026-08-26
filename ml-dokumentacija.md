# Dokumentacija ML komponente — Detekcija prevara u evidenciji radnog vremena

> Napomena o nazivu: umjesto sistema preporuke implementiran je **drugi metod iz oblasti
> mašinskog učenja** — **binarna klasifikacija** (detekcija prevara u evidenciji dolazaka i
> odlazaka), što je u skladu sa zahtjevom 2.4 ("...ili implementirajte neki drugi metod iz
> oblasti ML"). Budući da sistem preporuke nije implementiran, dokument je nazvan prema svom
> stvarnom sadržaju — `ml-dokumentacija.md` umjesto `recommender-dokumentacija.md` kako je
> navedeno u tački 9.2 uputa. Ovo je jedini dokument sa opisom ML komponente koji tačka 9.2
> traži.

## 1. Problem

Uposlenici evidentiraju dolazak i odlazak s posla RFID karticom. U evidenciji se mogu pojaviti
**prevare**: manipulisana vremena dolaska/odlaska i naknadna prepravljanja vremena odlaska.
Za svaki zapis evidencije model predviđa: **je li zapis prevara ili regularan** (binarna
klasifikacija, klasa "prevara" je pozitivna).

Ovo je isti tip problema kao udžbenički primjer **detekcije prevara s kreditnim karticama**:
nadzirana klasifikacija nad jako **neuravnoteženim** podacima (prevare su rijetke, ~3%).

### Zašto ML, a ne obično pravilo (if)?

Jednostavan prag (npr. "dolazak poslije 08:30 → prevara") bio bi **pogrešan**, jer legitimna
ponašanja izgledaju isto kao pojedinačni znak prevare:

| Znak | Legitimno objašnjenje |
|---|---|
| kasni dolazak | odobreno fleksibilno radno vrijeme |
| raniji odlazak | odobren kraći radni dan |
| kasniji odlazak | stvarni prekovremeni rad |
| jedna izmjena vremena odlaska | ispravka tehničke greške pri skeniranju |

Prevara nije nijedan pojedinačni znak, nego **kombinacija** znakova (npr. kasni dolazak +
raniji odlazak + višestruke izmjene odlaska), i to **relativno prema ličnom obrascu** svakog
uposlenika (09:00 je normalan dolazak za nekoga ko uvijek dolazi u 09:00, a anomalija za nekoga
ko godinama dolazi u 07:30). Takvu višedimenzionalnu, po osobi prilagođenu granicu ne može
opisati fiksni prag — model je **uči iz podataka**.

### Zašto "prevara", a ne "anomalija"?

Detekcija anomalija je **nenadzirana** tehnika (bez označenih podataka). Ovdje postoje
**označeni podaci** (`IsFraud`) i mjere se preciznost/odziv/F1 — što je po definiciji
**nadzirana klasifikacija**, čiji je standardni naziv u literaturi *fraud detection*. Model
označava **potencijalne** prevare; konačnu odluku donosi HR pregledom zapisa.

## 2. Algoritam

Korištena je **logistička regresija** (`LbfgsLogisticRegression`) iz biblioteke **ML.NET**
(`Microsoft.ML`) — standardni, dobro objašnjiv binarni klasifikator: nauči težinu svakog
atributa i vraća vjerovatnoću (0–1) da je zapis prevara.

Pipeline (`FraudDetectionService`):
1. spajanje 6 atributa u jedan vektor (`Concatenate` → `Features`);
2. **normalizacija** svih atributa na raspon [0,1] (`NormalizeMinMax`) — da atribut izražen u
   minutama ne nadjača atribut izražen kao mali broj; parametri normalizacije se uče **samo na
   trening skupu**;
3. treniranje logističke regresije s **težinama po redu** (vidi 5.1).

## 3. Atributi (features)

Jedan primjer = jedan zapis evidencije (jedan uposlenik, jedan dan). Gradi ih
`FraudSampleBuilder` iz tabele `Attendances`.

| Atribut | Opis |
|---|---|
| `ArrivalMinutes` | Vrijeme dolaska u minutama od ponoći (08:30 → 510). |
| `DepartureMinutes` | Vrijeme odlaska u minutama od ponoći. |
| `WorkedHours` | Stvarno odrađeni sati tog dana. |
| `DepartureEditCount` | Koliko je puta vrijeme odlaska naknadno prepravljano (indikator manipulacije). |
| `ArrivalDeviation` | Dolazak minus **lični prosječni** dolazak tog uposlenika (anomalija po osobi). |
| `DepartureDeviation` | Odlazak minus lični prosječni odlazak tog uposlenika. |

**Label (izlaz):** `IsFraud` — oznaka je li zapis prevara (kolona u tabeli `Attendances`).

Odstupanja od ličnog prosjeka su ključni atributi: čine detekciju **relativnom po uposleniku**,
što nijedan globalni prag ne može postići.

## 4. Podaci

Model se trenira nad zapisima iz baze (tabela `Attendances`): **oko 10.500 zapisa** evidencije za
30 uposlenika kroz ~19 mjeseci, od čega je **300 zapisa (~3%) označeno kao prevara**. Prevare su
raznovrsne (kasni dolasci, raniji odlasci, višestruke izmjene odlaska i njihove kombinacije), a
podaci sadrže i **legitimne dvojnike** (fleksibilni dolasci, odobreni kraći dani, stvarni
prekovremeni, pojedinačne ispravke), zbog kojih se klase djelimično preklapaju — kao u stvarnosti.

Evidencija je potpuna: svaki radni dan svakog uposlenika ima ili zapis prisustva ili odobreno
odsustvo, a zapisa nema vikendom. Skup zato ne sadrži "rupe" koje bi model mogao pogrešno
protumačiti, niti dane koji uopšte nisu radni.

## 5. Treniranje i evaluacija

### Hronološka podjela 80 : 20

Zapisi se sortiraju **po datumu**: najstarijih 80% je trening skup, najnovijih 20% je test skup.
Podjela je namjerno hronološka, a ne nasumična: zapis iz posljednjeg mjeseca ne smije učestvovati
u treniranju modela koji predviđa za neki raniji mjesec, jer bi tako **budućnost "curila" u prošlost**
(model bi na testu izgledao bolje nego što bi ikad bio u stvarnoj upotrebi, gdje budući podaci ne
postoje). Test skup tako simulira stvarnu situaciju: model treniran na prošlosti, primijenjen na
neviđenu budućnost.

### 5.1 Neuravnoteženost klasa (class weighting)

Prevara je samo ~3% zapisa. Bez korekcije, model bi mogao "sve proglasiti normalnim" i imati
97% tačnosti, a nijednu uhvaćenu prevaru — većinska klasa nadglasa manjinsku. Zato svaki
prevarantski red pri treniranju nosi **4× veću težinu** (`fraudWeight = 4`), čime manjinska
klasa dobija ravnopravan uticaj na granicu odluke.

### 5.2 Izmjerene metrike (trening i test)

| Metrika | Trening (80%) | Test (20%) |
|---|---|---|
| **F1** | **0.921** | **0.851** |
| Tačnost (accuracy) | 0.996 | 0.993 |
| Preciznost (precision) | 0.981 | 0.977 |
| Odziv (recall) | 0.868 | 0.754 |
| AUC | 0.993 | 0.991 |
| Broj zapisa | 8.386 | 2.097 |
| Broj prevara | 243 | 57 |

> Demo podaci se generišu u odnosu na datum pokretanja (prozor od ~19 mjeseci koji završava
> jučerašnjim danom), pa konkretne vrijednosti mogu odstupati za nekoliko stotinki između
> pokretanja. Tabela prikazuje jedno mjerenje; aktuelne vrijednosti su uvijek vidljive na
> ekranu "Detekcija prevara" u desktop aplikaciji.

Značenje metrika (pozitivna klasa = prevara):
- **Preciznost** — od zapisa koje je model označio, koliko ih stvarno jeste prevara (mjeri
  lažne uzbune; visoka preciznost znači da se uposlenici gotovo nikad lažno ne optužuju);
- **Odziv** — od stvarnih prevara, koliko ih je model uhvatio (mjeri propuštene prevare);
- **F1** — harmonijska sredina preciznosti i odziva, glavna mjera na neuravnoteženim podacima;
- **AUC** — vjerovatnoća da nasumična prevara dobije veći score od nasumičnog regularnog zapisa
  (0.5 = nasumično pogađanje, 1 = savršeno razdvajanje);
- **Tačnost** — udio svih ispravno klasifikovanih zapisa; na neuravnoteženim podacima je
  varljiva (i beskoristan model bi imao ~97%), pa se navodi samo kao dopunska mjera.

Razlika trening → test (F1 0.921 → 0.851) je **očekivani i zdrav** pad generalizacije: test skup
su hronološki najnoviji zapisi, u kojima su prevare suptilnije, pa odziv pada (0.87 → 0.75), dok
preciznost ostaje visoka (0.98) — model i na neviđenim podacima gotovo ne diže lažne uzbune.

## 6. Prikaz rezultata

Rezultati se prikazuju u **desktop aplikaciji** (ekran "Detekcija prevara", dostupan HR
menadžeru i administratoru):

- KPI kartice: broj označenih zapisa, stvarne prevare među označenim, lažne uzbune, F1 (test);
- tabela svih metrika za trening i test skup (s objašnjenjem svake metrike na hover);
- grafikon broja detektovanih prevara **po mjesecima** (uz slicer za godinu);
- grafikon detektovanih prevara **po danima u sedmici** (uz nezavisne slicere za godinu i mjesec).

## 7. Upravljanje modelom

Model se trenira **na startu API-ja** iz aktuelnog stanja baze i drži u memoriji kao singleton
servis (`IFraudDetectionService`); endpoint `GET /FraudDetection` (uloge HRManager i
Administrator) vraća metrike i listu označenih zapisa. Time je model uvijek usklađen s trenutnom
evidencijom, bez ručnog re-treniranja, a fiksni `seed` ML konteksta čini rezultate ponovljivim.
