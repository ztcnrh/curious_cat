{{
    config(
        materialized='table',
    )
}}

-- Produces unique months as rows where a user has the possibility to execute a command
-- (we should not have a command event tied to a specific user_id before the account existed)
with spine_user_engagement as (
    select
        u.user_id
        ,date_trunc('month', u.account_created_ts::date) as user_created_month
        ,dim_month.month as spine_month
        ,u.role
    from {{ ref('stg_users') }} as u
    inner join {{ ref('dim_month') }} on dim_month.month >= user_created_month --No need to track months before an account is created
    where dim_month.month between '2022-01-01' and '2022-12-01'
)

-- Get distinct Warp interactions by user, at least 1 command run per month means the user engaged in that month
, unique_events_by_month_and_user as (
    select distinct
        user_id
        ,date_trunc('month', event_ts::date) as command_event_month
    from {{ ref('stg_command_executions') }}
)

, user_engagement_history_by_month as (
    select
        s.user_id
        ,s.role as user_role
        ,s.user_created_month
        ,s.spine_month --tracks all months after account creation
        ,ue.command_event_month --track all months where user executed at least 1 command
    from spine_user_engagement as s
    -- If a command is not executed by a user in a certain month, command_event_month will be null and we know for that specific spine_month user likely churned
    left join unique_events_by_month_and_user as ue on
        s.user_id = ue.user_id
        and s.spine_month = ue.command_event_month
)

, categories as (
    select
        user_id
        ,user_role
        ,user_created_month
        ,spine_month
        ,command_event_month
        ,iff(command_event_month is not null, true, false) as is_active
        ,iff(lag(command_event_month) over(partition by user_id order by spine_month) is not null, true, false) as is_active_prev_month
        
        -- New: A user who is using Warp within the same month of their account creation
        ,iff(is_active = true and user_created_month = spine_month, 1, 0) as is_new_user
        
        -- Retained: A user who is using Warp and also used Warp the previous month
        ,iff(is_active = true and is_active_prev_month = true, 1, 0) as is_retained_user

        -- Churned: A user who used Warp the previous month but did not use Warp in the current month
        ,iff(is_active = false and is_active_prev_month = true, 1, 0) as is_churned_user

        -- Resurrected: A user who is using Warp but did not use Warp the previous month (and is not a new user)
        ,iff(is_active = true and is_active_prev_month = false and is_new_user = 0, 1, 0) as is_resurrected_user

        -- BONUS: Catching the edge case where a user has remained churned for the subsequent months
        ,iff(is_new_user + is_retained_user + is_churned_user + is_resurrected_user = 0, 1, 0) as is_inactive_user
    from user_engagement_history_by_month
)

select * from categories
order by user_id, spine_month --we can omit ranking if we want