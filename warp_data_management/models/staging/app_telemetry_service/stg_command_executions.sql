{{
    config(
        materialized='table',
    )
}}

-- Stage model, created pretending there's a raw source table (which in our case is the seed)
with final as (
    select
        user_id
        ,event_timestamp as event_ts
    from {{ ref('command_executions') }}
)

select * from final