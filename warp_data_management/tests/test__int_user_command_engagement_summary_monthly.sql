{{
    config(
        tags=['custom_data_test']
    )
}}

with category_sums as (
    select
        sum(is_new_user) + sum(is_retained_user) + sum(is_churned_user) + sum(is_resurrected_user) + sum(is_inactive_user) as all_categories_sum
        ,count(1) as total_records
    from {{ ref('int_user_command_engagement_summary_monthly') }}
)

select *
from category_sums
where all_categories_sum != total_records