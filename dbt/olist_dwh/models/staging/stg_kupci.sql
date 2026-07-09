with izvor as (

    select * from {{ source('raw_data', 'kupci') }}

),

ocisceno as (

    select
        customer_id::varchar(64)              as id_kupca,
        customer_unique_id::varchar(64)       as jedinstveni_id_kupca,
        lpad(customer_zip_code_prefix::varchar, 5, '0')
                                              as postanski_broj,
        initcap(trim(customer_city::varchar)) as grad,
        upper(trim(customer_state::varchar))  as drzava

    from izvor
    where customer_id is not null

)

select * from ocisceno
