with stavke as (
    select * from {{ ref('stg_stavke_porudzbine') }}
),

porudzbine as (
    select * from {{ ref('stg_porudzbine') }}
),

proizvodi as (
    select * from {{ ref('stg_proizvodi') }}
)

select
    date_trunc('month', p.datum_kupovine)::date as mesec,
    pr.kategorija,
    pr.kategorija_eng,

    count(distinct s.id_porudzbine)     as broj_porudzbina,
    count(*)                            as broj_prodatih_proizvoda,
    sum(s.cena)                         as ukupan_prihod,
    sum(s.trosak_dostave)               as ukupan_trosak_dostave,
    round(avg(s.cena), 2)               as prosecna_cena_proizvoda

from stavke s
inner join porudzbine p
    on s.id_porudzbine = p.id_porudzbine
inner join proizvodi pr
    on s.id_proizvoda = pr.id_proizvoda
where p.status_porudzbine not in ('canceled', 'unavailable')
group by 1, 2, 3
order by 1, 6 desc
