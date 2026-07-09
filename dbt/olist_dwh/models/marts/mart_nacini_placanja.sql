with placanja as (
    select * from {{ ref('stg_placanja') }}
)

select
    nacin_placanja,

    count(*)                                    as broj_transakcija,
    count(distinct id_porudzbine)               as broj_porudzbina,
    sum(iznos)                                  as ukupan_iznos,
    round(avg(iznos), 2)                        as prosecan_iznos,
    round(avg(broj_rata), 2)                    as prosecan_broj_rata,
    max(broj_rata)                              as maksimalan_broj_rata,
    round(
        100.0 * sum(iznos) / sum(sum(iznos)) over (), 2
    )                                           as procenat_ukupnog_iznosa

from placanja
group by nacin_placanja
order by ukupan_iznos desc
