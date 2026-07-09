with izvor as (

    select * from {{ source('raw_data', 'ocene') }}

),

ocisceno as (

    select
        review_id::varchar(64)              as id_recenzije,
        order_id::varchar(64)               as id_porudzbine,
        review_score::int                   as ocena,
        review_creation_date::timestamp     as datum_kreiranja,
        review_answer_timestamp::timestamp  as datum_odgovora,
        row_number() over (
            partition by order_id
            order by review_answer_timestamp desc
        ) as rb

    from izvor
    where review_id is not null
      and order_id is not null
      and review_score::int between 1 and 5

)

select
    id_recenzije,
    id_porudzbine,
    ocena,
    datum_kreiranja,
    datum_odgovora
from ocisceno
where rb = 1
