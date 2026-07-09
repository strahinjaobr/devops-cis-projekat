with porudzbine as (
    select * from {{ ref('stg_porudzbine') }}
),

kupci as (
    select * from {{ ref('stg_kupci') }}
),

stavke as (
    select
        id_porudzbine,
        count(*)                as broj_stavki,
        sum(cena)               as vrednost_proizvoda,
        sum(trosak_dostave)     as vrednost_dostave,
        sum(cena + trosak_dostave) as ukupna_vrednost
    from {{ ref('stg_stavke_porudzbine') }}
    group by id_porudzbine
),

placanja as (
    select
        id_porudzbine,
        sum(iznos)          as ukupno_placeno,
        max(broj_rata)      as maksimalan_broj_rata,
        count(*)            as broj_placanja
    from {{ ref('stg_placanja') }}
    group by id_porudzbine
),

recenzije as (
    select * from {{ ref('stg_recenzije') }}
)

select
    p.id_porudzbine,
    p.id_kupca,
    k.jedinstveni_id_kupca,
    k.grad,
    k.drzava,
    p.status_porudzbine,
    p.datum_kupovine,
    date_trunc('month', p.datum_kupovine)::date as mesec_kupovine,
    p.datum_isporuke,
    p.procenjeni_datum_isporuke,

    (p.datum_isporuke::date - p.datum_kupovine::date)
        as dana_do_isporuke,
    case
        when p.datum_isporuke is not null
         and p.datum_isporuke <= p.procenjeni_datum_isporuke
        then true
        when p.datum_isporuke is not null
        then false
    end as isporuceno_na_vreme,

    coalesce(s.broj_stavki, 0)          as broj_stavki,
    coalesce(s.vrednost_proizvoda, 0)   as vrednost_proizvoda,
    coalesce(s.vrednost_dostave, 0)     as vrednost_dostave,
    coalesce(s.ukupna_vrednost, 0)      as ukupna_vrednost,

    pl.ukupno_placeno,
    pl.maksimalan_broj_rata,

    r.ocena as ocena_recenzije

from porudzbine p
inner join kupci k
    on p.id_kupca = k.id_kupca
left join stavke s
    on p.id_porudzbine = s.id_porudzbine
left join placanja pl
    on p.id_porudzbine = pl.id_porudzbine
left join recenzije r
    on p.id_porudzbine = r.id_porudzbine
