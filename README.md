# Lakeshore County Budget, AtScale SML model

Budget versus actual for a fictional large metropolitan county: one governed
definition of adopted, adjusted, spent, variance and positions, served to Power
BI, Excel and every MCP client. Built for the FRC SLED seller enablement
session (use case 2: AI assistants and agents that return the official number).

Emitted by `lakeshore-county-budget/sml/emit_sml.py`; the data is generated
by `lakeshore-county-budget/data/generate.py` (seed 42) and loaded by
`snowflake/load.sh`. Re-run the emitter rather than editing YAML by hand.

## Inputs

| File in `context/` | What it is |
|---|---|
| `use_case.md` | The governed definitions, the grain, the six engineered stories with their numbers, limitations. The highest-leverage input. |
| `nlqs.md` | The eight hero questions with answers certified against the warehouse. |
| `ddl.sql` | Snowflake `CREATE TABLE` statements for the six tables, with table comments. |
| `erd.mmd` | Mermaid ERD: two facts, four dimensions. |
| `build.yaml` | The build parameters this emit used. |
| Data profile | (not provided; the emitter reads the generator's column list and the warehouse was verified by `04_validate.sql`) |
| Existing SML files | (not provided; new model) |

Target warehouse: **Snowflake** (`LAKESHORE_COUNTY_BUDGET_DEMO.COUNTY_BUDGET`).

## Build parameters

| Parameter | Value | Source |
|---|---|---|
| `unrelated_dimension_handling` | `empty` | explicit: position metrics must be empty by expense type, not repeated |
| `warehouse` | Snowflake | explicit |
| `as_connection` | `SnowflakePartner` | explicit (`SnowflakePartner` on demo2; `con1` on eshack and swtdev) |
| `database` / `schema` | `LAKESHORE_COUNTY_BUDGET_DEMO` / `COUNTY_BUDGET` | explicit |
| `model_unique_name` | `lakeshore_county_budget` | explicit |
| `catalog_unique_name` | `lakeshore_county_budget_catalog` | explicit, `<model>_catalog` |
| `currency` | USD | explicit |
| `time_window` | fiscal, 1 Dec to 30 Nov, plus a calendar contrast hierarchy | explicit |
| `use_cases_covered` | expenditure budget vs actual, positions | explicit |
| `use_cases_excluded` | revenue, cash, fund balance, encumbrance balances | explicit |
| `semi_additive_default` | `last` on the three position metrics over the snapshot's Date relationship | explicit |
| SML catalog `version` | `1.9` | explicit; demo2 accepted 1.9 on 2026-11-02 |

## Assumptions and decisions

- **One monthly fact carries budget and actual.** The adopted appropriation is
  spread over the twelve fiscal months as allotments, so the same fact answers
  "full-year adopted budget" at the Fiscal Year level and "year-to-date
  allotment" at a month, and budget-versus-actual is a plain additive subtraction.
- **Adjusted, variance and available balance are calculated columns on the fact**,
  not MDX, so they are additive base metrics that Power BI and Excel aggregate
  natively and the agent can filter on.
- **Two hierarchies in one Date Dimension share the `Day` leaf.** Upper levels have
  distinct unique names (Fiscal Year vs Year). Each sub-year level carries its own
  prior-year key at its own grain (`PRIOR_FISCAL_YEAR_QUARTER_KEY`,
  `PRIOR_FISCAL_YEAR_MONTH_KEY`, `PRIOR_YEAR_QUARTER_KEY`, `PRIOR_YEAR_MONTH_KEY`);
  the top level of each hierarchy declares none; `Day` declares none because the
  facts are monthly.
- **Position metrics are `semi_additive: last`** over `FACT_POSITION_SNAPSHOT_Date_Dimension` and
  `calculation_method: sum`, so they add across departments and funds and take the
  last month over time.
- **`unrelated_dimensions_handling: empty` on every base metric**, so Budgeted
  Positions by Expense Type is empty rather than the total repeated.
- **Every ratio guards both operands and the zero denominator.**
- **`is_unique_key` only where the key is unique in the data**: Day, Fund,
  Department, Expense Type.
- **No `dimensions:` block in the model file**: a clean star, every dimension has a
  fact relationship, none is degenerate.
- **Revenue is a third fact at fund x revenue source, with no department key.** Revenue
  measures are empty by Organization and Expense Type (`empty` handling), and Net
  Position is meaningful only by fund and time. Position Class joins the snapshot
  only; budget and revenue measures are empty by it.
- **No customer, vendor or person names.** Lakeshore County and every department
  are fictional; the structure follows a public US county chart of accounts.

## Generation summary

| Object | Count |
|---|---|
| Datasets | 9 (3 facts, 6 dimension sources) |
| Dimensions | 6 |
| Hierarchies | 7 |
| Level attributes | 19 |
| Secondary attributes | 12 |
| Base metrics | 14 |
| Calculated metrics | 20 |
| Model relationships | 11 |
| Calculated columns | 4 (3 on `FACT_BUDGET_ACTUAL`, 1 on `FACT_REVENUE`) |
| Role-play prefixes | none |
| Snowflake bridges | none |

Metric folders: Budget, Actuals, Variance, Revenue, Time Relative, Calendar Contrast, Positions.

Caveats: FY2023 has no prior year, so prior-year measures are empty for it. At
the Fiscal Year level FY2026 holds eleven months against FY2025's twelve; the
Fiscal YTD measures compare like for like.

## Reproducing this build

`context/` holds verbatim copies of every input (`use_case.md`, `nlqs.md`,
`ddl.sql`, `erd.mmd`, `build.yaml`). Re-running the emitter with the same
parameters produces identical YAML, and `data/generate.py --seed 42` produces
byte-identical CSVs.
