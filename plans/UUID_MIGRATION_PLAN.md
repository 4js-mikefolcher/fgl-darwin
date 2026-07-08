# UUID Migration Plan — Northwind on Postgres

Branch target: new branch off `genero/step2/refactor` (suggested: `genero/step3/uuid-pk`).

## 1. Decisions (locked)

- **Scope**: only the 8 SERIAL-backed PKs. CHAR-keyed tables (`customers`, `territories`, `cust_demo`, `cust_cust_demo` composite) are out of scope.
- **Generation**: server-side, `DEFAULT gen_random_uuid()::text` in Postgres, retrieved via `INSERT ... RETURNING <pk>`.
- **Storage**: `CHAR(36)` text columns. Postgres `uuid` native type explicitly not used (keeps the schema portable and the BDL `LIKE` typing predictable).
- **Data**: rebuild fresh — the seed script in [dbs/northwind_pgs_84x.4gl](dbs/northwind_pgs_84x.4gl) becomes the source of truth. No in-place migration of existing rows.

## 2. Tables affected

| Table | Current PK | New PK |
|---|---|---|
| `categories` | `categoryid SERIAL` | `categoryid CHAR(36)` |
| `employees` | `employeeid SERIAL` | `employeeid CHAR(36)` |
| `orders` | `orderid SERIAL` | `orderid CHAR(36)` |
| `products` | `productid SERIAL` | `productid CHAR(36)` |
| `region` | `regionid SERIAL` | `regionid CHAR(36)` |
| `shippers` | `shipperid SERIAL` | `shipperid CHAR(36)` |
| `suppliers` | `supplierid SERIAL` | `supplierid CHAR(36)` |
| `usstates` | `stateid SERIAL` | `stateid CHAR(36)` |

FKs that must follow the parent column type:

| Child column | Parent |
|---|---|
| `products.supplierid` | `suppliers.supplierid` |
| `products.categoryid` | `categories.categoryid` |
| `orders.employeeid` | `employees.employeeid` |
| `orders.shipvia` | `shippers.shipperid` |
| `order_details.orderid` | `orders.orderid` |
| `order_details.productid` | `products.productid` |
| `empl_terr.employeeid` | `employees.employeeid` |
| `employees.reportsto` | `employees.employeeid` (self) |
| `territories.regionid` | `region.regionid` |

Unchanged (still CHAR-keyed): `orders.customerid`, `empl_terr.territoryid`, `cust_cust_demo.*`.

Note: [dbs/northwind_pgs_84x.4gl:102](dbs/northwind_pgs_84x.4gl#L102) defines a `shippers_tmp` table that is not referenced from BDL code — recommend deleting it as part of this work (verify first).

## 3. Touch-point inventory (from current source)

- **8** `sqlca.sqlerrd[2]` retrieval sites across [hrm/src/model_*.4gl](hrm/src/) — must be replaced with `INSERT … RETURNING` patterns.
- **34** `INTEGER … WSParam` annotations in [hrm/src/rest_*.4gl](hrm/src/) — every path parameter for one of the 8 entities becomes `STRING`.
- **7** sites where an integer ID is concatenated into a SQL string without quotes (e.g. `" orderid = ", order_id`) — must be quoted for CHAR(36) values.
- **15** `model_*.4gl` files in scope (`insertRec`, `validateRec` shape changes for the 8 affected entities; the 7 others are passively affected only through FKs).
- All `*_list.per` and entity forms using `LIKE table.column` will inherit the new type once `northwind.sch` is regenerated — no field-by-field edits expected, but column widths and alignment in list views should be eyeballed.

## 4. Work breakdown

### Phase A — Schema rewrite

1. Rewrite [dbs/northwind_pgs_84x.4gl](dbs/northwind_pgs_84x.4gl):
   - 8 affected PK columns: `<pk> CHAR(36) NOT NULL DEFAULT gen_random_uuid()::text PRIMARY KEY`.
   - 9 child FK columns: change from `INTEGER`/`SMALLINT` to `CHAR(36) NOT NULL` (nullable where the FK is optional, e.g. `employees.reportsto`).
   - Drop the unused `shippers_tmp` table once confirmed dead.
2. Rewrite the seed inserts. Two strategies, pick one:
   - **Deterministic UUIDs (recommended for demo)**: hardcode UUID strings for each parent row in the seed script. FKs reference those literals. Repeatable across rebuilds, FK wiring is trivial.
   - **Server-generated**: omit the PK in `INSERT`s, capture via `RETURNING` into a temp variable, then use that variable for child inserts. More dynamic, more code.
3. Confirm `pgcrypto` extension is enabled (the `gen_random_uuid()` is built-in to Postgres 13+, so on `dbmpgs_9` / PG 13+ this is no-op; on older PG add `CREATE EXTENSION IF NOT EXISTS pgcrypto`).

Deliverable: a re-runnable `make db-rebuild` that drops and re-creates the northwind DB with UUID PKs.

### Phase B — Regenerate `northwind.sch`

The schema file is the symlink target [dbs/northwind.sch](dbs/northwind.sch). After Phase A:

```bash
fgldbsch -db northwind -schema public -t '*' -fileprefix dbs/northwind
```

(Adjust to match the project's existing extraction command; check the Makefile or any `db-*` target.)

Verify by `git diff dbs/northwind.sch` — should show the 8 PK columns and their FK references changing from `INTEGER`/`SMALLINT` to `CHAR(36)`.

### Phase C — Model layer

For each of the 8 affected models (`model_categories`, `model_employees`, `model_orders`, `model_products`, `model_region`, `model_shippers`, `model_suppliers`, `model_usstates`):

1. **`insertRec`**. Replace:

   ```4gl
   INSERT INTO categories (categoryid, categoryname, description)
      VALUES (DEFAULT, self.categoryname, self.description)
   ...
   IF sqlca.sqlcode == 0 THEN
      LET self.categoryid = sqlca.sqlerrd[2]   -- broken for CHAR(36)
   END IF
   ```

   with:

   ```4gl
   INSERT INTO categories (categoryname, description)
      VALUES (self.categoryname, self.description)
      RETURNING categoryid INTO self.categoryid
   ```

   The `DEFAULT gen_random_uuid()::text` column default does the work. The implicit-cast assignment populates `self.categoryid` directly.

2. **`validateRec`** — already does `SELECT 1 INTO … FROM <table> WHERE <pk> = self.<pk>`. No literal change needed because `LIKE table.column` typing follows the schema, but double-check there are no `IF self.<pk> < 1` legacy guards.

3. **`validate_<entity>` helpers** (e.g. `validate_shipvia` in [model_shippers.4gl:107](hrm/src/model_shippers.4gl#L107), `validate_customer` in `model_customers.4gl`, etc.) — same: `LIKE` typing carries the change.

### Phase D — REST layer

Touches the 8 entity REST modules (`rest_categories`, `rest_employees`, `rest_orders`, `rest_order_details`, `rest_products`, `rest_shippers`, `rest_suppliers`, `rest_empl_terr`, `rest_usstates`). For each `WSParam INTEGER` matching one of the 8 affected PKs:

```4gl
PUBLIC FUNCTION getById(
   p_categoryid INTEGER ATTRIBUTES(WSParam))
```

becomes:

```4gl
PUBLIC FUNCTION getById(
   p_categoryid STRING ATTRIBUTES(WSParam, WSLength=36))
```

(`WSLength=36` documents the contract; not strictly required.)

This is a **breaking change** for any external API consumer. If there are none (and there shouldn't be — this is a demo), no compatibility shim is needed.

Path matchers like `/categories/{p_categoryid}` work unchanged — only the param type changes.

### Phase E — UI / SQL string-concat sites

Grep:

```bash
grep -rnE '= *\", *(order_id|empl_id|prod_id|ship_id|supp_id|cat_id|reg_id|state_id)' --include='*.4gl' hrm/src/
```

Each match is a SQL string built like `" orderid = ", order_id` — works for INTEGER, breaks for CHAR(36). Either:

- Add quotes: `" orderid = '", order_id CLIPPED, "'"`, or
- Convert to parameterized SQL with `?` placeholders (preferred; safer and consistent with the other CHAR-keyed paths in the codebase).

Estimated 7 sites. The previously-deleted `view_*` functions had these patterns — surviving examples are mostly in helpers like `<entity>_do_load`, `order_lookup_menu`, the report `where_clause` builders, and `md_order_details.4gl` execute_search.

Also audit `<` and `>` integer comparisons on these IDs (e.g. `IF empl_id < 1`) — pointless for UUID, replace with `IF empl_id IS NULL OR empl_id.getLength() == 0` or just `IF empl_id IS NULL`.

### Phase F — Test layer

1. **`test_rest_*.4gl`** (14 files, ~140 test functions per [CLEANUP_PLAN.md](CLEANUP_PLAN.md)). Patterns to update:
   - Hardcoded `INTEGER` IDs in URL paths (`GET /employees/3`) — change to a fresh-UUID flow: POST first, capture the returned UUID, then GET/PUT/DELETE using that.
   - Local `DEFINE id INTEGER` for captured IDs → `DEFINE id STRING` (or `LIKE` against the new schema).
   - DB validation `SELECT … WHERE <pk> = <captured_id>` — must quote.
2. **`ggc-test/test_md_orders.4gl`**. The existing strategy of `ggc.getFieldValue()` to capture serial values dynamically works as-is for UUIDs (string output). No structural change, just the field-value type assumptions.
3. **Reports** ([hrm/src/rpt_*.4gl](hrm/src/)) — verify `where_clause` construction and any place that does `WHERE empl_id = ${param}`. Same quoting fix as Phase E.

### Phase G — Verification

1. `make clean all` clean compile (will run after Phase B at the earliest, so plan to land Phases A+B first as a unit).
2. `make ggc-build && make ggc-test` against the rebuilt DB.
3. Smoke test:
   - `main_orders` — query, add, edit, delete an order. Verify the new orderid is a UUID string in the form.
   - `mstr_dtl_order` — search, view, add order with multiple detail rows. Verify FK to product UUIDs.
   - `main_rpt_orders_by_customer` — confirm WHERE-clause builder still produces valid SQL.
4. Manual REST sanity: `curl http://localhost:8899/categories` returns objects with UUID `categoryid` strings.

## 5. Sequencing

The FK web makes mixed-state unsupportable — schema and models must move together. Suggested order **inside one branch**:

1. **Phase A + B together** as commit 1. Compile will fail on the model layer; that's expected.
2. **Phase C** as commit 2 (or one commit per entity if you want bisectable history). Compile passes after each model is internally consistent.
3. **Phase D** as commit 3.
4. **Phase E** as commit 4.
5. **Phase F** as commit 5 (likely the largest by line count, but mechanical).
6. **Phase G** verification commit (smoke-test scripts, fixes to anything that surfaces).

If you want a smaller pilot to de-risk first, the cleanest single-entity candidate is `shippers`:
- Few FKs in (just `orders.shipvia`).
- Touches a manageable subset: `model_shippers`, `rest_shippers`, `ui_shippers`, `test_rest_shippers`, plus `orders.shipvia` rewiring.
- If the shippers conversion works end-to-end, the same recipe scales to the other 7 entities.

But: a partial pilot still requires changing `orders.shipvia` to CHAR(36), which means the orders schema and code must also tolerate the new type. So the pilot isn't truly isolated — it's just "do one + minimal blast radius" instead of "do all in one go."

## 6. Risks and gotchas

- **`sqlca.sqlerrd[2]` is INTEGER-typed in BDL**. Any code expecting it after an INSERT must move to `RETURNING ... INTO` — there is no string variant of `sqlerrd[2]`.
- **`dispatch.4gl` indirection**. The controller passes IDs around as `LIKE` types — should follow the schema, but worth grepping for any place dispatch stores `INTEGER` locals tied to one of the 8 entities.
- **Composite keys**. `order_details` (`orderid`, `productid`) and `empl_terr` (`employeeid`, `territoryid`) — both touch UUIDs on one side and CHAR/VARCHAR on the other. Insert/update/delete WHERE clauses must remain consistent.
- **`sqlca.sqlerrd[3]` (rows affected)** is unchanged — still INTEGER. Don't touch it.
- **Form column widths**. List grids displaying the PK column (e.g. orders_list.per showing orderid) will visually balloon from 4-5 digits to 36-character UUIDs. May want a `WIDTH=36` or hide the column entirely in list views.
- **Hardcoded IDs in seed data and tests**. The current seed inserts use integer literals as FKs (e.g. `INSERT INTO orders ... VALUES (..., 1, ...)` referencing `employees.employeeid = 1`). The rewrite must replace these with UUID literals consistently. Using deterministic UUIDs in the seed file makes this much easier than capturing server-generated values mid-script.
- **`fgldbsch` schema extraction** must run against a Postgres connection that already has the new schema. Don't commit a `.sch` that disagrees with the actual database state.
- **REST API consumers**. If anything external calls these endpoints expecting `integer` IDs in JSON, this breaks them. (Demo only — likely fine.)

## 7. Out of scope / explicitly not changing

- `customers.customerid` (`CHAR(5)`, e.g. `ALFKI`) — preserves the Northwind look.
- `territories.territoryid` (`VARCHAR(20)`) — unchanged.
- `cust_demo.customertypeid`, `cust_cust_demo` composite — unchanged.
- Native Postgres `uuid` type — explicitly chose `CHAR(36)` for portability. If you later want `uuid`, that's a small follow-up that affects only the schema and `.sch`, not the BDL code.
- The 12-file structural duplication in [CLEANUP_PLAN.md](CLEANUP_PLAN.md) §3.6 — orthogonal to this work.
- Pending items in [MD_REFACTOR_PLAN.md](MD_REFACTOR_PLAN.md) — independent, can land before or after.

## 8. Estimated effort

Rough order-of-magnitude, not committed:

| Phase | Effort |
|---|---|
| A. Schema + seed rewrite | 4-6 hours |
| B. .sch regeneration | 30 min |
| C. Models (8 × insertRec + validations) | 2-3 hours |
| D. REST endpoints (34 param changes + DB validations) | 2 hours |
| E. UI SQL string-concat sites | 1-2 hours |
| F. Tests (14 test_rest_* + 1 ggc) | 4-6 hours |
| G. Verification + fixes | 2-4 hours |
| **Total** | **~16-24 hours** |

The majority of work is mechanical (param type renames, INSERT…RETURNING swaps). The seed rewrite (Phase A) is the most thought-intensive because it sets the data shape every downstream test depends on.
