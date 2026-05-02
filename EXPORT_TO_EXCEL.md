# Export-to-Excel Rollout Plan

## Context

`md_order_details.4gl` already exports its two display arrays to Excel via
the `com.fourjs.poiapi.fgl_table_export` package (installed at
[.fglpkg/poiapi/com/fourjs/poiapi/](.fglpkg/poiapi/com/fourjs/poiapi/);
source at `~/4js-github/poiapi`). The goal is to extend the same capability
to every other module that has a `DISPLAY ARRAY`.

Each module needs three things:

1. An `excel_export` action on the `DISPLAY ARRAY`.
2. `AGGREGATE` COUNT / SUM rows on the matching form so numeric columns
   surface totals in the UI *and* in the exported Excel file (the POI
   helper emits native Excel `SUM(…)` / `COUNTA(…)` formulas from the
   form metadata).
3. An `excel_export` toolbar item so the action is reachable from the
   toolbar.

Because the POI helper is metadata-driven (it reads titles, types,
formats, and AGGREGATE definitions straight from the AUI tree), the
per-module code change is minimal — most of the rollout is in the forms
and in two shared toolbars.

## Reference implementation (already shipped)

From [hrm/src/md_order_details.4gl](hrm/src/md_order_details.4gl):

- **Imports** (lines 1-17):
  ```
  IMPORT util
  IMPORT os
  IMPORT FGL com.fourjs.poiapi.fgl_table_export
  ```
- **Action wiring** ([md_order_details.4gl:116-118](hrm/src/md_order_details.4gl#L116-L118)):
  Inside `DIALOG ATTRIBUTES(UNBUFFERED)`:
  ```
  ON ACTION excel_export
     LET selected_option = cExport
     ACCEPT DIALOG
  ```
  Dispatched in `AFTER DIALOG` CASE → `CALL export_orders_to_excel()`.
- **Export function** ([md_order_details.4gl:1090-1103](hrm/src/md_order_details.4gl#L1090-L1103)):
  ```
  PRIVATE FUNCTION export_orders_to_excel() RETURNS ()
     DEFINE jsonData util.JSONArray
     DEFINE excelFile STRING
     LET jsonData = util.JSONArray.fromFGL(order_result_list)
     LET excelFile = tableExcelExport("s_table", jsonData)
     IF excelFile IS NOT NULL AND excelFile.getLength() > 0 THEN
        CALL fgl_putfile(excelFile, os.Path.baseName(excelFile))
     ELSE
        ERROR "Excel export failed."
     END IF
  END FUNCTION
  ```
- **Action default** already present in
  [hrm/src/generic.4ad](hrm/src/generic.4ad) lines 43-46
  (text `"Export to Excel"`, icon `fa-file-excel-o`). No change needed.
- **Toolbar** [hrm/src/search_list.4tb](hrm/src/search_list.4tb) already
  contains `<ToolBarItem name="excel_export"/>`.
- **Form aggregates**
  [mstr_order_list.per:63-65](hrm/src/mstr_order_list.per#L63-L65):
  ```
  AGGREGATE tot001 = FORMONLY.rec_count,     AGGREGATETEXT = "Count:", AGGREGATETYPE = COUNT;
  AGGREGATE tot005 = FORMONLY.freight_total, AGGREGATETEXT = "Total:", AGGREGATETYPE = SUM;
  AGGREGATE tot010 = FORMONLY.amt_total,     AGGREGATETEXT = "Total:", AGGREGATETYPE = SUM;
  ```
  Runtime computes `COUNT` / `SUM` automatically — no `.4gl` code needed
  unless `AGGREGATETYPE=PROGRAM`.

## Scope

### Shared toolbars (2 files)

| File | Change | Affects |
|---|---|---|
| [hrm/src/list_standard.4tb](hrm/src/list_standard.4tb) | Add `<ToolBarItem name="excel_export"/>` before the `exit` separator | 12 list modules |
| [hrm/src/list_lookup.4tb](hrm/src/list_lookup.4tb)     | Add `<ToolBarItem name="excel_export"/>` before the `exit` separator | 2 lookup modules |

[hrm/src/search_list.4tb](hrm/src/search_list.4tb) already has the item.
[hrm/src/master_detail.4tb](hrm/src/master_detail.4tb) is for detail-edit
forms (no display array) and does not need the item.

### UI modules (14 `.4gl` + 14 `.per`)

The 14 standalone list modules under [hrm/src/](hrm/src/):

| Priority | Module | Form | Aggregates to add |
|---|---|---|---|
| P1 | [ui_order_details.4gl](hrm/src/ui_order_details.4gl) | [order_details_list.per](hrm/src/order_details_list.per) | COUNT orderid; SUM quantity, totalprice |
| P1 | [ui_orders.4gl](hrm/src/ui_orders.4gl) | [orders_list.per](hrm/src/orders_list.per) | COUNT orderid; SUM freight |
| P1 | [ui_products.4gl](hrm/src/ui_products.4gl) | [products_list.per](hrm/src/products_list.per) | COUNT productid; SUM unitsinstock, unitsonorder |
| P2 | [ui_employees.4gl](hrm/src/ui_employees.4gl) | [employees_list.per](hrm/src/employees_list.per) | COUNT employeeid |
| P2 | [ui_empl_terr.4gl](hrm/src/ui_empl_terr.4gl) | [empl_terr_list.per](hrm/src/empl_terr_list.per) | COUNT employeeid |
| P3 | [ui_shippers.4gl](hrm/src/ui_shippers.4gl) | [shippers_list.per](hrm/src/shippers_list.per) | COUNT shipperid |
| P3 | [ui_suppliers.4gl](hrm/src/ui_suppliers.4gl) | [suppliers_list.per](hrm/src/suppliers_list.per) | COUNT supplierid |
| P3 | [ui_territories.4gl](hrm/src/ui_territories.4gl) | [territories_list.per](hrm/src/territories_list.per) | COUNT territoryid |
| P3 | [ui_region.4gl](hrm/src/ui_region.4gl) | [region_list.per](hrm/src/region_list.per) | COUNT regionid |
| P3 | [ui_usstates.4gl](hrm/src/ui_usstates.4gl) | [usstates_list.per](hrm/src/usstates_list.per) | COUNT stateid |
| P4 | [ui_categories.4gl](hrm/src/ui_categories.4gl) | [categories_list.per](hrm/src/categories_list.per) | COUNT categoryid |
| P4 | [ui_customers.4gl](hrm/src/ui_customers.4gl) | [customers_list.per](hrm/src/customers_list.per) | COUNT customerid |
| P4 | [ui_cust_cust_demo.4gl](hrm/src/ui_cust_cust_demo.4gl) | [cust_cust_demo_list.per](hrm/src/cust_cust_demo_list.per) | COUNT customerid |
| P4 | [ui_cust_demo.4gl](hrm/src/ui_cust_demo.4gl) | [cust_demo_list.per](hrm/src/cust_demo_list.per) | COUNT customertypeid |

Screen record names are to be confirmed per form while editing (most
modules use `sr`; confirm against the `SCREEN RECORD` line in the `.per`
file and use that exact name in the `tableExcelExport()` call).

## Per-module recipe

For each `ui_<entity>.4gl`:

### 1. Imports (top of file, if missing)
```
IMPORT util
IMPORT os
IMPORT FGL com.fourjs.poiapi.fgl_table_export
```

### 2. Action handler inside `DISPLAY ARRAY … TO sr.*`
```
ON ACTION excel_export
   CALL export_<entity>_to_excel()
```

These list modules use a standalone `DISPLAY ARRAY` (not a `DIALOG`) —
call the export function directly. Do **not** copy the
`selected_option / ACCEPT DIALOG` pattern from `md_order_details` here;
that pattern is only needed when the DISPLAY ARRAY lives inside a
multi-construct DIALOG.

### 3. Export function (bottom of module)
```
PRIVATE FUNCTION export_<entity>_to_excel() RETURNS ()
   DEFINE jsonData util.JSONArray
   DEFINE excelFile STRING

   LET jsonData = util.JSONArray.fromFGL(<array_variable>)
   LET excelFile = tableExcelExport("<screen_record_name>", jsonData)

   IF excelFile IS NOT NULL AND excelFile.getLength() > 0 THEN
      CALL fgl_putfile(excelFile, os.Path.baseName(excelFile))
   ELSE
      ERROR "Excel export failed."
   END IF
END FUNCTION
```

### 4. Form changes in the matching `<entity>_list.per`

- Add an extra bottom row to the `TABLE` block with `[tot001 ]` / `[tot005 ]`
  placeholders aligned under the columns that need aggregates.
- In `ATTRIBUTES`, declare the formonly fields and the `AGGREGATE` rows,
  e.g.:
  ```
  AGGREGATE tot001 = FORMONLY.rec_count,
    AGGREGATETEXT = "Count:", AGGREGATETYPE = COUNT;
  AGGREGATE tot005 = FORMONLY.qty_total,
    AGGREGATETEXT = "Total:", AGGREGATETYPE = SUM;
  ```
- No `.4gl` code needed for aggregate values — the runtime computes
  `COUNT` / `SUM` / `AVG` / `MIN` / `MAX` automatically. Only
  `AGGREGATETYPE=PROGRAM` requires code-side `DISPLAY TO`.

## Shared toolbar edits

### [hrm/src/list_standard.4tb](hrm/src/list_standard.4tb)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ToolBar>
  <ToolBarItem name="add" />
  <ToolBarSeparator />
  <ToolBarItem name="modify" />
  <ToolBarItem name="delete" />
  <ToolBarItem name="excel_export" />   <!-- new -->
  <ToolBarSeparator />
  <ToolBarItem name="exit" />
</ToolBar>
```

### [hrm/src/list_lookup.4tb](hrm/src/list_lookup.4tb)
Insert `<ToolBarItem name="excel_export"/>` before the final
`<ToolBarSeparator/>` / `exit` pair.

No changes needed to [hrm/src/generic.4ad](hrm/src/generic.4ad) — the
`excel_export` ActionDefault (text `"Export to Excel"`, icon
`fa-file-excel-o`) is already present at lines 43-46 and applies globally.

## Files to modify

- [hrm/src/list_standard.4tb](hrm/src/list_standard.4tb) — +1 toolbar item
- [hrm/src/list_lookup.4tb](hrm/src/list_lookup.4tb) — +1 toolbar item
- 14 `hrm/src/ui_*.4gl` list modules — 3 imports, 1 action, 1 function each
- 14 matching `hrm/src/*_list.per` forms — aggregate rows + TABLE placeholders
- No changes to [fgl-darwin.4pw](fgl-darwin.4pw) (no new source files)

## Reused functions / patterns

- `tableExcelExport(screen_record, jsonData)` — from
  `com.fourjs.poiapi.fgl_table_export` (package at
  [.fglpkg/poiapi/com/fourjs/poiapi/](.fglpkg/poiapi/com/fourjs/poiapi/);
  source at `~/4js-github/poiapi`)
- `util.JSONArray.fromFGL()` — one-liner dynamic-array → JSON
- `fgl_putfile()` — triggers file download (browser / GDC)
- `os.Path.baseName()` — derives the download filename
- `excel_export` ActionDefault in [hrm/src/generic.4ad](hrm/src/generic.4ad)
- `AGGREGATE … AGGREGATETYPE = COUNT|SUM` on form columns — runtime
  auto-computes

## Rollout sequencing (recommended)

1. **Shared toolbars** — edit `list_standard.4tb` and `list_lookup.4tb`.
   Instant effect on all list modules once the action handlers land.
2. **Template module** — do one P3 module end-to-end (e.g.
   `ui_shippers` — few columns, easy smoke test). Compile, run, export,
   inspect the `.xlsx`.
3. **P3 / P4 modules** — COUNT only, mechanical copy-paste of the
   template.
4. **P2 modules** — `ui_employees`, `ui_empl_terr` — still COUNT only.
5. **P1 modules** — `ui_orders`, `ui_order_details`, `ui_products` —
   add `SUM` aggregates; take care over which columns are genuinely
   summable (prices per-line do *not* sum meaningfully; `freight`,
   `quantity`, `totalprice` do).
6. Update this document's **Status** section as each module lands.

## Verification

Per module after changes:

1. **Compile clean** — `make <module>` or `make all`, no warnings.
2. **Manual smoke test** — `fglrun bin/<module>.42m`, open list,
   click the Excel-icon toolbar button. Confirm the file downloads,
   opens in Excel with correct headers, data, and aggregate
   formulas (`SUM(…)`, `COUNTA(…)`) in the totals row.
3. **GGC regression** — `make ggc-test` (runs
   [ggc-test/test_md_orders.4gl](ggc-test/test_md_orders.4gl)) must still
   pass — master/detail export path unchanged.
4. **Optional new GGC scenario** — once the rollout is complete, add a
   scenario that does `CALL ggc.action("excel_export")` on one list
   and asserts `ggc.checkNoError()`.

## Out of scope

- Adding export to detail/edit forms (`master_detail.4tb` users) — these
  are data-entry forms, not display arrays.
- Any change to `md_order_details.4gl` — already shipped.
- Any change to the POI library itself (upstream at
  `~/4js-github/poiapi`).
- CSV / PDF export — this rollout is Excel only.

## Status

| Module | Toolbar | .4gl action + function | .per aggregates | Compiled | Smoke-tested |
|---|:-:|:-:|:-:|:-:|:-:|
| (shared) `list_standard.4tb` | ✅ | — | — | — | — |
| (shared) `list_lookup.4tb` | ☐ | — | — | — | — |
| `ui_order_details` (P1) | ✅ | ✅ | ✅ COUNT orderid, SUM quantity, SUM totalprice | ✅ | ☐ |
| `ui_orders` (P1) | ✅ | ✅ | ✅ COUNT orderid, SUM freight | ✅ | ☐ |
| `ui_products` (P1) | ✅ | ✅ | ✅ COUNT productid, SUM unitsinstock (unitsonorder skipped — see note) | ✅ | ☐ |
| `ui_employees` (P2) | ☐ | ☐ | ☐ | ☐ | ☐ |
| `ui_empl_terr` (P2) | ☐ | ☐ | ☐ | ☐ | ☐ |
| `ui_shippers` (P3) | ☐ | ☐ | ☐ | ☐ | ☐ |
| `ui_suppliers` (P3) | ☐ | ☐ | ☐ | ☐ | ☐ |
| `ui_territories` (P3) | ☐ | ☐ | ☐ | ☐ | ☐ |
| `ui_region` (P3) | ☐ | ☐ | ☐ | ☐ | ☐ |
| `ui_usstates` (P3) | ☐ | ☐ | ☐ | ☐ | ☐ |
| `ui_categories` (P4) | ☐ | ☐ | ☐ | ☐ | ☐ |
| `ui_customers` (P4) | ☐ | ☐ | ☐ | ☐ | ☐ |
| `ui_cust_cust_demo` (P4) | ☐ | ☐ | ☐ | ☐ | ☐ |
| `ui_cust_demo` (P4) | ☐ | ☐ | ☐ | ☐ | ☐ |
| `md_order_details` | ✅ | ✅ | ✅ | ✅ | ✅ |
