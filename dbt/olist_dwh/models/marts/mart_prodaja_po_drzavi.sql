with porudzbine as (
    select * from {{ ref('fct_porudzbine') }}
)

select
    drzava,

    count(distinct jedinstveni_id_kupca)    as broj_kupaca,
    count(*)                                as broj_porudzbina,
    sum(ukupna_vrednost)                    as ukupan_prihod,
    round(avg(ukupna_vrednost), 2)          as prosecna_vrednost_porudzbine,
    round(avg(dana_do_isporuke), 1)         as prosecno_dana_do_isporuke,
    round(avg(ocena_recenzije), 2)          as prosecna_ocena

from porudzbine
where status_porudzbine = 'delivered'
group by drzava
order by ukupan_prihod desc
