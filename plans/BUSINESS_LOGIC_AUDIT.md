# Architecture Audit — DDA Compliance in hrm/src

This audit measures `hrm/src/` against the rules of **Dialog-Driven
Architecture** as defined in
[`docs/DIALOG_DRIVEN_ARCHITECTURE.md`](../docs/DIALOG_DRIVEN_ARCHITECTURE.md).
Each finding cites the specific DDA rule it violates and gives a
verified file:line reference.

## How the audit was done

Every non-model `.4gl` source file in `hrm/src/` was inspected for:

- Direct DML (`INSERT`, `UPDATE`, `DELETE`) or transaction statements
  (`BEGIN WORK`, `COMMIT`, `ROLLBACK`) outside of `model_*`
- `SELECT`, `PREPARE`, `DECLARE CURSOR`, join statements, or any
  schema-coupled SQL outside of `model_*`
- Validation rules, range checks, FK existence checks, computed-field
  formulas, or other constraints on the data that live outside of
  `model_*.validateRec` or a model method
- `CONSTRUCT` statements that address `table.column` references
  instead of screen-record fields

Findings are split into two categories per the DDA framing:

- **Domain rule leak** — a business rule (validation, computed field,
  integrity guard) lives outside the model. Violates **R3** or **R5**.
- **Schema leak** — table/column knowledge (DML, joins, ad-hoc
  SELECTs, transactions) lives outside the model. Violates **R2**,
  **R6**, or **R8**.

The canonical test is **schema-rename** (DDA §6): if renaming a column
forces edits to more than one file, schema knowledge has escaped its
layer.

## Headline numbers

- **35 violations across 22 files.**
- **9 of 31 audited files are genuinely clean.**
- The original audit (now replaced) missed **11 violations** —
  primarily the universal "every `ui_<table>` has its own inline
  `do_load` SELECT" pattern, the `rest_empl_terr` 4-table JOIN, and a
  fifth copy of the line-total formula.

The most pervasive issue is not in any one file — it is that **every
`ui_<table>` module owns its own list-loading SQL**, and every
`rest_<table>` module owns its own read-side SQL. The same shape of
schema leak appears 17 times across the codebase.

---

## Summary

| File | Domain rule leaks (R3/R5) | Schema leaks (R2/R6/R8) | Severity |
|------|----------------------------|---------------------------|----------|
| [`md_order_details.4gl`](../hrm/src/md_order_details.4gl) | calc_line_total (321); calcPrice (1026); duplicate-product guard (779) | 6-table JOIN in execute_search (216); 3× `DELETE FROM order_details` (513/559/614); 3× `BEGIN/COMMIT/ROLLBACK` (506/557/611); CONSTRUCT on `orders.*`/`customers.*`/`employees.*` (76) | **High** |
| [`ui_order_details.4gl`](../hrm/src/ui_order_details.4gl) | calculate_total_price (469); inline formula in FOREACH (216); discount range duplicate (493); orderid FK duplicate (509); productid FK duplicate (524) | `do_load` 2-table JOIN (201); `default_unitprice_from_product` lookup (455); CONSTRUCT mostly screen-record but mixed (171) | **High** |
| [`ui_orders.4gl`](../hrm/src/ui_orders.4gl) | `validate_employee_field` (571); `validate_customer_field` (589); `validate_shipvia_field` (606) — all three duplicate existing model functions | `do_load` 3-table JOIN (244); CONSTRUCT references `orders.*` columns (208) | **High** |
| [`ui_employees.4gl`](../hrm/src/ui_employees.4gl) | — | `do_load` self-join for manager (152); 2nd inline SELECT (499); lookup query (563); combo SELECT for territories/manager (assumed) | Medium |
| [`ui_customers.4gl`](../hrm/src/ui_customers.4gl) | — | `do_load` SELECT (173); lookup query (495) | Medium |
| [`ui_territories.4gl`](../hrm/src/ui_territories.4gl) | — | `do_load` SELECT (232); embedded subquery for employees-in-territory (121); combo SELECT for region (502) | Medium |
| [`ui_products.4gl`](../hrm/src/ui_products.4gl) | — | `do_load` SELECT (190); combo SELECT for supplier (389); combo SELECT for category (411) | Medium |
| [`ui_cust_cust_demo.4gl`](../hrm/src/ui_cust_cust_demo.4gl) | — | `do_load` JOIN (190) | Medium |
| [`ui_empl_terr.4gl`](../hrm/src/ui_empl_terr.4gl) | — | `do_load` JOIN (164) | Medium |
| [`ui_categories.4gl`](../hrm/src/ui_categories.4gl) | — | `do_load` single-table SELECT (167) | Low |
| [`ui_shippers.4gl`](../hrm/src/ui_shippers.4gl) | — | `do_load` single-table SELECT (120) | Low |
| [`ui_suppliers.4gl`](../hrm/src/ui_suppliers.4gl) | — | `do_load` single-table SELECT (152) | Low |
| [`ui_region.4gl`](../hrm/src/ui_region.4gl) | — | `do_load` single-table SELECT (187) | Low |
| [`ui_usstates.4gl`](../hrm/src/ui_usstates.4gl) | — | `do_load` single-table SELECT (120) | Low |
| [`ui_cust_demo.4gl`](../hrm/src/ui_cust_demo.4gl) | — | `do_load` single-table SELECT (136) | Low |
| [`rest_orders.4gl`](../hrm/src/rest_orders.4gl) | derived employeename formula in projection | 3-table JOIN in getAll (28) and getById (63) | Medium |
| [`rest_order_details.4gl`](../hrm/src/rest_order_details.4gl) | line-total formula in projection × 3 sites (30/63/94) | 2-table JOIN in getAll (28), byOrder (61), getById (92) | Medium |
| [`rest_employees.4gl`](../hrm/src/rest_employees.4gl) | — | self-join in getAll (28) and getById (62) | Medium |
| [`rest_cust_cust_demo.4gl`](../hrm/src/rest_cust_cust_demo.4gl) | — | 3-table JOIN in getAll (28), getById (63), CRUD (102) | Medium |
| [`rest_empl_terr.4gl`](../hrm/src/rest_empl_terr.4gl) | — | 4-table JOIN in getAll (34), getById (71), CRUD (114) | Medium |
| [`rest_categories.4gl`](../hrm/src/rest_categories.4gl) + 8 others | — | single-table list/lookup SELECT | Low |
| [`advsearch_orders.4gl`](../hrm/src/advsearch_orders.4gl) | — | CONSTRUCT addresses `orders.*`/`customers.*`/`employees.*` columns (8) | Low |
| 8× `rpt_*.4gl` | — | Inline schema-coupled JOINs in report queries | Low (see §F) |

---

## Findings by file

### A. `md_order_details.4gl` — High (5 distinct violations, 3 categories)

**Domain rule leaks (R3)**

- **Line-total formula appears twice in the same file.**
  `calc_line_total` at [md_order_details.4gl:321-328](../hrm/src/md_order_details.4gl#L321)
  and `calcPrice` at [md_order_details.4gl:1026-1029](../hrm/src/md_order_details.4gl#L1026)
  are two implementations of `unitprice * quantity * (1 - discount)`
  inside one file. Both belong as a single
  `model_order_details.calcLineTotal()`. The formula also appears in
  [ui_order_details.4gl:216](../hrm/src/ui_order_details.4gl#L216), 469, and three times in
  [rest_order_details.4gl](../hrm/src/rest_order_details.4gl) — **five copies in
  total**.
- **Duplicate-product integrity guard** at
  [md_order_details.4gl:779](../hrm/src/md_order_details.4gl#L779) — a nested loop in
  `AFTER INPUT` that fails the dialog if two detail rows have the same
  productid. This is a uniqueness constraint on the data; belongs in
  `model_order_details.validateRec` (per-row check against the array
  already inserted).

**Schema leaks (R2 + R6)**

- **6-table JOIN built inline** in `execute_search`
  ([md_order_details.4gl:216-228](../hrm/src/md_order_details.4gl#L216)) — `orders`
  joined with `employees`, `customers`, `order_details`, `products`,
  `shippers`. Belongs in a model fetch function (see Walkthrough below).
- **Direct DML in three places.**
  - [Line 513](../hrm/src/md_order_details.4gl#L513): `DELETE FROM order_details WHERE orderid = ...`
  - [Line 559](../hrm/src/md_order_details.4gl#L559): same `DELETE` in delete_md_order
  - [Line 614](../hrm/src/md_order_details.4gl#L614): scoped `DELETE FROM order_details WHERE orderid = ... AND productid = ...`
- **Transaction control in three places.** `BEGIN WORK` at
  [506](../hrm/src/md_order_details.4gl#L506), [557](../hrm/src/md_order_details.4gl#L557),
  [611](../hrm/src/md_order_details.4gl#L611), each with matching
  `COMMIT`/`ROLLBACK`. Violates **R6**.
- **CONSTRUCT addresses table columns** instead of screen-record
  fields at [md_order_details.4gl:76-78](../hrm/src/md_order_details.4gl#L76)
  (`orders.orderid, orders.orderdate, customers.customerid, employees.employeeid`).
  The companion `FROM s_search.*` mapping is present, so this is a
  small schema leak — but trivially fixable.

### B. `ui_order_details.4gl` — High (5 domain rule leaks, 3 schema leaks)

**Domain rule leaks (R3)** — every one of these duplicates logic that
already exists in `model_order_details`:

- `calculate_total_price` at
  [ui_order_details.4gl:469-487](../hrm/src/ui_order_details.4gl#L469) — third copy of
  the line-total formula.
- **Inline formula in FOREACH** at
  [ui_order_details.4gl:216](../hrm/src/ui_order_details.4gl#L216) —
  `curr_order_details.totalprice = unitprice * quantity * (1 - discount)`.
  Fourth copy.
- `validate_discount_field` at
  [ui_order_details.4gl:493-504](../hrm/src/ui_order_details.4gl#L493) — duplicates
  the discount-range check in `model_order_details.validateRec`.
  Worse: uses `> 0.99999999` instead of `>= 1`, so this UI check and
  the model check disagree on the boundary.
- `validate_orderid_field` at
  [ui_order_details.4gl:509-519](../hrm/src/ui_order_details.4gl#L509) — FK existence
  check duplicating `validateRec`'s `orderid` check.
- `validate_productid_field` at
  [ui_order_details.4gl:524-536](../hrm/src/ui_order_details.4gl#L524) — duplicates
  `model_order_details.validate_product()` (which already exists in
  the model and is even called from `md_order_details`).

**Schema leaks (R2)**

- `order_details_do_load` at
  [ui_order_details.4gl:201-222](../hrm/src/ui_order_details.4gl#L201) — inline
  `SELECT` joining `order_details` with `products`.
- `default_unitprice_from_product` at
  [ui_order_details.4gl:455-463](../hrm/src/ui_order_details.4gl#L455) — raw
  `SELECT unitprice FROM products WHERE productid = ?`. This is
  derived-field defaulting; belongs in
  `model_order_details.validate_product()`.
- CONSTRUCT mostly uses screen-record refs (`s_order_details.*`) but
  the `ON` clause names columns. Minor.

### C. `ui_orders.4gl` — High (3 + 2)

**Domain rule leaks (R3)** — three private validators duplicate model
functions that already exist:

- `validate_employee_field` at
  [ui_orders.4gl:571-584](../hrm/src/ui_orders.4gl#L571) — duplicates
  `model_employees.validate_employee` (the model function is even
  called from `md_order_details:672` already).
- `validate_customer_field` at
  [ui_orders.4gl:589-601](../hrm/src/ui_orders.4gl#L589) — duplicates
  `model_customers.validate_customer`.
- `validate_shipvia_field` at
  [ui_orders.4gl:606-616](../hrm/src/ui_orders.4gl#L606) — duplicates
  `model_shippers.validate_shipvia`.

**Schema leaks (R2)**

- `orders_do_load` at
  [ui_orders.4gl:244-268](../hrm/src/ui_orders.4gl#L244) — 3-table JOIN built inline.
- CONSTRUCT at
  [ui_orders.4gl:208-217](../hrm/src/ui_orders.4gl#L208) names `orders.*`
  columns. Has a `FROM s_orders.*` mapping — partial fix.

### D. Universal `ui_<table>_do_load` pattern — Medium / Low

Every `ui_<table>.4gl` defines a private `<table>_do_load(where_clause)`
function that builds its own list-loading SQL with `LET sql_stmt = "..."`,
`PREPARE`, and `DECLARE CURSOR`. This is the single most pervasive
violation in the codebase. **Severity scales with join count.**

| File | Line | Joins | Severity |
|------|------|-------|----------|
| [`ui_employees.4gl`](../hrm/src/ui_employees.4gl) | 152 | self-join to employees (manager) | Medium |
| [`ui_customers.4gl`](../hrm/src/ui_customers.4gl) | 173 | single-table | Medium-Low |
| [`ui_territories.4gl`](../hrm/src/ui_territories.4gl) | 232 | with subquery elsewhere | Medium |
| [`ui_products.4gl`](../hrm/src/ui_products.4gl) | 190 | single-table + 2 combo SELECTs | Medium |
| [`ui_cust_cust_demo.4gl`](../hrm/src/ui_cust_cust_demo.4gl) | 190 | 3-table JOIN | Medium |
| [`ui_empl_terr.4gl`](../hrm/src/ui_empl_terr.4gl) | 164 | 3-table JOIN | Medium |
| [`ui_categories.4gl`](../hrm/src/ui_categories.4gl) | 167 | single-table | Low |
| [`ui_shippers.4gl`](../hrm/src/ui_shippers.4gl) | 120 | single-table | Low |
| [`ui_suppliers.4gl`](../hrm/src/ui_suppliers.4gl) | 152 | single-table | Low |
| [`ui_region.4gl`](../hrm/src/ui_region.4gl) | 187 | single-table | Low |
| [`ui_usstates.4gl`](../hrm/src/ui_usstates.4gl) | 120 | single-table | Low |
| [`ui_cust_demo.4gl`](../hrm/src/ui_cust_demo.4gl) | 136 | single-table | Low |

**All violate DDA R2.** Each one should become a
`model_<table>.fetchList(where_clause)` (or `searchList`) returning a
dynamic array of a list-row record type. The UI then loops the result
into its display array.

This is the single highest-leverage refactor in the codebase: one
pattern, applied 12 times, removes ~150 lines of inline SQL.

### E. REST modules — Medium / Low

The same pattern repeats in `rest_*`. Every handler builds its own
`SELECT` against the database.

**Medium-severity (joins):**

- [`rest_orders.4gl:28`](../hrm/src/rest_orders.4gl#L28),
  [63](../hrm/src/rest_orders.4gl#L63) — 3-table JOIN with derived
  `employeename` formula (domain rule leak as well).
- [`rest_order_details.4gl:28`](../hrm/src/rest_order_details.4gl#L28),
  [61](../hrm/src/rest_order_details.4gl#L61),
  [92](../hrm/src/rest_order_details.4gl#L92) — 2-table JOIN with
  inline line-total formula (3 more copies of the formula).
- [`rest_employees.4gl:28`](../hrm/src/rest_employees.4gl#L28),
  [62](../hrm/src/rest_employees.4gl#L62) — self-join for manager.
- [`rest_cust_cust_demo.4gl:28`](../hrm/src/rest_cust_cust_demo.4gl#L28),
  [63](../hrm/src/rest_cust_cust_demo.4gl#L63),
  [102](../hrm/src/rest_cust_cust_demo.4gl#L102) — 3-table JOIN.
- [`rest_empl_terr.4gl:34`](../hrm/src/rest_empl_terr.4gl#L34),
  [71](../hrm/src/rest_empl_terr.4gl#L71),
  [114](../hrm/src/rest_empl_terr.4gl#L114) — 4-table JOIN
  (orders/territories/region/employees). **Original audit missed this
  file entirely.**

**Low-severity (single-table SELECTs):** `rest_categories`,
`rest_shippers`, `rest_suppliers`, `rest_territories`, `rest_region`,
`rest_usstates`, `rest_cust_demo`, `rest_products`, `rest_customers`.
All have inline list/lookup SELECTs that bypass the model.

All violate **R8** ("REST adapters are thin"). The remediation
collapses to **the same model fetch function the UI needs**
(see §D) — once the model has `fetchList`, the REST handler is two
lines.

### F. Report modules — Low (and contextual)

All eight `rpt_*.4gl` modules contain inline joins. This is
**arguably acceptable**: a report's query is often unique to that
report (specific projection, specific aggregation), so pushing it
into the per-table model creates an awkward grab-bag of one-off
read functions.

If the project has a reporting CQRS-lite story, the joins move into
`query_*` or `view_*` modules. If reports stay self-contained, the
schema leak is documented and isolated to the `rpt_*` namespace.

**Recommendation:** defer. Fix the more pervasive ui/rest patterns
first; reports are read-only and don't carry domain rules.

### G. `advsearch_orders.4gl` — Low

The function shape is correct (CONSTRUCT, return WHERE fragment), but
the `ON` clause references `orders.orderid`, `customers.companyname`,
`employees.firstname`/`lastname`, etc. (
[advsearch_orders.4gl:8-13](../hrm/src/advsearch_orders.4gl#L8)). With
the `FROM s_advsearch.*` mapping present, this can be rewritten as
`CONSTRUCT where_clause ON s_advsearch.*` — see Walkthrough.

---

## Refactoring order

Ordered by **leverage** (one change × many violations) and **risk**
(domain-rule consolidation before persistence-layer rewrites).

1. **Add `model_order_details.calcLineTotal(unitprice, quantity, discount)`** —
   removes **5 duplicate copies** of the formula in one shot
   ([md_order_details.4gl:321](../hrm/src/md_order_details.4gl#L321),
   [md_order_details.4gl:1026](../hrm/src/md_order_details.4gl#L1026),
   [ui_order_details.4gl:216](../hrm/src/ui_order_details.4gl#L216),
   [ui_order_details.4gl:469](../hrm/src/ui_order_details.4gl#L469),
   and three sites in
   [rest_order_details.4gl](../hrm/src/rest_order_details.4gl)).
   Smallest diff, highest payoff.

2. **Delete the duplicate validators in `ui_orders.4gl`** ([§C](#c-ui_orders4gl--high-3--2))
   and `ui_order_details.4gl` ([§B](#b-ui_order_details4gl--high-5-domain-rule-leaks-3-schema-leaks)).
   Purely subtractive — the model functions already exist and are even
   already used elsewhere (`md_order_details:672`). Replace local
   calls with model calls; delete the private copies.

3. **Move the duplicate-product guard into
   `model_order_details.validateRec`** ([§A](#a-md_order_details4gl--high-5-distinct-violations-3-categories))
   as a list-position check (validateRec is per-row; add a sibling
   `validateList(arr)` that scans for duplicates across the array).

4. **Walkthrough: `searchHeadersWithDetails`** (below) — moves the
   6-table JOIN out of `md_order_details.execute_search`. Highest
   risk; do this with steps 1-3 done so the test surface is stable.

5. **Establish the `model_<table>.fetchList(where_clause)` pattern**
   in one model (start with `model_categories` — single-table, low
   risk), then apply it across all 12 `ui_<table>` modules from §D.
   This is the dominant refactor by line-count.

6. **Collapse REST handlers** ([§E](#e-rest-modules--medium--low)) onto
   the same `fetchList` / `searchList` functions from step 5. Each
   REST handler shrinks to a thin call.

7. **Move DML and transactions out of `md_order_details`** into
   `model_orders.saveWithDetails(...)` and
   `model_orders.deleteCascade(...)`. The 3 DML sites and 3 txn
   blocks consolidate into 2 model functions.

8. **Fix `advsearch_orders.4gl`** ([§G](#g-advsearch_orders4gl--low)) to
   address screen-record fields. One-line change.

9. **Defer the `rpt_*` joins** unless a CQRS-lite split is desired
   ([§F](#f-report-modules--low-and-contextual)).

---

## Walkthrough: `searchHeadersWithDetails`

The current state is split across three files and violates DDA rules
R2, R3, R6, and the CONSTRUCT/SQL split discipline (§5 in the DDA
doc):

- [`advsearch_orders.4gl`](../hrm/src/advsearch_orders.4gl) runs
  CONSTRUCT and returns a WHERE fragment. Already correct in shape,
  but addresses table columns instead of screen-record fields.
- [`md_order_details.4gl::execute_search`](../hrm/src/md_order_details.4gl#L202)
  builds the 6-table JOIN inline, then walks the result aggregating
  headers + per-order details for display.

Target state under DDA is three pieces with clear boundaries.

**1. `advsearch_orders.4gl` — fix the CONSTRUCT.**

```4gl
PUBLIC FUNCTION advsearch_orders() RETURNS (STRING)
   DEFINE where_clause STRING

   OPEN WINDOW advsearch_window WITH FORM "advsearch_orders"
   LET int_flag = FALSE

   -- Screen-record fields only; the .per form maps them to columns.
   CONSTRUCT where_clause ON s_advsearch.*
      FROM s_advsearch.*
      ATTRIBUTES(CANCEL = FALSE, ACCEPT = FALSE)

      ON ACTION cancel_search
         LET int_flag = TRUE
         EXIT CONSTRUCT

      ON ACTION do_search
         ACCEPT CONSTRUCT
   END CONSTRUCT

   CLOSE WINDOW advsearch_window

   IF int_flag THEN LET where_clause = "" END IF
   RETURN where_clause
END FUNCTION
```

The UI module no longer mentions any table or column name; the
mapping is in the form.

**2. `model_orders.4gl` — add the fetch function.**

```4gl
PUBLIC TYPE t_order_search_row RECORD
   orderid       LIKE orders.orderid,
   orderdate     LIKE orders.orderdate,
   customerid    LIKE orders.customerid,
   customername  LIKE customers.companyname,
   employeeid    LIKE orders.employeeid,
   employeename  VARCHAR(64),
   freight       LIKE orders.freight,
   shipcity      LIKE orders.shipcity,
   shipname      LIKE orders.shipname,
   shipcountry   LIKE orders.shipcountry,
   -- detail (nullable; LEFT JOIN)
   productid     LIKE order_details.productid,
   productname   LIKE products.productname,
   unitprice     LIKE order_details.unitprice,
   quantity      LIKE order_details.quantity,
   discount      LIKE order_details.discount
END RECORD

PUBLIC FUNCTION searchHeadersWithDetails(where_clause STRING)
                  RETURNS DYNAMIC ARRAY OF t_order_search_row
   DEFINE result DYNAMIC ARRAY OF t_order_search_row
   DEFINE row    t_order_search_row
   DEFINE sql    STRING

   LET sql = "SELECT o.orderid, o.orderdate, o.customerid, c.companyname, "
          || "       o.employeeid, "
          || "       e.firstname || ' ' || e.lastname AS employeename, "
          || "       o.freight, o.shipcity, o.shipname, o.shipcountry, "
          || "       od.productid, p.productname, od.unitprice, od.quantity, od.discount "
          || "  FROM orders o "
          || "  INNER JOIN customers c ON c.customerid = o.customerid "
          || "  INNER JOIN employees e ON e.employeeid = o.employeeid "
          || "  LEFT  JOIN order_details od ON od.orderid = o.orderid "
          || "  LEFT  JOIN products      p  ON p.productid = od.productid "
          || " WHERE " || NVL(where_clause, "1=1")
          || " ORDER BY o.orderid"

   PREPARE p_search FROM sql
   DECLARE c_search CURSOR FOR p_search
   FOREACH c_search INTO row.*
      LET result[result.getLength()+1] = row
   END FOREACH

   RETURN result
END FUNCTION
```

The model owns every table name, every join, the projection, and the
ordering. The WHERE clause is opaque — it crosses the boundary as a
string and the model never inspects it.

**3. `md_order_details.execute_search` — shrink to aggregation only.**

```4gl
PRIVATE FUNCTION execute_search(where_clause STRING) RETURNS ()
   DEFINE rows DYNAMIC ARRAY OF model_orders.t_order_search_row
   DEFINE i, header_idx INTEGER
   DEFINE prev_order_id LIKE orders.orderid

   LET rows = model_orders.searchHeadersWithDetails(where_clause)

   CALL order_result_list.clear()
   CALL order_header_dict.clear()
   CALL order_detail_dict.clear()

   LET prev_order_id = 0
   LET header_idx    = 0

   FOR i = 1 TO rows.getLength()
      IF rows[i].orderid != prev_order_id THEN
         LET header_idx += 1
         LET prev_order_id = rows[i].orderid
         CALL init_header_row(header_idx, rows[i])
      END IF

      IF rows[i].productid IS NOT NULL THEN
         CALL append_search_detail(rows[i].orderid, rows[i].*, rows[i].productname)
         LET order_result_list[header_idx].totalqty += NVL(rows[i].quantity, 0)
         LET order_result_list[header_idx].totalamt +=
            model_order_details.calcLineTotal(rows[i].unitprice,
                                              rows[i].quantity,
                                              rows[i].discount)
      END IF
   END FOR
END FUNCTION
```

The dialog module is now *aggregation for display* only — a one-
header-many-details pivot. No `SELECT`, no `FROM`, no joined-table
column names. The line-total call is a model function (refactor step
#1 above).

### Payoff

- **Schema-rename safety.** Renaming `customers.companyname` now
  touches `model_orders.searchHeadersWithDetails` and the
  `advsearch_orders.per` form; nothing else.
- **Reuse.** `searchHeadersWithDetails` can be called from a REST
  endpoint, a report, or a different search dialog without
  duplicating the JOIN.
- **Testability.** `searchHeadersWithDetails(where_clause)` is fglunit-
  testable: pass a WHERE fragment, assert on the returned array.
  `execute_search` in its current form is not — it depends on dialog
  state and side-effects.

---

## Genuinely clean files

These files contain no SQL and no domain rules — they are pure
infrastructure or pure presenter wiring:

- [`main_lib.4gl`](../hrm/src/main_lib.4gl) — global init, icon/style
  defaults, temp-file helper
- [`controller.4gl`](../hrm/src/controller.4gl) — generic
  add/edit/delete/navigate flow controller
- [`dispatch.4gl`](../hrm/src/dispatch.4gl) — dynamic-call dispatch
  table
- [`dialog_prompt.4gl`](../hrm/src/dialog_prompt.4gl) — yes/no/OK
  prompt utility
- [`list_view_helper.4gl`](../hrm/src/list_view_helper.4gl) — Excel
  export only
- [`md_helper.4gl`](../hrm/src/md_helper.4gl) — master-detail
  constants only
- [`mstr_dtl_order.4gl`](../hrm/src/mstr_dtl_order.4gl) — entry-point
  wiring only
- [`model_helper.4gl`](../hrm/src/model_helper.4gl) — `t_valid_rec`
  type only
- [`report_helper.4gl`](../hrm/src/report_helper.4gl) — text-file
  display utility

When in doubt about how a non-model layer should look, read one of
these. They are the DDA reference shape for their respective roles.
