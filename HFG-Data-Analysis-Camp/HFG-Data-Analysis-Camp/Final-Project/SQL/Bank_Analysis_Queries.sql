/* ============================================================
   Data Analysis Bootcamp — Final Project
   Bank Database — Analytical SQL Queries
   Dialect: T-SQL (SQL Server)
   ============================================================
   Coverage:
     - Basic queries (SELECT / WHERE / ORDER BY, date & numeric filters)  -> Q1, Q2
     - Aggregations (COUNT/SUM/AVG, GROUP BY, HAVING)                      -> Q3, Q4
     - Joins (INNER JOIN, LEFT JOIN)                                       -> Q5, Q6
     - CTEs                                                                -> Q7, Q8, Q15
     - Window Functions (LAG, RANK, SUM OVER, AVG OVER, ROW_NUMBER)        -> Q8, Q9, Q10, Q11, Q13, Q15
   Total: 15 queries
   ============================================================ */


/* ------------------------------------------------------------
   Q1: High-Value Active Accounts
   Business Question: Which active accounts hold more than
   100,000 in balance, and how are they ranked?
   Topic: Basic query — WHERE (numeric filter), ORDER BY
   Insight: Identifies the bank's highest-value active accounts —
   useful for VIP customer targeting or premium account programs.
   ------------------------------------------------------------ */
SELECT
    Account_Number,
    Customer_ID,
    Account_Type,
    Balance,
    Status
FROM Account
WHERE Status = 'Active'
  AND Balance > 100000
ORDER BY Balance DESC;


/* ------------------------------------------------------------
   Q2: Recent Loans (Date Filtering)
   Business Question: Which loans were issued from 2025 onward?
   Topic: Basic query — WHERE (date filter), ORDER BY
   Insight: Tracks recent lending activity for portfolio review.
   ------------------------------------------------------------ */
SELECT
    LoanID,
    Customer_ID,
    Amount,
    StartDate,
    LoanType
FROM Loan
WHERE StartDate >= '2025-01-01'
ORDER BY StartDate DESC;


/* ------------------------------------------------------------
   Q3: Branch-Level Account Summary
   Business Question: How much total and average balance does
   each branch hold, and how many accounts does it manage?
   Topic: Aggregation — COUNT, SUM, AVG, GROUP BY
   Insight: Ranks branches by deposit volume — useful for
   resource allocation and branch performance review.
   ------------------------------------------------------------ */
SELECT
    Branch_ID,
    COUNT(*)        AS num_accounts,
    SUM(Balance)     AS total_balance,
    AVG(Balance)     AS avg_balance
FROM Account
GROUP BY Branch_ID
ORDER BY total_balance DESC;


/* ------------------------------------------------------------
   Q4: High-Volume Branches
   Business Question: Which branches manage more than 500
   active accounts?
   Topic: Aggregation — GROUP BY + HAVING
   Insight: Flags branches under high operational load, which
   may need additional staffing or ATM capacity.
   ------------------------------------------------------------ */
SELECT
    Branch_ID,
    COUNT(*) AS active_accounts
FROM Account
WHERE Status = 'Active'
GROUP BY Branch_ID
HAVING COUNT(*) > 500;


/* ------------------------------------------------------------
   Q5: Customer, Account & Branch Detail (INNER JOIN)
   Business Question: Who are the customers with high-balance
   accounts, and which branch holds their account?
   Topic: Join — INNER JOIN (2 joins: Customer→Account→Branch)
   Insight: Full profile of high-value customers per branch —
   supports relationship management and retention efforts.
   ------------------------------------------------------------ */
SELECT
    c.Customer_ID,
    c.FirstName,
    c.LastName,
    a.Account_Number,
    a.Account_Type,
    a.Balance,
    b.BranchName
FROM Customer c
INNER JOIN Account a ON c.Customer_ID = a.Customer_ID
INNER JOIN Branch  b ON a.Branch_ID   = b.BranchId
WHERE a.Balance > 200000
ORDER BY a.Balance DESC;


/* ------------------------------------------------------------
   Q6: Customers With No Loans (LEFT JOIN)
   Business Question: Which customers have never taken a loan?
   Topic: Join — LEFT JOIN (anti-join pattern via IS NULL)
   Insight: Identifies a segment for cross-sell/loan marketing
   campaigns — customers with a banking relationship but no
   lending product yet.
   ------------------------------------------------------------ */
SELECT
    c.Customer_ID,
    c.FirstName,
    c.LastName
FROM Customer c
LEFT JOIN Loan l ON c.Customer_ID = l.Customer_ID
WHERE l.LoanID IS NULL;


/* ------------------------------------------------------------
   Q7: Branch Loan Performance (CTE #1)
   Business Question: Which branches generate the most loan
   volume, and what's their average interest rate?
   Topic: CTE + Aggregation + JOIN
   Insight: Compares lending performance and pricing (interest
   rate) across branches.
   ------------------------------------------------------------ */
WITH BranchLoans AS (
    SELECT
        Branch_ID,
        COUNT(*)          AS total_loans,
        SUM(Amount)        AS total_loan_amount,
        AVG(InterestRate)  AS avg_rate
    FROM Loan
    GROUP BY Branch_ID
)
SELECT
    b.BranchName,
    bl.total_loans,
    bl.total_loan_amount,
    bl.avg_rate
FROM BranchLoans bl
JOIN Branch b ON bl.Branch_ID = b.BranchId
ORDER BY bl.total_loan_amount DESC;


/* ------------------------------------------------------------
   Q8: Monthly Transaction Trend (CTE #2 + Window Function)
   Business Question: How does transaction volume change
   month over month, and is it growing or shrinking?
   Topic: CTE + Window Function — LAG()
   Insight: Reveals seasonality or growth trends in ATM
   transaction activity — key for the "trend over time" chart
   required in the dashboard.
   ------------------------------------------------------------ */
WITH MonthlyTx AS (
    SELECT
        FORMAT(TransactionDate, 'yyyy-MM') AS tx_month,
        COUNT(*)                            AS num_transactions,
        SUM(Amount)                         AS total_amount
    FROM transactions_ATM_Account
    GROUP BY FORMAT(TransactionDate, 'yyyy-MM')
)
SELECT
    tx_month,
    num_transactions,
    total_amount,
    total_amount - LAG(total_amount) OVER (ORDER BY tx_month) AS change_from_prev_month
FROM MonthlyTx
ORDER BY tx_month;


/* ------------------------------------------------------------
   Q9: Customer Ranking by Balance Within State (Window Function)
   Business Question: Who are the top customers by account
   balance in each state?
   Topic: Window Function — RANK() with PARTITION BY
   Insight: Surfaces top customers per region for targeted
   regional relationship management.
   ------------------------------------------------------------ */
SELECT
    c.Customer_ID,
    c.FirstName,
    c.State,
    a.Balance,
    RANK() OVER (PARTITION BY c.State ORDER BY a.Balance DESC) AS balance_rank_in_state
FROM Customer c
JOIN Account a ON c.Customer_ID = a.Customer_ID
ORDER BY c.State, balance_rank_in_state;


/* ------------------------------------------------------------
   Q10: Running Balance Movement per Account (Window Function)
   Business Question: How does an account's cumulative
   transaction total build up over time?
   Topic: Window Function — SUM() OVER with PARTITION BY + ORDER BY
   Insight: Useful for account statements / cash-flow tracking
   for a single account (parameterize Account_Number as needed).
   ------------------------------------------------------------ */
SELECT
    Account_Number,
    TransactionDate,
    Amount,
    SUM(Amount) OVER (PARTITION BY Account_Number ORDER BY TransactionDate) AS running_total
FROM transactions_ATM_Account
WHERE Account_Number = 1000004012
ORDER BY TransactionDate;


/* ------------------------------------------------------------
   Q11: Loan Amount vs. Loan Type Average (Window Function)
   Business Question: Which loans are significantly above the
   average amount for their loan type?
   Topic: Window Function — AVG() OVER with PARTITION BY
   Insight: Flags unusually large loans within each category —
   useful for risk review.
   ------------------------------------------------------------ */
SELECT
    LoanID,
    Customer_ID,
    LoanType,
    Amount,
    AVG(Amount) OVER (PARTITION BY LoanType)              AS avg_amount_for_type,
    Amount - AVG(Amount) OVER (PARTITION BY LoanType)      AS diff_from_avg
FROM Loan
ORDER BY LoanType, diff_from_avg DESC;


/* ------------------------------------------------------------
   Q12: Card Portfolio Breakdown
   Business Question: What's the distribution of card types
   and statuses across the bank's card portfolio?
   Topic: Aggregation + calculated percentage
   Insight: Shows the health of the card portfolio (e.g., % of
   blocked cards) — a KPI candidate for the dashboard.
   ------------------------------------------------------------ */
SELECT
    Card_Type,
    Card_Status,
    COUNT(*) AS num_cards,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Card), 2) AS pct_of_total
FROM Card
GROUP BY Card_Type, Card_Status
ORDER BY num_cards DESC;


/* ------------------------------------------------------------
   Q13: Employee Salary vs. Branch Average (Window Function)
   Business Question: Which employees earn well above their
   branch's average salary?
   Topic: Window Function — AVG() OVER with PARTITION BY
   Insight: Supports HR compensation review / pay equity checks
   within each branch.
   ------------------------------------------------------------ */
SELECT
    Employee_ID,
    FirstName,
    LastName,
    Branch_ID,
    Salary,
    AVG(Salary) OVER (PARTITION BY Branch_ID)             AS branch_avg_salary,
    Salary - AVG(Salary) OVER (PARTITION BY Branch_ID)     AS diff_from_branch_avg
FROM Employee
ORDER BY diff_from_branch_avg DESC;


/* ------------------------------------------------------------
   Q14: Top ATM Locations by Activity
   Business Question: Which ATMs handle the highest transaction
   volume and value?
   Topic: Aggregation + JOIN
   Insight: Identifies high-traffic ATMs — useful for cash
   replenishment planning and maintenance prioritization.
   ------------------------------------------------------------ */
SELECT
    t.ATM_ID,
    a.Location,
    a.Branch_ID,
    COUNT(*)     AS num_transactions,
    SUM(t.Amount) AS total_amount
FROM transactions_ATM_Account t
JOIN ATM a ON t.ATM_ID = a.ATM_ID
GROUP BY t.ATM_ID, a.Location, a.Branch_ID
ORDER BY total_amount DESC;


/* ------------------------------------------------------------
   Q15: Top 3 Customers per Branch by Total Balance
   Business Question: Who are the top 3 highest-balance
   customers at each branch?
   Topic: CTE + Window Function — ROW_NUMBER() with PARTITION BY
   Insight: A classic "Top-N per group" business query — supports
   branch-level VIP customer identification.
   ------------------------------------------------------------ */
WITH CustomerBalance AS (
    SELECT
        a.Branch_ID,
        c.Customer_ID,
        c.FirstName,
        c.LastName,
        SUM(a.Balance) AS total_balance
    FROM Account a
    JOIN Customer c ON a.Customer_ID = c.Customer_ID
    GROUP BY a.Branch_ID, c.Customer_ID, c.FirstName, c.LastName
),
RankedCustomers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY Branch_ID ORDER BY total_balance DESC) AS rn
    FROM CustomerBalance
)
SELECT
    Branch_ID,
    Customer_ID,
    FirstName,
    LastName,
    total_balance
FROM RankedCustomers
WHERE rn <= 3
ORDER BY Branch_ID, total_balance DESC;
