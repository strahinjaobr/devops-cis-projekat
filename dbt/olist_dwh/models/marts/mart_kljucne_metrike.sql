with porudzbine as (
    select * from {{ ref('fct_porudzbine') }}
),

stavke as (
    select * from {{ ref('stg_stavke_porudzbine') }}
),

placanja as (
    select * from {{ ref('stg_placanja') }}
),

proizvodi as (
    select * from {{ ref('stg_proizvodi') }}
),

metrike as (

    select 1 as rb, 'ukupan_prihod' as metrika,
        round(sum(ukupna_vrednost), 2) as vrednost,
        'Ukupna vrednost svih neotkazanih porudzbina (proizvodi + dostava)' as opis
    from porudzbine where status_porudzbine not in ('canceled', 'unavailable')

    union all
    select 2, 'ukupan_broj_porudzbina',
        count(*),
        'Ukupan broj svih porudzbina'
    from porudzbine

    union all
    select 3, 'broj_isporucenih_porudzbina',
        count(*),
        'Broj porudzbina sa statusom delivered'
    from porudzbine where status_porudzbine = 'delivered'

    union all
    select 4, 'procenat_otkazanih_porudzbina',
        round(100.0 * count(*) filter (where status_porudzbine = 'canceled')
            / count(*), 2),
        'Udeo otkazanih porudzbina u ukupnom broju (%)'
    from porudzbine

    union all
    select 5, 'prosecna_vrednost_porudzbine',
        round(avg(ukupna_vrednost), 2),
        'Prosecna vrednost porudzbine - AOV (Average Order Value)'
    from porudzbine where status_porudzbine not in ('canceled', 'unavailable')

    union all
    select 6, 'ukupan_broj_kupaca',
        count(distinct jedinstveni_id_kupca),
        'Broj jedinstvenih kupaca'
    from porudzbine

    union all
    select 7, 'procenat_kupaca_koji_su_ponovo_kupili',
        round(100.0 * count(*) filter (where broj_porudzbina > 1)
            / count(*), 2),
        'Udeo kupaca sa vise od jedne porudzbine (%) - lojalnost'
    from (
        select jedinstveni_id_kupca, count(*) as broj_porudzbina
        from porudzbine
        group by jedinstveni_id_kupca
    ) k

    union all
    select 8, 'prosecan_broj_stavki_po_porudzbini',
        round(avg(broj_stavki), 2),
        'Prosecan broj proizvoda u jednoj porudzbini'
    from porudzbine where broj_stavki > 0

    union all
    select 9, 'ukupan_prihod_od_dostave',
        round(sum(vrednost_dostave), 2),
        'Ukupna naplacena vrednost dostave'
    from porudzbine where status_porudzbine not in ('canceled', 'unavailable')

    union all
    select 10, 'prosecno_dana_do_isporuke',
        round(avg(dana_do_isporuke), 1),
        'Prosecan broj dana od kupovine do isporuke'
    from porudzbine where dana_do_isporuke is not null

    union all
    select 11, 'procenat_isporuka_na_vreme',
        round(100.0 * count(*) filter (where isporuceno_na_vreme)
            / count(*), 2),
        'Udeo porudzbina isporucenih pre procenjenog datuma (%)'
    from porudzbine where isporuceno_na_vreme is not null

    union all
    select 12, 'prosecna_ocena_recenzije',
        round(avg(ocena_recenzije), 2),
        'Prosecna ocena kupaca (skala 1-5)'
    from porudzbine where ocena_recenzije is not null

    union all
    select 13, 'broj_razlicitih_proizvoda',
        count(distinct id_proizvoda),
        'Broj razlicitih prodatih proizvoda'
    from stavke

    union all
    select 14, 'broj_kategorija_proizvoda',
        count(distinct kategorija),
        'Broj razlicitih kategorija u katalogu'
    from proizvodi

    union all
    select 15, 'prosecan_broj_rata',
        round(avg(broj_rata), 2),
        'Prosecan broj rata pri placanju'
    from placanja

    union all
    select 16, 'procenat_placanja_kreditnom_karticom',
        round(100.0 * count(*) filter (where nacin_placanja = 'credit_card')
            / count(*), 2),
        'Udeo transakcija kreditnom karticom (%)'
    from placanja

)

select rb, metrika, vrednost, opis
from metrike
order by rb
