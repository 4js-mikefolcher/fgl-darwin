# Cleanup Plan — Northwind Demo (Genero BDL)

Branch: `genero/step2/refactor`. Scope: duplicate code and dead code in `.4gl` sources under `hrm/src/`, `ggc-test/`, and `dbs/`. Forms (`.per`), styles (`.4st`), and `bin/` artifacts are out of scope unless called out.

## 1. Summary

The codebase (~24K LOC across ~103 `.4gl` files, ignoring `bin/`) is in good shape architecturally. The generic `controller` + `dispatch` + `list_view_helper` already extract the bulk of CRUD navigation, and the master/detail module ([md_order_details.4gl](hrm/src/md_order_details.4gl)) has its own queued refactor in [MD_REFACTOR_PLAN.md](MD_REFACTOR_PLAN.md). The biggest remaining duplication lives in the 12 entity `ui_*.4gl` files: identical `_load_at`, `_display_curr`, `_clear_curr`, `_get_count`, `_do_refresh`, `_do_add_edit`, `_do_delete`, `_list_display`, `_*_lookup`, `_*_lookup_menu` blocks (~1500-2000 lines that could be parameterized via dispatch). The four `rpt_orders_by_*.4gl` reports share an identical CONSTRUCT/run/execute/REPORT skeleton (~60 lines per report × 4 = ~240 lines collapsible). The 14 `test_rest_*.4gl` files duplicate test scaffolding (~140 test functions, ~10 per entity, all DB-roundtrip-then-cleanup). Dead code is modest but concrete: ~12 dead lookup/view functions, `confirm_delete` duplicated by `dialog_prompt.delete_prompt`, a few orphan helper functions, and one `DISPLAY "Hello World"` debug print. The highest-value, lowest-risk wins are: (1) delete the dead `*_lookup` / `view_*` functions; (2) consolidate `populate_shipvia_combo` + `load_shipvia_combo`; (3) delete `arr_max`/`get_arr_max`; (4) remove `confirm_delete` and migrate the 13 callers to `dialog_prompt.delete_prompt`. The MD_REFACTOR_PLAN items remain the right priority for `md_order_details.4gl` itself.

---

## 2. Dead-Code Findings

### 2.1 Dead lookup function pairs (never called from any module)

| Function | Location | Evidence |
|---|---|---|
| `category_lookup`, `category_lookup_menu` | [ui_categories.4gl:346,366](hrm/src/ui_categories.4gl#L346) | `grep "category_lookup"` shows definitions only; the only call site is `category_lookup` → `category_lookup_menu` internally. No external module imports / calls either. |
| `shipper_lookup`, `shipper_lookup_menu` | [ui_shippers.4gl:324,344](hrm/src/ui_shippers.4gl#L324) | Same — only the internal pair call. No caller. |
| `supplier_lookup`, `supplier_lookup_menu` | [ui_suppliers.4gl:313,329](hrm/src/ui_suppliers.4gl#L313) | Same. No caller. |
| `region_lookup`, `region_lookup_menu` | [ui_region.4gl:365,385](hrm/src/ui_region.4gl#L365) | Same. No caller. |

Confidence: **high** — these are stand-alone `OPEN WINDOW`/`MENU` lookups; dispatch routes don't pass through them and the controller doesn't use them. `customer_lookup`, `employee_lookup`, `order_lookup`, `product_lookup`, `cust_demo_lookup` are still in use; only the four above are dead.

Suggested action: **delete** both functions in each module.

### 2.2 Dead `view_<entity>` standalone-window functions

| Function | Location | Evidence |
|---|---|---|
| `view_employee(empl_id)` | [ui_employees.4gl:85](hrm/src/ui_employees.4gl#L85) | No `CALL view_employee(` anywhere in the tree. |
| `view_customer(cust_id)` | [ui_customers.4gl:91](hrm/src/ui_customers.4gl#L91) | No `CALL view_customer(` anywhere. |
| `view_order(order_id)` | [ui_orders.4gl:86](hrm/src/ui_orders.4gl#L86) | No `CALL view_order(` anywhere (note: `view_orders_for_customer` / `view_orders_for_employee` ARE still used). |
| `view_shipper(ship_id)` | [ui_shippers.4gl:33](hrm/src/ui_shippers.4gl#L33) | No caller. |
| `view_cust_demo(type_id)` | [ui_cust_demo.4gl:48](hrm/src/ui_cust_demo.4gl#L48) | No caller. |
| `view_territory(terr_id)` | [ui_territories.4gl:76](hrm/src/ui_territories.4gl#L76) | No caller. `view_territories_for_region` is still used. |
| `view_product(prod_id)` | [ui_products.4gl:55](hrm/src/ui_products.4gl#L55) | No caller. `view_products_for_category` is still used. |
| `view_products_for_supplier(supp_id)` | [ui_products.4gl:89](hrm/src/ui_products.4gl#L89) | No caller; `view_products_for_category` IS used. |

Confidence: **high** for all. Quick verification: `grep -rn "CALL view_<name>(" hrm/src/`.

Suggested action: **delete**. These were entry points predating the generic controller; refactoring to `controller_navigate_view` apparently retired them but the function bodies were left behind.

### 2.3 Unused utility functions / module variables

| Item | Location | Evidence | Confidence |
|---|---|---|---|
| `get_arr_max()` | [main_lib.4gl:33](hrm/src/main_lib.4gl#L33) | Defined once, no callers in any `.4gl`. | high |
| Module variable `arr_max` (and its `LET arr_max = 1000` in `init_pgm`) | [main_lib.4gl:5,20](hrm/src/main_lib.4gl#L5) | Only used inside `get_arr_max()` itself, which is dead. | high |
| `check_server(url STRING)` | [test_rest_lib.4gl:137](hrm/src/test_rest_lib.4gl#L137) | No `test_rest_*.4gl` calls it; the suite simply lets HTTP errors fail individual tests. | high |
| `confirm_delete()` | [main_lib.4gl:74](hrm/src/main_lib.4gl#L74) | Still has 13 callers in `ui_*.4gl`, but it duplicates `dialog_prompt.delete_prompt()` exactly. Mark as **redundant**, not dead. | high (as duplicate) |

Suggested action: delete `get_arr_max`+`arr_max`, delete `check_server`. For `confirm_delete` see Duplicate-Code section.

### 2.4 Debug leftovers

| Item | Location | Evidence |
|---|---|---|
| `DISPLAY "Hello World"` | [rest_categories.4gl:26](hrm/src/rest_categories.4gl#L26) | In the body of `getAll()`. Pollutes server logs every time the categories REST endpoint is hit. |
| `DISPLAY SFMT("Employee ID (%1) and Level (%2)", emp_id, level)` | [rpt_org_chart.4gl:104](hrm/src/rpt_org_chart.4gl#L104) | Debug print inside `build_org_tree` — fires once per employee on every report run. |

Confidence: **high** — pure scaffolding.

Suggested action: **delete** both lines.

### 2.5 Visibility / naming inconsistencies (not dead, but worth a one-line edit)

| Item | Location | Notes |
|---|---|---|
| `FUNCTION (self t_category) updateRec()` missing `PUBLIC` keyword | [model_categories.4gl:58](hrm/src/model_categories.4gl#L58) | Other `updateRec` methods in sibling models are `PUBLIC`. Functionally still callable via method syntax but inconsistent. Confidence: high. |
| Duplicate `IMPORT FGL model_helper` | [ui_cust_cust_demo.4gl:2,8](hrm/src/ui_cust_cust_demo.4gl#L2) | Same module imported twice. Confidence: high. |

Suggested action: add `PUBLIC`; delete the second import.

### 2.6 Dispatch table includes `cmd_employee` action that no caller emits

In [controller.4gl](hrm/src/controller.4gl)'s `controller_navigate`, line 94 defines an `ON ACTION cmd_employees` and lines 181-184 set `setActionHidden("cmd_employees", ...)`. The only `init_view_commands()` that publishes `commandName="employees"` is [ui_territories.4gl:44](hrm/src/ui_territories.4gl#L44) — so `cmd_employees` IS reachable. **Keep.** Documented here only to confirm the check was done.

By contrast `cmd_employee` (singular, line 169) is never emitted by any `init_view_commands()` array — no `commandName="employee"` exists. Confidence: medium (could be triggered by a future module). Suggested action: **verify with user** — likely safe to remove the `cmd_employee` action line and its `setActionHidden` line.

---

## 3. Duplicate-Code Findings

### 3.1 `confirm_delete` vs `delete_prompt` — exact-logic duplicate

- [main_lib.4gl:74-85](hrm/src/main_lib.4gl#L74) — `FUNCTION confirm_delete()` returns BOOLEAN, uses `MENU "Confirm Deletion"`.
- [dialog_prompt.4gl:1-15](hrm/src/dialog_prompt.4gl#L1) — `PUBLIC FUNCTION delete_prompt() RETURNS BOOLEAN`, uses `MENU "Delete Confirmation"`.

Both produce an identical `MENU ... STYLE="dialog"` Yes/No prompt. [md_order_details.4gl:552](hrm/src/md_order_details.4gl#L552) and [md_order_details.4gl:606](hrm/src/md_order_details.4gl#L606) already use `dialog_prompt.delete_prompt()`. The 13 remaining callers all use `confirm_delete()`:

- [ui_categories.4gl:245](hrm/src/ui_categories.4gl#L245)
- [ui_cust_cust_demo.4gl:328](hrm/src/ui_cust_cust_demo.4gl#L328)
- [ui_cust_demo.4gl:246](hrm/src/ui_cust_demo.4gl#L246)
- [ui_customers.4gl:283](hrm/src/ui_customers.4gl#L283)
- [ui_empl_terr.4gl:300](hrm/src/ui_empl_terr.4gl#L300)
- [ui_employees.4gl:294](hrm/src/ui_employees.4gl#L294)
- [ui_order_details.4gl:348](hrm/src/ui_order_details.4gl#L348)
- [ui_orders.4gl:412](hrm/src/ui_orders.4gl#L412)
- [ui_products.4gl:340](hrm/src/ui_products.4gl#L340)
- [ui_region.4gl:261](hrm/src/ui_region.4gl#L261)
- [ui_shippers.4gl:228](hrm/src/ui_shippers.4gl#L228)
- [ui_suppliers.4gl:226](hrm/src/ui_suppliers.4gl#L226)
- [ui_territories.4gl:343](hrm/src/ui_territories.4gl#L343)
- [ui_usstates.4gl:201](hrm/src/ui_usstates.4gl#L201)

Consolidation: keep `delete_prompt` in `dialog_prompt.4gl`, replace `confirm_delete` callers with `dialog_prompt.delete_prompt`, delete `confirm_delete` from `main_lib.4gl`. Each `ui_*` needs `IMPORT FGL dialog_prompt`.

Lines saved: ~12 (delete `confirm_delete` body); plus visual de-duplication.
Confidence: high.

### 3.2 `populate_shipvia_combo` vs `load_shipvia_combo` — duplicate combobox loader

- [ui_orders.4gl:702-718](hrm/src/ui_orders.4gl#L702) — `FUNCTION populate_shipvia_combo()` looks up `ui.ComboBox.forName("shipvia")` then SELECTs from `shippers` and populates.
- [md_order_details.4gl:1070-1081](hrm/src/md_order_details.4gl#L1070) — `PUBLIC FUNCTION load_shipvia_combo(cbx ui.ComboBox)` takes the combobox as a parameter; same SELECT, same `cbx.addItem`.

`load_shipvia_combo` is used as a form INITIALIZER ([md_order_details.per:79](hrm/src/md_order_details.per#L79)). `populate_shipvia_combo` is called 6× directly in `ui_orders.4gl` and 1× in `main_orders.4gl`.

Consolidation: keep one in `model_shippers.4gl` (closer to the data, already in scope of all users):

```
PUBLIC FUNCTION load_shipvia_combo(cbx ui.ComboBox) RETURNS ()
```

Then `populate_shipvia_combo()` can be a 3-line wrapper that does `ui.ComboBox.forName("shipvia")` and delegates, OR all call sites can be migrated to call `model_shippers.load_shipvia_combo(ui.ComboBox.forName("shipvia"))`. The form INITIALIZER signature `load_shipvia_combo(cbx ui.ComboBox)` is already the right shape for direct use.

Lines saved: ~12 (delete one body, optionally a thin wrapper).
Confidence: high.

### 3.3 `default_shipping_from_customer` — model method vs `ui_orders` private function

- [model_orders.4gl:162-184](hrm/src/model_orders.4gl#L162) — `PUBLIC FUNCTION (self t_order) default_shipping_from_customer()` — method on `t_order`, uses `self.customerid`. Called from md_order_details.
- [ui_orders.4gl:624-646](hrm/src/ui_orders.4gl#L624) — `PRIVATE FUNCTION default_shipping_from_customer(cust_id LIKE customers.customerid)` — takes parameter, mutates module-level `curr_orders`. Called 2× inside `ui_orders.4gl`.

Same SELECT, same field assignments. Consolidation: have the `ui_orders.4gl` callers call `curr_orders.default_shipping_from_customer()` (the model method already exists). Delete the private duplicate.

Lines saved: ~22. Confidence: high.

### 3.4 `validate_customer_field` / `validate_employee_field` / `validate_shipvia_field` (ui_orders) ≈ `validate_customer` / `validate_employee` / `validate_shipvia` (models)

- [ui_orders.4gl:651,669,686](hrm/src/ui_orders.4gl#L651) — three private functions
- [model_customers.4gl:128](hrm/src/model_customers.4gl#L128), [model_employees.4gl:170](hrm/src/model_employees.4gl#L170), [model_shippers.4gl:107](hrm/src/model_shippers.4gl#L107) — three public functions returning `t_valid_rec`

The ui_orders versions return `(BOOLEAN, STRING)`; the model versions return `t_valid_rec`. Logic is the same lookup. Consolidation: have the ui_orders functions call the model functions and re-package the result, OR replace ui_orders call sites with direct model calls (using `t_valid_rec`). The `md_order_details.4gl` `header_input` already uses the model functions; ui_orders just doesn't.

Lines saved: ~40. Confidence: medium (callers in `ui_orders.4gl` expect the tuple return — needs caller updates).

### 3.5 Excel-export wrappers — three near-identical copies

- [ui_orders.4gl:505-518](hrm/src/ui_orders.4gl#L505) — `export_orders_to_excel(list_arr DYNAMIC ARRAY OF t_order_list)` — wraps `tableExcelExport("orders_list", jsonData)`.
- [ui_order_details.4gl:447](hrm/src/ui_order_details.4gl#L447) — direct call to `tableExcelExport("order_details_list", ...)` (no wrapper).
- [ui_products.4gl:430](hrm/src/ui_products.4gl#L430) — direct call to `tableExcelExport("products_list", ...)`.
- [md_order_details.4gl:1097-1110](hrm/src/md_order_details.4gl#L1097) — `export_orders_to_excel()` for the result list — same wrapping pattern.

All four blocks compose `util.JSONArray.fromFGL(arr)` + `tableExcelExport(name, jsonData)` + `fgl_putfile`/error path. Pull into a helper:

```
-- In a new section of list_view_helper.4gl (or main_lib.4gl)
PUBLIC FUNCTION export_array_to_excel(screen_record STRING, jsonData util.JSONArray) RETURNS ()
   VAR excelFile = tableExcelExport(screen_record, jsonData)
   IF excelFile IS NOT NULL AND excelFile.getLength() > 0 THEN
      CALL fgl_putfile(excelFile, os.Path.baseName(excelFile))
   ELSE
      ERROR "Excel export failed."
   END IF
END FUNCTION
```

Callers pass `("orders_list", util.JSONArray.fromFGL(orders_arr))`, etc.

Lines saved: ~25. Confidence: high.

### 3.6 The 12 entity `ui_*.4gl` modules — structural megaduplication

The dispatch interface forces each entity to implement: `*_get_count`, `*_load_at`, `*_display_curr`, `*_clear_curr`, `*_do_query`, `*_do_load` (private), `*_do_add_edit`, `*_do_delete`, `*_do_refresh`, `*_list_display`, `*_do_command`. Most are 5-line bodies that vary only by entity name and field list. Representative samples:

- `_load_at`: [ui_employees.4gl:136-144](hrm/src/ui_employees.4gl#L136), [ui_customers.4gl:131-139](hrm/src/ui_customers.4gl#L131), [ui_shippers.4gl:93-98](hrm/src/ui_shippers.4gl#L93) — identical except array/record name.
- `_display_curr`: [ui_employees.4gl:149-153](hrm/src/ui_employees.4gl#L149), [ui_customers.4gl:144-148](hrm/src/ui_customers.4gl#L144), [ui_shippers.4gl:101-103](hrm/src/ui_shippers.4gl#L101) — all `DISPLAY BY NAME <curr>.*`.
- `_clear_curr`: identical pattern `INITIALIZE <curr>.* TO NULL`.
- `_get_count`: identical `RETURN <arr>.getLength()`.
- `_do_refresh`: identical 3-branch CASE on operation (`"A"`/`"C"`/`"D"`), see [ui_employees.4gl:313-333](hrm/src/ui_employees.4gl#L313) vs [ui_customers.4gl:302-322](hrm/src/ui_customers.4gl#L302) vs [ui_shippers.4gl:249-267](hrm/src/ui_shippers.4gl#L249).
- `_do_add_edit`: same INPUT BY NAME + validateRec + insertRec/updateRec skeleton, e.g. [ui_employees.4gl:236-286](hrm/src/ui_employees.4gl#L236) vs [ui_customers.4gl:224-275](hrm/src/ui_customers.4gl#L224) vs [ui_shippers.4gl:170-219](hrm/src/ui_shippers.4gl#L170) vs [ui_suppliers.4gl:171-220](hrm/src/ui_suppliers.4gl#L171). Only differences are the entity name in error messages and the optional `populate_*_combo` call before INPUT.
- `_do_delete`: same shape `confirm_delete` → `deleteRec` → MESSAGE/ERROR — [ui_employees.4gl:291-308](hrm/src/ui_employees.4gl#L291), 12 near-clones.
- `_list_display`: same DISPLAY ARRAY skeleton (ADD/MODIFY/DELETE/ACCEPT/EXIT action handlers setting `selectedOption` from `list_view_helper` constants), [ui_employees.4gl:338-379](hrm/src/ui_employees.4gl#L338), 12 near-clones.
- `*_lookup_menu` (where present): identical First/Previous/Next/Last/Select/Exit MENU, [ui_employees.4gl:425-489](hrm/src/ui_employees.4gl#L425) vs [ui_customers.4gl:412-476](hrm/src/ui_customers.4gl#L412) vs [ui_shippers.4gl:344-399](hrm/src/ui_shippers.4gl#L344).

**Consolidation target**: most of these CAN'T be made truly generic because Genero lacks generics over RECORD types. But the trivial 1- to 5-line wrappers (`_get_count`, `_load_at`, `_display_curr`, `_clear_curr`) are pure ceremony — they exist only so `dispatch.4gl` can route to them. Two options:

**Option A (conservative, recommended)**: leave the trivial wrappers (they're cheap, and they document the dispatch contract). Focus consolidation on the bodies that have actual content:
- Move the `_do_refresh` CASE pattern into a `list_view_helper.refresh_array(...)` helper that takes a callback name — but Genero has no first-class functions, so this doesn't work cleanly. **Leave as-is** unless willing to invent a JSON-bridging convention.
- Move the `_list_display` DISPLAY ARRAY action skeleton into `list_view_helper`. Same problem — the array type is entity-specific. **Leave as-is**.

**Option B (aggressive, more work, more risk)**: re-architect so the controller takes a `DICTIONARY OF util.JSONObject` keyed by primary key, with all entity-specific code reduced to: model, SELECT statement, and a small `populate(json, rec)` shim. Roughly the same pattern `md_order_details.4gl` already proves with `toOrderDetail()`/`fromOrderDetail()`. **Out of scope** for a cleanup pass — this would be a redesign.

**Realistic suggestion**: skip 3.6 as a refactor target. The duplication is structural, the existing template is readable, and Genero's lack of generics makes the cost of abstraction high.

Confidence: high (that the duplication exists); low (that consolidation is worth it).
Lines saved if attempted: ~1500-2000 across 12 files, but with significant complexity cost. **Not recommended**.

### 3.7 The four `rpt_orders_by_*.4gl` reports — duplicate skeletons

- [rpt_orders_by_customer.4gl](hrm/src/rpt_orders_by_customer.4gl)
- [rpt_orders_by_employee.4gl](hrm/src/rpt_orders_by_employee.4gl)
- [rpt_orders_by_product.4gl](hrm/src/rpt_orders_by_product.4gl)
- [rpt_orders_by_daterange.4gl](hrm/src/rpt_orders_by_daterange.4gl)

Each has:
1. `run_<x>()` function with `OPEN WINDOW` + `WHILE NOT done` + `CONSTRUCT BY NAME where_clause ON <fields>` with identical `ON ACTION run/cancel/exit` blocks ([rpt_orders_by_customer.4gl:28-71](hrm/src/rpt_orders_by_customer.4gl#L28) ≈ [rpt_orders_by_employee.4gl:30-73](hrm/src/rpt_orders_by_employee.4gl#L30)).
2. `execute_<x>_report(where_clause)` with `generate_temp_filename`, `PREPARE`, `DECLARE CURSOR`, `START REPORT TO FILE`, `FOREACH` loop, `FINISH REPORT`, then `display_report_file` — identical except for SQL and target type.
3. `REPORT <x>(r)` with `FIRST PAGE HEADER` / `PAGE HEADER` / `ON EVERY ROW` / `AFTER GROUP` — fields differ but layout (columns, separators, grand total) is templated.

The CONSTRUCT/WHILE/run-or-exit shell (~25 lines, repeated 4×) is the cleanest extract — but Genero doesn't have first-class functions, so a direct extraction isn't possible. **Practical option**: leave the shells, just deduplicate `generate_temp_filename` calling convention and `display_report_file` invocation pattern (already shared via `report_helper`). Note: `rpt_orders_generic.4gl`, `rpt_org_chart.4gl`, `rpt_products_by_category.4gl`, and `rpt_employees_with_totals.4gl` follow the same pattern — so 7 files share the skeleton.

Confidence: high (duplication is real); low (cost to abstract).
Lines saved if attempted: ~150. **Not recommended unless willing to use code generation.**

### 3.8 The 14 `test_rest_*.4gl` files — duplicate test scaffolding

Each test file follows: MAIN with sequential `CALL test_get_all() / test_get_by_id() / test_create_*() / test_update_*() / test_delete_*() / ...` then exit-with-failure-count. Each test function repeats: HTTP call → status check → JSON parse → field assertions → DB validation (SELECT) → cleanup (DELETE).

- ~10 test functions per file × 14 files = ~141 functions
- Each `test_create_*` is ~50 lines that vary only by: URL slug, record type, expected field name, validation SQL.
- The "DB validation after POST/PUT" idiom — `SELECT … INTO db_<field> FROM <table> WHERE <pk>=<id>` then compare — is repeated 50+ times across the suite.

Helpers worth adding (in `test_rest_lib.4gl`):

- `assert_status(actual INTEGER, expected INTEGER, label STRING) RETURNS BOOLEAN` (logs FAIL + returns FALSE).
- `parse_or_fail(json STRING, target ARG-RECORD)` — wraps `util.JSON.parse` in TRY/CATCH and records FAIL.
- `cleanup_delete(url STRING)` — wraps `http_delete` with no-op on failure.

These would cut each test by ~5 lines (status check + JSON parse boilerplate) — but they don't eliminate the entity-specific SQL/field assertions. Lines saved across the suite: ~500-700.

Confidence: high (duplication is real).
Risk: low — these are tests, churn is acceptable.

Suggested action: add the three helpers to `test_rest_lib.4gl`, migrate the existing `test_rest_*.4gl` modules opportunistically (one entity per PR). Out of scope for a pure cleanup pass but flag as the highest-payoff next step after the dead-code deletions.

### 3.9 `main_*.4gl` shim modules — 5-line clones (~14 files)

[main_employees.4gl](hrm/src/main_employees.4gl), [main_orders.4gl](hrm/src/main_orders.4gl), [main_customers.4gl](hrm/src/main_customers.4gl), etc. — each is 15-25 lines of `OPEN WINDOW` + `MENU` with Query/Add/Exit, calling `submenu_<x>()` and `root_add_<x>()`. Very similar but each is the entry point for its own `.42r`, so they're intentionally separate. No consolidation target.

`main_rpt_orders_by_*.4gl` — each is exactly 10 lines, calling a single `run_<x>()`. Already maximally trivial.

Confidence: high. Suggested action: **leave**. These are the build artifacts.

---

## 4. Already Covered by MD_REFACTOR_PLAN.md

These items intersect with the existing plan; do not duplicate-track:

- **`calcPrice()` ↔ `calc_line_total()` consolidation** — covered by [MD_REFACTOR_PLAN.md](MD_REFACTOR_PLAN.md) item #2. Both functions live in `md_order_details.4gl` and compute the same line-total formula.
- **Header→result-list field-copy duplication** between `sync_current_recs` and `execute_search` — covered by MD_REFACTOR_PLAN item #3.
- **Header dict population verbosity** — covered by MD_REFACTOR_PLAN item #4.
- **`update_detail_recs` + `set_current_recs` always called as a pair** — covered by MD_REFACTOR_PLAN item #5.
- **`details_input` ↔ `detail_single_input` duplicate field handlers** — covered by MD_REFACTOR_PLAN item #1.

---

## 5. Recommended Sequencing

### Phase 1 — Dead-code deletions (quick wins, near-zero risk)

1. Delete `DISPLAY "Hello World"` in [rest_categories.4gl:26](hrm/src/rest_categories.4gl#L26).
2. Delete `DISPLAY SFMT("Employee ID ...")` in [rpt_org_chart.4gl:104](hrm/src/rpt_org_chart.4gl#L104).
3. Delete `get_arr_max()` and `DEFINE arr_max INTEGER` + `LET arr_max = 1000` in [main_lib.4gl](hrm/src/main_lib.4gl).
4. Delete `check_server()` in [test_rest_lib.4gl:137](hrm/src/test_rest_lib.4gl#L137).
5. Delete dead `view_*` functions: `view_employee`, `view_customer`, `view_order`, `view_shipper`, `view_cust_demo`, `view_territory`, `view_product`, `view_products_for_supplier`.
6. Delete dead lookup function pairs: `category_lookup`/`category_lookup_menu`, `shipper_lookup`/`shipper_lookup_menu`, `supplier_lookup`/`supplier_lookup_menu`, `region_lookup`/`region_lookup_menu`.
7. Remove duplicate `IMPORT FGL model_helper` in [ui_cust_cust_demo.4gl:8](hrm/src/ui_cust_cust_demo.4gl#L8).
8. Add `PUBLIC` to `updateRec` in [model_categories.4gl:58](hrm/src/model_categories.4gl#L58).

Estimated effort: 1-2 hours. Recompile + run `make ggc-test` to validate.

### Phase 2 — Targeted duplicate-code consolidations (medium risk)

9. Consolidate `confirm_delete` into `dialog_prompt.delete_prompt`. Add `IMPORT FGL dialog_prompt` to each of the 13 ui_* files; replace `confirm_delete()` with `dialog_prompt.delete_prompt()`; delete `confirm_delete` from `main_lib.4gl`.
10. Consolidate `populate_shipvia_combo` and `load_shipvia_combo`. Move to `model_shippers.4gl` (where `shippers` is the natural scope). Update form INITIALIZER and 7 call sites.
11. Delete the private `default_shipping_from_customer(cust_id)` in `ui_orders.4gl`; switch its 2 callers to `curr_orders.default_shipping_from_customer()` (the model method).
12. Add `export_array_to_excel(screen_record, jsonData)` helper to `list_view_helper.4gl`; migrate 3-4 callers.

Estimated effort: 3-4 hours. Validate with `make ggc-test` and a manual sweep of `main_orders` + `mstr_dtl_order`.

### Phase 3 — MD_REFACTOR_PLAN execution (already queued)

13. Work through MD_REFACTOR_PLAN items #1-#5 in the order specified there (`calcPrice` → field handlers → fold-set_current → populate-from-header → JSON populate_header_dict).

### Phase 4 — Optional: test_rest_lib helpers (medium risk, high payoff in tests)

14. Add `assert_status`, `parse_or_fail`, `cleanup_delete` helpers to `test_rest_lib.4gl`. Migrate one `test_rest_*.4gl` as a proof, then opportunistically.

### Phase 5 — Skipped (not recommended)

- Item 3.6 (entity ui_* megaduplication) — defer; benefit/cost ratio is poor.
- Item 3.7 (rpt_orders_by_* skeletons) — defer; same.
- Item 3.9 (main_* shims) — not actionable.

### Risky / verify first

- `cmd_employee` (singular) action in `controller.4gl` — confirm no future caller wants it; safe to remove only after user verification.
- The `ifx_menu.4gl` text-based menu is independent of `bdl_menu.4gl`. It's still built. Confirm with user whether it's still needed; if not, it can be removed from the Makefile (~290 lines saved).

---

## 6. Out of Scope / Notes

- **Forms (`.per`) duplication** — not audited in depth. The `*_list.per` files likely have layout duplication (search panel + result grid + action buttons). Suggest a separate pass.
- **Schema concerns** — [dbs/northwind_pgs_84x.4gl](dbs/northwind_pgs_84x.4gl) is a standalone DB-init script (3592 lines). Not audited.
- **`ifx_menu.4gl`** — a text-mode launcher that parallels `bdl_menu.4gl`. Still in the Makefile. If only `bdl_menu` is used in practice, removing `ifx_menu` saves ~290 lines and one `.42r`. Verify with user.
- **`main_rest_server.4gl`** — REST entry point importing all 14 `rest_*.4gl`. Compiled by the Makefile but no test integration; the `test_rest_*.4gl` files all hit `http://localhost:8899/...`. Confirm it's still intended to be deployable.
- **`load_employees_ext` / `get_employees_count`** ([ui_employees.4gl:537,560](hrm/src/ui_employees.4gl#L537)) — both used by `ui_territories.4gl`. Not dead. But the pair is awkward — `load_employees_ext(where_clause)` + caller-checks-`get_employees_count()` could be one function that returns the count.
- **Module-level `m_define_null_cursor` / `m_define_empl_cursor` flags** in [rpt_org_chart.4gl:90-91](hrm/src/rpt_org_chart.4gl#L90) — a manual "DECLARE-only-once" pattern inside the recursive `build_org_tree`. Correct, just worth noting; not a bug.
- **No `view_usstates` or `usstates_lookup` exists** — `ui_usstates.4gl` is the cleanest of the entity modules. Good template.
- **Genero patterns NOT covered** — the audit excluded `.4ad` action defaults, `.4st` styles, `.4tb` toolbars, and the `*.42d` schema dump. No obvious duplication noticed in passing.

---

## Critical Files for Implementation

- [hrm/src/main_lib.4gl](hrm/src/main_lib.4gl) — delete `confirm_delete`, `get_arr_max`, `arr_max`.
- [hrm/src/dialog_prompt.4gl](hrm/src/dialog_prompt.4gl) — already correct; the canonical home for delete confirmation.
- [hrm/src/ui_orders.4gl](hrm/src/ui_orders.4gl) — consolidate `populate_shipvia_combo`, delete `default_shipping_from_customer` private, delete `view_order`.
- [hrm/src/md_order_details.4gl](hrm/src/md_order_details.4gl) — host of `load_shipvia_combo` (to be moved); also primary target of MD_REFACTOR_PLAN.
- [hrm/src/list_view_helper.4gl](hrm/src/list_view_helper.4gl) — natural home for `export_array_to_excel` helper.
