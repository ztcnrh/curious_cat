with date_spine as (
    {{
        dbt_utils.date_spine(
            datepart="month",
            start_date="to_date('2021-01-01', 'yyyy-mm-dd')",
            end_date="to_date('2026-01-01', 'yyyy-mm-dd')"
        )
    }}
)

select
    date_month as month
from date_spine