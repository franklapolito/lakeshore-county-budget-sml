-- lakeshore_county_budget : canonical DDL
-- Column order is exactly the CSV column order, so COPY INTO can be positional.
USE DATABASE <% database %>;
USE SCHEMA <% schema %>;

CREATE OR REPLACE TABLE DIM_DATE (
  DATE_KEY                        NUMBER(8,0)   NOT NULL,
  DATE_NAME                       VARCHAR(10)   NOT NULL,
  FULL_DATE                       DATE          NOT NULL,
  DAY_OF_MONTH                    NUMBER(2,0)   NOT NULL,
  DAY_OF_WEEK_NAME                VARCHAR(10)   NOT NULL,
  IS_WEEKEND                      NUMBER(1,0)   NOT NULL,
  IS_MONTH_END                    NUMBER(1,0)   NOT NULL,
  MONTH_KEY                       NUMBER(6,0)   NOT NULL,
  MONTH_NAME                      VARCHAR(7)    NOT NULL,
  MONTH_OF_YEAR                   NUMBER(2,0)   NOT NULL,
  QUARTER_KEY                     NUMBER(5,0)   NOT NULL,
  QUARTER_NAME                    VARCHAR(8)    NOT NULL,
  QUARTER_OF_YEAR                 NUMBER(1,0)   NOT NULL,
  YEAR_KEY                        NUMBER(4,0)   NOT NULL,
  YEAR_NAME                       VARCHAR(4)    NOT NULL,
  FISCAL_YEAR_KEY                 NUMBER(4,0)   NOT NULL,
  FISCAL_YEAR_NAME                VARCHAR(6)    NOT NULL,
  FISCAL_QUARTER_KEY              NUMBER(5,0)   NOT NULL,
  FISCAL_QUARTER_NAME             VARCHAR(10)   NOT NULL,
  FISCAL_QUARTER_OF_YEAR          NUMBER(1,0)   NOT NULL,
  FISCAL_MONTH_KEY                NUMBER(6,0)   NOT NULL,
  FISCAL_MONTH_NAME               VARCHAR(24)   NOT NULL,
  FISCAL_MONTH_OF_YEAR            NUMBER(2,0)   NOT NULL,
  PRIOR_YEAR_QUARTER_KEY          NUMBER(5,0)   NOT NULL,
  PRIOR_YEAR_MONTH_KEY            NUMBER(6,0)   NOT NULL,
  PRIOR_YEAR_DATE_KEY             NUMBER(8,0)   NOT NULL,
  PRIOR_FISCAL_YEAR_QUARTER_KEY   NUMBER(5,0)   NOT NULL,
  PRIOR_FISCAL_YEAR_MONTH_KEY     NUMBER(6,0)   NOT NULL,
  CONSTRAINT PK_DIM_DATE PRIMARY KEY (DATE_KEY)
);
COMMENT ON TABLE DIM_DATE IS 'One row per day, 2022-12-01 to 2026-11-30, with a calendar hierarchy (Year > Quarter > Month > Day) and a fiscal hierarchy (Fiscal Year > Fiscal Quarter > Fiscal Month > Day). The fiscal year runs 1 December to 30 November and is named for the calendar year it ends in: FY2026 = 2025-12-01 to 2026-11-30. The PRIOR_* keys hold the same quarter, month or day one year earlier at that level''s own grain and drive ParallelPeriod in the semantic model. Facts join at month-end dates.';

CREATE OR REPLACE TABLE DIM_FUND (
  FUND_KEY        NUMBER(4,0)   NOT NULL,
  FUND_CODE       VARCHAR(4)    NOT NULL,
  FUND_NAME       VARCHAR(40)   NOT NULL,
  FUND_TYPE       VARCHAR(20)   NOT NULL,
  FUND_CATEGORY   VARCHAR(20)   NOT NULL,
  IS_RESTRICTED   NUMBER(1,0)   NOT NULL,
  CONSTRAINT PK_DIM_FUND PRIMARY KEY (FUND_KEY)
);
COMMENT ON TABLE DIM_FUND IS 'The six county funds. FUND_TYPE is Governmental or Proprietary; FUND_CATEGORY is General, Special Revenue, Capital Projects, Debt Service or Enterprise. IS_RESTRICTED = 1 means the money is legally limited to a purpose (grants, motor fuel tax, capital, debt).';

CREATE OR REPLACE TABLE DIM_DEPARTMENT (
  DEPARTMENT_KEY    NUMBER(4,0)   NOT NULL,
  DEPARTMENT_CODE   VARCHAR(4)    NOT NULL,
  DEPARTMENT_NAME   VARCHAR(60)   NOT NULL,
  BUREAU_NAME       VARCHAR(40)   NOT NULL,
  FUNCTION_AREA     VARCHAR(30)   NOT NULL,
  OFFICE_TYPE       VARCHAR(20)   NOT NULL,
  CONSTRAINT PK_DIM_DEPARTMENT PRIMARY KEY (DEPARTMENT_KEY)
);
COMMENT ON TABLE DIM_DEPARTMENT IS 'The 43 departments of Lakeshore County (fictional), in the organization hierarchy Function Area > Bureau > Department. OFFICE_TYPE is Elected Official (Sheriff, Chief Judge, State''s Attorney, Assessor, Treasurer, County Clerk, Recorder, Board) or Appointed.';

CREATE OR REPLACE TABLE DIM_EXPENSE_TYPE (
  EXPENSE_TYPE_KEY    NUMBER(4,0)   NOT NULL,
  EXPENSE_TYPE_CODE   VARCHAR(3)    NOT NULL,
  EXPENSE_TYPE_NAME   VARCHAR(30)   NOT NULL,
  EXPENSE_CATEGORY    VARCHAR(20)   NOT NULL,
  CONSTRAINT PK_DIM_EXPENSE_TYPE PRIMARY KEY (EXPENSE_TYPE_KEY)
);
COMMENT ON TABLE DIM_EXPENSE_TYPE IS 'The eleven object classes (expense types) in the hierarchy Expense Category > Expense Type. Categories: Personnel, Operating, Capital, Fixed Charges, Other.';

CREATE OR REPLACE TABLE FACT_BUDGET_ACTUAL (
  BUDGET_ACTUAL_KEY    NUMBER(10,0)   NOT NULL,
  DATE_KEY             NUMBER(8,0)    NOT NULL,
  FUND_KEY             NUMBER(4,0)    NOT NULL,
  DEPARTMENT_KEY       NUMBER(4,0)    NOT NULL,
  EXPENSE_TYPE_KEY     NUMBER(4,0)    NOT NULL,
  FISCAL_YEAR          NUMBER(4,0)    NOT NULL,
  FISCAL_MONTH         NUMBER(2,0)    NOT NULL,
  ALLOTMENT_AMOUNT     NUMBER(16,2)   NOT NULL,
  AMENDMENT_AMOUNT     NUMBER(16,2)   NOT NULL,
  EXPENDITURE_AMOUNT   NUMBER(16,2)   NOT NULL,
  ENCUMBRANCE_AMOUNT   NUMBER(16,2)   NOT NULL,
  TRANSACTION_COUNT    NUMBER(8,0)    NOT NULL,
  CONSTRAINT PK_FACT_BUDGET_ACTUAL PRIMARY KEY (BUDGET_ACTUAL_KEY)
);
COMMENT ON TABLE FACT_BUDGET_ACTUAL IS 'Budget and actuals at month-end x fund x department x expense type, FY2023 to FY2026 through October 2026. ALLOTMENT_AMOUNT is the adopted appropriation spread over the twelve fiscal months (evenly, except debt service on its 1 Dec / 1 Jun payment schedule), so the sum over a fiscal year is the adopted budget. AMENDMENT_AMOUNT is a supplemental appropriation or transfer in the month the Board approved it. EXPENDITURE_AMOUNT is cash spent in the month; ENCUMBRANCE_AMOUNT is new purchase-order commitments issued in the month. DATE_KEY is the last day of the month.';

CREATE OR REPLACE TABLE FACT_POSITION_SNAPSHOT (
  POSITION_SNAPSHOT_KEY   NUMBER(10,0)   NOT NULL,
  DATE_KEY                NUMBER(8,0)    NOT NULL,
  DEPARTMENT_KEY          NUMBER(4,0)    NOT NULL,
  FUND_KEY                NUMBER(4,0)    NOT NULL,
  FISCAL_YEAR             NUMBER(4,0)    NOT NULL,
  FISCAL_MONTH            NUMBER(2,0)    NOT NULL,
  BUDGETED_FTE            NUMBER(9,1)    NOT NULL,
  FILLED_FTE              NUMBER(9,1)    NOT NULL,
  VACANT_FTE              NUMBER(9,1)    NOT NULL,
  CONSTRAINT PK_FACT_POSITION_SNAPSHOT PRIMARY KEY (POSITION_SNAPSHOT_KEY)
);
COMMENT ON TABLE FACT_POSITION_SNAPSHOT IS 'Month-end snapshot of budgeted, filled and vacant full-time-equivalent positions by department and fund. A BALANCE, not a flow: never sum across months. The count for a period is the last month-end in that period.';
