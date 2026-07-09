with izvor as (

    select * from {{ source('raw_data', 'placanja') }}

),

ocisceno as (

    select
        order_id::varchar(64)               as id_porudzbine,
        payment_sequential::int             as redni_broj_placanja,
        lower(trim(payment_type::varchar))  as nacin_placanja,
        payment_installments::int           as broj_rata,
        payment_value::numeric(10, 2)       as iznos

    from izvor
    where order_id is not null
      and lower(trim(payment_type::varchar)) != 'not_defined'

)

select * from ocisceno
