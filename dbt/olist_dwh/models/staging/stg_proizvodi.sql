with izvor as (

    select * from {{ source('raw_data', 'proizvodi') }}

),

prevod as (

    select * from {{ source('raw_data', 'prevod_kategorija') }}

),

ocisceno as (

    select
        p.product_id::varchar(64)                             as id_proizvoda,
        coalesce(nullif(trim(p.product_category_name::varchar), ''), 'nepoznato')
                                                              as kategorija,
        coalesce(nullif(trim(t.product_category_name_english::varchar), ''), 'unknown')
                                                              as kategorija_eng,
        p.product_photos_qty::int                             as broj_fotografija,
        p.product_weight_g::numeric                           as tezina_g,
        p.product_length_cm::numeric                          as duzina_cm,
        p.product_height_cm::numeric                          as visina_cm,
        p.product_width_cm::numeric                           as sirina_cm

    from izvor p
    left join prevod t
        on p.product_category_name = t.product_category_name
    where p.product_id is not null

)

select * from ocisceno
