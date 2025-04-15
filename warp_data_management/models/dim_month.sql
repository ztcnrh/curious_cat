{{
    dbt_utils.date_spine(
        datepart="month",
        start_date="to_date('2022-01-01', 'yyyy-mm-dd')",
        end_date="to_date('2026-01-01', 'yyyy-mm-dd')"
    )
}}