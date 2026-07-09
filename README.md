# DataOps projekat – ELT obrada podataka elektronske trgovine

Projektni zadatak iz predmeta Cloud infrastruktura i servisi. Cilj je izgradnja lokalne kontejnerizovane infrastrukture
koja realizuje ELT (Extract, Load, Transform) pristup: sirovi podaci se alatom Airbyte
učitavaju u PostgreSQL skladište bez izmena, a zatim se transformišu alatom dbt u
analitičke tabele pogodne za izveštavanje.

## Uputstvo za pokretanje

```
git clone https://github.com/strahinjaobr/devops-cis-projekat.git
cd devops-cis-projekat
copy .env.primer .env
docker compose up -d
```

Zatim preuzeti [Olist CSV fajlove](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
u folder `data/` i izvršiti Airbyte sinhronizaciju (podešavanje opisano u odeljku 6),
pa pokrenuti transformacije:

```
pip install dbt-postgres
cd dbt/olist_dwh
dbt run --profiles-dir .
dbt test --profiles-dir .
```

Očekivani ishod: 11 izgrađenih modela, 36 testova, PASS=36, ERROR=0.
Detaljna verzija uputstva nalazi se u odeljku 5.

## 1. Arhitektura

Sistem čine tri komponente:

1. PostgreSQL 16 (Docker kontejner) – skladište podataka (DWH)
2. Airbyte (lokalna instanca, abctl) – EL faza, prenos CSV podataka u bazu
3. dbt – T faza, SQL transformacije unutar skladišta

Podaci unutar skladišta prolaze kroz tri šeme:

| Šema | Sadržaj | Puni je |
|---|---|---|
| `raw_data` | sirovi podaci, identični CSV izvorima | Airbyte |
| `staging` | očišćeni i tipizirani podaci (view) | dbt |
| `analitika` | finalne analitičke tabele (table) | dbt |

Tok podataka: CSV → Airbyte → `raw_data` → dbt → `staging` → dbt → `analitika`.

## 2. Izvor podataka

Korišćen je javno dostupan skup podataka
[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
sa platforme Kaggle (oko 100.000 porudžbina brazilske e-commerce platforme).
Iz skupa je iskorišćeno sedam logički povezanih entiteta:

| CSV fajl | Airbyte strim (tabela u raw_data) |
|---|---|
| olist_customers_dataset.csv | `kupci` |
| olist_orders_dataset.csv | `porudzbine` |
| olist_order_items_dataset.csv | `stavke_porudzbine` |
| olist_products_dataset.csv | `proizvodi` |
| olist_order_payments_dataset.csv | `placanja` |
| olist_order_reviews_dataset.csv | `ocene` |
| product_category_name_translation.csv | `prevod_kategorija` |

CSV fajlovi se ne versionišu u repozitorijumu. Nakon preuzimanja sa Kaggle-a
smeštaju se u folder `data/`.

## 3. Struktura repozitorijuma

```
.
├── docker-compose.yml       orkestracija: PostgreSQL (DWH) + SFTP server za CSV fajlove
├── .env.primer             šablon konfiguracije okruženja
├── init/01_seme.sql         kreiranje šema pri prvom pokretanju baze
├── data/                    ovde se smeštaju preuzeti CSV fajlovi (van git-a)
└── dbt/olist_dwh/           dbt projekat
    ├── dbt_project.yml
    ├── profiles.yml         konekcija ka bazi (čita promenljive okruženja)
    ├── macros/
    └── models/
        ├── staging/         stg_* modeli + izvori.yml + testovi (schema.yml)
        └── marts/           fct_* i mart_* modeli + testovi (schema.yml)
```

## 4. Preduslovi

- Docker Desktop (testirano na Windows 11)
- Python 3.10 ili noviji
- Airbyte instanca instalirana alatom [abctl](https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart)
  (konfiguracija EL procesa opisana je u odeljku 6)

Napomena: Airbyte se od 2024. godine više ne instalira kroz docker-compose, već
zvaničnim alatom abctl, koji ga takođe pokreće u Docker-u. Zato docker-compose.yml
u ovom projektu podiže bazu i SFTP servis, a Airbyte se instalira posebnom abctl
komandom.

## 5. Pokretanje sistema i izvršavanje transformacija

Komande se izvršavaju redom, iz korena repozitorijuma (PowerShell).

Podizanje infrastrukture:

```
git clone https://github.com/strahinjaobr/devops-cis-projekat.git
cd devops-cis-projekat
copy .env.primer .env
docker compose up -d
docker compose ps
```

Očekivano stanje: `skladiste_postgres` (healthy, port 5433) i `fajl_server_sftp`
(port 2222). Port 5433 je izabran jer je na mom računaru 5432 bio zauzet.

Izvršavanje transformacija:

```
pip install dbt-postgres
cd dbt/olist_dwh
dbt debug --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .
```

`dbt run` gradi svih 11 modela (staging i mart sloj), a `dbt test` izvršava 36
testova integriteta. Očekivani ishod: PASS=36, ERROR=0.

Provera rezultata:

```
docker exec skladiste_postgres psql -U student -d skladiste -c "SELECT * FROM analitika.mart_kljucne_metrike ORDER BY rb;"
docker exec skladiste_postgres psql -U student -d skladiste -c "SELECT * FROM analitika.mart_mesecna_prodaja_po_kategoriji LIMIT 10;"
```

Preduslov za transformacije je da je šema `raw_data` napunjena podacima, što se radi
jednokratno kroz Airbyte sinhronizaciju (odeljak 6). Provera da su podaci učitani:

```
docker exec skladiste_postgres psql -U student -d skladiste -c "\dt raw_data.*"
```

## 6. EL faza: konfiguracija Airbyte procesa

Airbyte je instaliran zvaničnim alatom abctl (`abctl local install --low-resource-mode`;
pristupni kredencijali se dobijaju komandom `abctl local credentials`, interfejs je na
http://localhost:8000). Kroz grafički interfejs konfigurisano je sledeće.

Za svaki od sedam CSV fajlova kreiran je Source tipa File: format `csv`, Storage
Provider `SFTP`, host `host.docker.internal`, port `2222`, kredencijali iz `.env`
fajla, putanja `data/<naziv_fajla>.csv`, a Dataset Name određuje ime tabele u bazi
(prema tabeli u odeljku 2).

SFTP je upotrebljen umesto direktnog čitanja sa diska jer provajder Local Filesystem
ne funkcioniše u abctl instalaciji – konektorski pod u Kubernetes klasteru nema
pristup fajl sistemu host mašine (otvoren problem
[airbyte#45645](https://github.com/airbytehq/airbyte/issues/45645)), dok provajder
HTTPS prihvata isključivo šifrovane konekcije. SFTP servis iz docker-compose fajla
servira lokalni folder `data/` kroz protokol koji konektor podržava.

Odredište je jedan Destination tipa Postgres: host `host.docker.internal` (Airbyte
radi u sopstvenom klasteru, pa `localhost` ne pokazuje na host mašinu), port `5433`,
baza `skladiste`, Default Schema `raw_data`, kredencijali iz `.env` fajla.

Svaki Source je povezan sa odredištem (Connection) uz sync mode
Full refresh | Overwrite, nakon čega je izvršena sinhronizacija kojom je sedam
tabela učitano u šemu `raw_data` u izvornom obliku.

## 7. Opis transformacija

### Staging sloj (šema `staging`)

Svaki model čita odgovarajuću tabelu iz `raw_data` i sprovodi tri vrste operacija:
kastovanje tipova (tekstualni datumi u `timestamp`, novčani iznosi u `numeric(10,2)`,
ocene u `int`), standardizaciju naziva kolona (npr. `order_purchase_timestamp` →
`datum_kupovine`) i čišćenje nevalidnih zapisa. Čišćenje obuhvata: uklanjanje redova
bez primarnog ključa, uklanjanje stavki sa negativnom cenom, izbacivanje plaćanja
tipa `not_defined`, ograničavanje ocena na opseg 1–5 i deduplikaciju recenzija
(prozorskom funkcijom `ROW_NUMBER` zadržava se najnovija recenzija po porudžbini).
Proizvodi bez kategorije dobijaju vrednost `nepoznato`, a poštanski brojevi se
dopunjuju vodećim nulama na pet cifara.

### Mart sloj (šema `analitika`)

| Model | Sadržaj |
|---|---|
| `fct_porudzbine` | činjenična tabela: porudžbine spojene sa kupcima, agregiranim stavkama, plaćanjima i recenzijama |
| `mart_mesecna_prodaja_po_kategoriji` | mesečna prodaja po kategoriji proizvoda |
| `mart_prodaja_po_drzavi` | prodaja po saveznoj državi kupca |
| `mart_nacini_placanja` | struktura načina plaćanja |
| `mart_kljucne_metrike` | KPI tabela sa 16 metrika poslovanja |

KPI tabela obuhvata, između ostalog: ukupan prihod, broj porudžbina, procenat
otkazanih porudžbina, prosečnu vrednost porudžbine, broj jedinstvenih kupaca, stopu
ponovljenih kupovina, prihod od dostave, prosečno vreme isporuke, procenat isporuka
na vreme, prosečnu ocenu i prosečan broj rata.

### Testovi integriteta

Testovi su definisani deklarativno u YAML fajlovima (`models/staging/schema.yml`,
`models/marts/schema.yml`): `unique` i `not_null` nad primarnim ključevima,
`relationships` za referencijalni integritet (stavke → porudžbine → kupci,
stavke → proizvodi) i `accepted_values` za domene vrednosti (statusi porudžbina,
ocene 1–5). Ukupno 36 testova.

## 8. Bezbednosne napomene

Kredencijali (korisničko ime, lozinka, naziv baze) prosleđuju se kontejnerima
isključivo kroz `.env` fajl koji je naveden u `.gitignore`; u repozitorijumu stoji
samo šablon `.env.primer`. CSV fajlovi i fajlovi baze podataka takođe su isključeni
iz verzionisanja.
