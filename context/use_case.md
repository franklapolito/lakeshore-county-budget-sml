# Lakeshore County budget versus actual: the governed definitions

Lakeshore County is a fictional large metropolitan county. Its finance office,
budget office, 43 departments and an AI assistant all need the same numbers
from the same books. This document is the governed definition of those
numbers. It is the input to the semantic model, and the model is the only
place those definitions are enforced.

## The scenario

The county adopts an annual budget for a fiscal year that runs **1 December to
30 November** and is named for the calendar year it ends in. FY2026 is
2025-12-01 to 2026-11-30. The data is as of **31 October 2026**: eleven of
FY2026's twelve months are closed, so 91.7% of the year has elapsed.

Every department reports spend against budget in its own Power BI model or
Excel workbook. Finance reports the official figure to the Board. The two
disagree whenever someone sums positions across months, uses calendar years,
or compares spend to the adopted budget after an amendment moved it. An AI
assistant asked the same question twice gives two answers for the same
reasons.

## Grain

| Table | Grain | Rows |
|---|---|---|
| `FACT_BUDGET_ACTUAL` | month-end × fund × department × expense type | 16,223 |
| `FACT_POSITION_SNAPSHOT` | month-end × department × fund | 1,927 |
| `DIM_DATE` | day, 2022-12-01 to 2026-11-30 | 1,461 |
| `DIM_FUND` | fund | 6 |
| `DIM_DEPARTMENT` | department (Function Area > Bureau > Department) | 43 |
| `DIM_EXPENSE_TYPE` | object class (Expense Category > Expense Type) | 11 |

Facts join `DIM_DATE` at the **last day of the month**.

## Governed definitions

- **Adopted Budget** is the appropriation the Board adopted, spread across the
  twelve fiscal months as allotments (evenly, except debt service, which is
  allotted on its 1 December and 1 June payment schedule). Summed over a
  fiscal year it is the adopted budget; summed through October it is the
  year-to-date allotment.
- **Budget Amendments** are supplemental appropriations and transfers, booked
  in the month the Board approved them.
- **Adjusted Budget** = Adopted Budget + Budget Amendments. **Every variance
  is against the adjusted budget**, never the adopted one.
- **Expenditures** are cash spent in the month. **Encumbrances** are new
  purchase-order commitments issued in the month.
- **Budget Variance** = Adjusted Budget − Expenditures. Negative means over
  budget. **Available Balance** also subtracts Encumbrances.
- **Percent of Budget Spent** = Expenditures ÷ Adjusted Budget. Read it next to
  the share of the year elapsed (91.7% as of October).
- **Fiscal year to date** means from 1 December of the fiscal year to the
  selected month. The calendar hierarchy exists so the difference can be shown,
  not so it can be used for budget reporting.
- **Budgeted, Filled and Vacant Positions** are month-end balances in
  full-time equivalents. The value for any period is the **last month-end in
  that period**. They are never summed across months.
- **Vacancy Rate** = Vacant Positions ÷ Budgeted Positions.

## Engineered stories

All figures are from the seed-42 data and are asserted in
`snowflake/04_validate.sql`.

| | Story | The number |
|---|---|---|
| S1 | **Calendar versus fiscal.** Debt service is paid 1 December and 1 June. The December 2025 payment is FY2026 but calendar 2025. | Debt service FY2026: **$250.4M**. Calendar 2026: **$123.5M**. |
| S2 | **Headcount is a snapshot.** Summing the Sheriff's budgeted positions across FY2026's months gives eleven times the truth. | As of October 2026: **5,338.1** budgeted, **4,471.7** filled. The naive sum: 58,719.1. |
| S3 | **Over budget, fiscal year to date.** Exactly four departments are over their adjusted FYTD budget in FY2026. | Corrections (−$15.9M, 105.0%), Facilities Management (104.4%), Public Defender (102.9%), Juvenile Detention Center (103.6%). |
| S4 | **Adopted versus adjusted.** Behavioral Health Services received an $18M Grants Fund supplemental in April 2026 (FY2026 M05). | FYTD spend $85.0M against $72.1M adopted allotment (118%) but $90.1M adjusted (94%). Under budget. |
| S5 | **Growth versus prior fiscal year, FYTD.** | Behavioral Health +27.3%, Clerk Elections +24.8% (March 2026 primary), Health function area +6.7%; Emergency Management −15.4% (a one-off FY2025 grant). |
| S6 | **Vacancy drives overtime.** Corrections runs the county's highest vacancy rate and its overtime is 175% of allotment. | Corrections vacancy **21.5%** vs county **10.6%**; overtime $38.7M on a $22.2M allotment; salaries under by $6.9M. |

## Headline figures, FY2026 through October

| Figure | Value |
|---|---|
| Expenditures, all funds | $3,648,602,152.93 |
| Adopted allotment, 11 of 12 months | $3,722,197,405.74 |
| Amendments | $24,000,000.00 |
| General Fund expenditures | $1,563,534,724.83 |
| General Fund adopted allotment, 11 months | $1,590,909,737.76 |

## Known limitations

- One county, one data platform. Revenue, cash and fund balance are out of
  scope; this is the expenditure side of the budget.
- Position data covers departments with staff; Debt Service and Fixed Charges
  have no positions.
- FY2023 has no prior year in the data, so prior-year measures are empty for
  it.
- Encumbrances are issued amounts, not open balances.
