with izvor as (

    select * from {{ source('raw_data', 'porudzbine') }}

),

ocisceno as (

    select
        order_id::varchar(64)                       as id_porudzbine,
        customer_id::varchar(64)                    as id_kupca,
        lower(trim(order_status::varchar))          as status_porudzbine,
        order_purchase_timestamp::timestamp         as datum_kupovine,
        order_approved_at::timestamp                as datum_odobrenja,
        order_delivered_carrier_date::timestamp     as datum_predaje_kuriru,
        order_delivered_customer_date::timestamp    as datum_isporuke,
        order_estimated_delivery_date::timestamp    as procenjeni_datum_isporuke

    from izvor
    where order_id is not null
      and customer_id is not null

)

select * from ocisceno
