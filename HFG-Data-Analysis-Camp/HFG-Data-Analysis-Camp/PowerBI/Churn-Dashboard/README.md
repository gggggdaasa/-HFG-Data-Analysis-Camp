# Customer Churn Analytics Dashboard

Interactive Power BI dashboard analyzing customer churn for a telecom company, built as part of the **HFG Data Analysis Camp**.

---

## Business Questions Answered

1. Total customers vs. customers who churned
2. Which contract type has the highest churn rate
3. Revenue distribution across internet service types
4. Average subscription tenure — churned vs. retained customers
5. Payment methods most associated with churn, and their revenue share
6. Whether Tech Support / Online Security reduces churn
7. Revenue at risk from churned month-to-month customers
8. Interactive slicers (gender, senior citizen, contract type) for exploration

## Data

- **Source:** `churn_analysis_dataset.csv` (7,061 raw rows)
- **Cleaned:** 7,032 unique customers after removing blank rows, duplicate rows, and invalid `TotalCharges` values, plus standardizing `InternetService` labels.

## Files

- `churn_analysis_dataset_cleaned.xlsx` — cleaned dataset used as the Power BI data source
- `Customer_Churn_Analytics_Dashboard.pbix` — the Power BI report file *(add this once exported from Power BI Desktop)*

## Tech Stack

- Power BI Desktop
- Power Query (data cleaning)
- DAX (Count, Sum, Average aggregations; visual-level filters)
