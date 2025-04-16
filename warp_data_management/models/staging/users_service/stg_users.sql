{{
    config(
        materialized='table',
    )
}}

-- Stage model, created pretending there's a raw source table (which in our case is the seed)
with final as (
    select
        user_id
        ,account_created_timestamp as account_created_ts
        ,role
    from {{ ref('users') }}
)

select * from final