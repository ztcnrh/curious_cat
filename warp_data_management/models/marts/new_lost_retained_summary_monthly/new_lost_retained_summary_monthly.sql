{{
    config(
        materialized='table',
    )
}}

select
    spine_month as month
    ,sum(is_new_user) as new
    ,sum(is_retained_user) as retained
    ,sum(is_resurrected_user) as resurrected
    ,sum(is_churned_user) as churned
    ,count(user_id) as total_user_cnt
from {{ ref('int_user_command_engagement_summary_monthly') }}
group by month