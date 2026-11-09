# Hero questions, with answers certified against the warehouse

Each answer below was computed in SQL against `LAKESHORE_COUNTY_BUDGET_DEMO.COUNTY_BUDGET`
(see `snowflake/nlq_smoke_tests.sql`). The model must return the same number
from Claude Desktop, Power BI and Excel. "As of" is 31 October 2026, FY2026
month 11.

| # | Question (as a seller would ask it) | Certified answer | What it proves |
|---|---|---|---|
| 1 | How much has the General Fund spent in FY2026, and how does that compare to budget? | $1,563.5M spent against a $1,590.9M year-to-date allotment: 98.3% of the FYTD allotment, 90.1% of the full-year adopted budget ($1,735.5M). | The baseline. Same number in every tool. |
| 2 | Which departments are over budget fiscal year to date? | Corrections (−$15.9M), Facilities Management (−$3.1M), Public Defender (−$2.5M), Juvenile Detention Center (−$1.9M). Everyone else is under. | A governed variance: adjusted, not adopted; fiscal, not calendar. |
| 3 | How much debt service did the county pay in 2026? | $250.4M in FY2026 (two payments, 1 Dec 2025 and 1 Jun 2026). A calendar-2026 reading gives $123.5M, half the figure. | The fiscal-year trap. A raw-SQL agent assumes calendar year. |
| 4 | How many budgeted positions does the Sheriff have in FY2026, and how many are filled? | 5,338.1 budgeted, 4,471.7 filled as of October 2026 (866.4 vacant, 16.2%). | The snapshot trap. A raw-SQL agent sums months and gets 58,719. |
| 5 | Corrections is over budget. What is driving it, and how does its vacancy rate compare to the county? | Overtime: $38.7M spent on a $22.2M allotment (175%), while salaries are $6.9M under. Vacancy 21.5% versus 10.6% county-wide. Overtime FYTD is up from $35.8M in FY2025. | The agentic chain: three governed answers in one conversation, each traceable. |
| 6 | Behavioral Health looks 18% over its adopted budget. Is it actually over budget? | No. An $18M Grants Fund supplemental was approved in April 2026. Against the adjusted budget of $90.1M it has spent $85.0M, 94%. | Adopted versus adjusted: the definition lives in the model, not in the prompt. |
| 7 | Which function area grew spending the most versus last fiscal year, year to date? | Property & Taxation +8.6% (election year), Health +6.7%, Economic Development +5.0%; General Government +1.1% is the slowest. | Prior-fiscal-year time intelligence on the fiscal hierarchy. |
| 8 | Show percent of budget spent by bureau, FY2026, next to the share of the year elapsed. | A table of 19 bureaus against the FYTD allotment: Public Defender 102.9%, Sheriff 101.2%, County Health System 98.5%, Bureau of Asset Management 85.5%. Against the full-year adjusted budget the Sheriff is at 92.8% with 91.7% of the year elapsed. | The BI triangle: the same table in Power BI and Excel. |

## Certified over the demo2 MCP server, 2026-11-09

All eight answers above were returned by `run_query` against
`atscale_catalogs.lakeshore_county_budget_catalog.lakeshore_county_budget` on
demo2 and matched the SQL to the cent (Q1 $1,563,534,724.83; Q3 $250,445,088.00
vs $123,456,931.63; Q4 5,338.1 / 4,471.7; Q6 94.37%; Q7 Property & Taxation
+8.55%). `get_outbound_queries` returned the Snowflake SQL for Q1.

One rule for the agent, now also in the metric descriptions: a positions
question must carry a time level (Fiscal Year, Fiscal Quarter, Fiscal Month,
Year or Month). Asked with no time level at all, the engine sums every
month-end since 2022 and the Sheriff reads 245,632. The MCP server warns the
agent when this is about to happen; phrase Q4 as "in FY2026" or "as of October
2026".

## The two raw-SQL contrast questions

If the raw-SQL half is shown, ask questions 3 and 4 first of an agent writing
its own SQL against the tables, then of the same agent through AtScale. The
raw answers are wrong in the two ways the governed definitions prevent, and
the wrong numbers are known in advance: $123.5M and 58,719.

## Where the answers come from

Every governed answer is traceable: the metric definition is in the SML YAML
(`metrics/`, `calculations/`), and the SQL AtScale sent to Snowflake is
returned by the MCP server's `get_outbound_queries` tool.
