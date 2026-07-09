with izvor as (

    select * from {{ source('raw_data', 'stavke_porudzbine') }}

),

ocisceno as (

    select
        order_id::varchar(64)               as id_porudzbine,
        order_item_id::int                  as redni_broj_stavke,
        product_id::varchar(64)             as id_proizvoda,
        seller_id::varchar(64)              as id_prodavca,
        shipping_limit_date::timestamp      as rok_slanja,
        price::numeric(10, 2)               as cena,
        freight_value::numeric(10, 2)       as trosak_dostave

    from izvor
    where order_id is not null
      and product_id is not null
      and price::numeric >= 0

)

select * from ocisceno
