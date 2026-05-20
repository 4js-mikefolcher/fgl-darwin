# Unit Test Plan for `hrm/src`

## Framework Notes

- `fglunit` requires a live DB connection for any function that touches SQL — use `FglUnit.setSetupSuite` / `setTeardownSuite` to open/close the `northwind` database
- Functions that open forms, windows, or run `MENU` / `CONSTRUCT` / `DISPLAY ARRAY` cannot be tested with `fglunit` (they need GGC) — these are excluded below
- The existing `test_rest_*` files use a hand-rolled framework — the new tests will use `fglunit` instead

---

## Tier 1 — Pure Logic, No DB

> Highest value, no setup needed

| Module | Function | Test Cases |
|--------|----------|------------|
| `model_helper` | `t_valid_rec.init()` | `status=FALSE`, `msg=""` after init |
| `model_helper` | `t_valid_rec.success(msg)` | `status=TRUE`, msg matches |
| `model_helper` | `t_valid_rec.failed(msg)` | `status=FALSE`, msg matches |
| `model_helper` | `t_valid_rec.success("")` | empty msg accepted |
| `md_helper` | constants (`cQuit`…`cAppend`, `cViewImage`…) | value assertions |
| `list_view_helper` | constants (`cAddRecord`…`cExportToExcel`) | value assertions |
| `main_lib` | `generate_temp_filename(prefix, ext)` | path contains prefix; ends with `.ext`; path is non-null; different calls produce different names |
| `main_lib` | `get_program_icon(pgm_name)` | known name returns correct icon; unknown name returns `NULL`; path-prefixed name strips correctly |

---

## Tier 2 — DB-Backed Validation

> Requires `DATABASE northwind` connection. These `validateRec` methods have rich branching logic that is fully testable with a real DB.

### `model_categories` — `t_category.validateRec(mode)`

| Test | Setup |
|------|-------|
| `mode="A"`, valid name ≤15 chars → success | no DB row needed |
| `mode="A"`, name `NULL` → failed `"Category Name is required"` | — |
| `mode="A"`, name empty → failed | — |
| `mode="A"`, name >15 chars → failed `"must be 15 characters or less"` | — |
| `mode="C"`, existing `categoryid` → success | use real row (e.g. `id=1`) |
| `mode="C"`, non-existent id → failed `"Category ID is not found"` | — |

### `model_customers` — `t_customer.validateRec(mode)`

| Test | Setup |
|------|-------|
| `mode="A"`, valid `customerid` + `companyname` → success | no existing row |
| `mode="A"`, `customerid` already exists → failed `"already exists"` | use existing row |
| `mode="A"`, `customerid` `NULL` → failed `"required"` | — |
| `mode="A"`, `companyname` `NULL` → failed `"required"` | — |
| `mode="C"`, existing `customerid` → success | use existing row |
| `mode="C"`, non-existent `customerid` → failed `"not found"` | — |

### `model_customers` — `validate_customer(customerid)`

| Test |
|------|
| valid `customerid` → success, msg = company name |
| non-existent `customerid` → failed |
| `NULL` `customerid` → success, msg = `""` |
| empty string `customerid` → success, msg = `""` |

### `model_employees` — `t_employee.validateRec(mode)`

| Test |
|------|
| `mode="A"`, all required fields valid, `hiredate > birthdate` → success |
| `firstname` `NULL` → failed `"First name is missing"` |
| `lastname` `NULL` → failed `"Last name is missing"` |
| `birthdate` `NULL` → failed `"Birth date is missing"` |
| `hiredate` `NULL` → failed `"Hire date name is missing"` |
| `hiredate ≤ birthdate` → failed `"Hire date is before birth date"` |
| `reportsto` = valid employee id → success, `fullname` populated |
| `reportsto` = non-existent id → failed `"Invalid reports to"` |
| `mode="C"`, existing `employeeid` → success |
| `mode="C"`, non-existent `employeeid` → failed `"not found"` |

### `model_employees` — `validate_employee(employeeid)`

| Test |
|------|
| valid id → success, msg = `"firstname lastname"` |
| non-existent id → failed |
| `NULL` id → success, msg = `""` |

### `model_orders` — `t_order.validateRec(mode)`

| Test |
|------|
| `mode="A"`, valid `orderdate` + valid `customerid` + valid `employeeid` → success |
| `orderdate` `NULL` → failed `"Order Date is required"` |
| `customerid` `NULL`/empty → failed `"Customer ID is missing"` |
| `customerid` non-existent → failed `"does not exist in customers"` |
| `employeeid` `NULL` → failed `"Employee ID is missing"` |
| `employeeid` non-existent → failed `"does not exist in employees"` |
| `mode="C"`, existing `orderid` → success |
| `mode="C"`, non-existent `orderid` → failed `"not found"` |

### `model_order_details` — `t_order_detail.validateRec(mode)`

| Test |
|------|
| `mode="A"`, all valid → success |
| `orderid` `NULL` → failed `"Order ID is required"` |
| `productid` `NULL` → failed `"Product ID is required"` |
| `unitprice` `NULL` → failed `"Unit Price is required"` |
| `quantity` `NULL` → failed `"Quantity is required"` |
| `discount` `NULL` → failed `"Discount is required"` |
| `unitprice < 0` → failed `"cannot be negative"` |
| `quantity < 1` → failed `"must be at least 1"` |
| `discount < 0` → failed `"must be between 0 and 1"` |
| `discount ≥ 1` → failed `"must be between 0 and 1"` |
| non-existent `productid` → failed `"does not exist in products"` |
| `mode="C"`, existing composite key → success |
| `mode="C"`, non-existent composite key → failed `"not found"` |
| `mode="A"`, duplicate composite key → failed `"already exists"` |

### `model_order_details` — `t_order_detail.validate_product()`

| Test |
|------|
| valid `productid` → success, `productname` populated |
| non-existent `productid` → failed |
| `NULL` `productid` → success (no lookup) |

### `model_products` — `t_product.validateRec(mode)`

| Test |
|------|
| `mode="A"`, valid name + `discontinued` set → success |
| `productname` `NULL` → failed `"required"` |
| `productname` empty → failed |
| `discontinued` `NULL` → failed `"required"` |
| `mode="C"`, existing `productid` → success |
| `mode="C"`, non-existent `productid` → failed `"not found"` |

### `model_shippers` — `t_shipper.validateRec(mode)`

| Test |
|------|
| `mode="A"`, `companyname` + `phone` set → success |
| `companyname` `NULL` → failed `"required"` |
| `phone` `NULL` → failed `"required"` |
| `mode="C"`, existing `shipperid` → success |
| `mode="C"`, non-existent `shipperid` → failed `"not found"` |

### `model_shippers` — `validate_shipvia(shipperid)`

| Test |
|------|
| valid `shipperid` → success |
| non-existent `shipperid` → failed |
| `NULL` `shipperid` → success |

### `model_suppliers` — `t_supplier.validateRec(mode)`

| Test |
|------|
| `mode="A"`, `companyname` set → success |
| `companyname` `NULL` → failed |
| `mode="C"`, existing `supplierid` → success |
| `mode="C"`, non-existent `supplierid` → failed |

### `model_territories` — `t_territory.validateRec(mode)`

| Test |
|------|
| `mode="A"`, all fields set, id not existing → success |
| `mode="A"`, id already exists → failed `"already exists"` |
| `territoryid` `NULL` → failed `"required"` |
| `territorydescription` `NULL` → failed `"required"` |
| `regionid` `NULL` → failed `"required"` |
| `mode="C"`, existing `territoryid` → success |
| `mode="C"`, non-existent `territoryid` → failed `"not found"` |

### `model_region` — `t_region.validateRec(mode)`

| Test |
|------|
| `mode="A"`, `regiondescription` set → success |
| `regiondescription` `NULL` → failed |
| `mode="C"`, existing `regionid` → success |
| `mode="C"`, non-existent `regionid` → failed |

### `model_usstates` — `t_usstate.validateRec(mode)`

| Test |
|------|
| `mode="A"` → always success (no field checks) |
| `mode="C"`, existing `stateid` → success |
| `mode="C"`, non-existent `stateid` → failed |

### `model_cust_demo` — `t_cust_demo.validateRec(mode)`

| Test |
|------|
| `mode="A"`, `customertypeid` set, not existing → success |
| `customertypeid` `NULL` → failed `"required"` |
| `mode="A"`, `customertypeid` already exists → failed `"already exists"` |

### `model_cust_cust_demo` — `t_cust_cust_demo.validateRec(mode)`

| Test |
|------|
| `customerid` `NULL` → failed `"required"` |
| `customertypeid` `NULL` → failed `"required"` |
| duplicate assignment → failed `"already assigned"` |
| valid new assignment → success |

### `model_cust_cust_demo` — `validateCustomer()` / `validateCustomerType()`

| Test |
|------|
| valid `customerid` → success, `companyname` populated |
| non-existent `customerid` → failed |
| valid `customertypeid` → success, `customerdesc` populated |
| non-existent `customertypeid` → failed |

### `model_empl_terr` — `t_empl_terr.validateRec(mode)` / `validateEmployee()` / `validateTerritory()`

| Test |
|------|
| `employeeid` `NULL` → failed |
| `territoryid` `NULL` → failed |
| duplicate assignment → failed |
| valid new assignment → success |
| `validateEmployee`: valid id → success, `fullname` populated |
| `validateEmployee`: non-existent id → failed |
| `validateTerritory`: valid id → success, description + region populated |
| `validateTerritory`: non-existent id → failed |

---

## Tier 3 — DB CRUD (Insert/Update/Delete Round-Trips)

> Testable but require careful setup/teardown to avoid polluting the DB. Each model's `insertRec`, `updateRec`, `deleteRec` tested as a lifecycle.

| Module | Tests |
|--------|-------|
| `model_categories` | insert → verify `sqlca.sqlcode=0` → update → verify → delete → verify |
| `model_customers` | same pattern |
| `model_employees` | same pattern |
| `model_orders` | same (depends on valid customer + employee existing) |
| `model_order_details` | same (depends on valid order + product) |
| `model_products` | same |
| `model_shippers` | same |
| `model_suppliers` | same |
| `model_territories` | same |
| `model_region` | same |
| `model_usstates` | same |
| `model_cust_demo` | same |
| `model_cust_cust_demo` | insert + delete (no update) |
| `model_empl_terr` | insert + delete (no update) |

---

## Excluded — UI/Form-Dependent (Need GGC)

- All `ui_*` modules (`DISPLAY ARRAY`, `INPUT`, `CONSTRUCT`)
- `dialog_prompt` (`MENU` dialog)
- `advsearch_orders` (`CONSTRUCT` + `OPEN WINDOW`)
- `dispatch_*` functions (delegate to `ui_*` modules)
- `report_helper` (`OPEN WINDOW`, `DISPLAY ARRAY`, report output)
- `list_view_helper.export_array_to_excel` (calls `fgl_putfile`)
- All `rpt_*` modules (`START REPORT`)
- All `main_*` programs (entry points)

---

## Proposed Test File Structure

```
hrm/src/
  test_model_helper.4gl         -- Tier 1: pure t_valid_rec + constants
  test_main_lib.4gl             -- Tier 1: generate_temp_filename, get_program_icon
  test_model_categories.4gl     -- Tier 2+3: validateRec + CRUD
  test_model_customers.4gl      -- Tier 2+3
  test_model_employees.4gl      -- Tier 2+3
  test_model_orders.4gl         -- Tier 2+3
  test_model_order_details.4gl
  test_model_products.4gl
  test_model_shippers.4gl
  test_model_suppliers.4gl
  test_model_territories.4gl
  test_model_region.4gl
  test_model_usstates.4gl
  test_model_cust_demo.4gl
  test_model_cust_cust_demo.4gl
  test_model_empl_terr.4gl
```

Roughly 130+ individual test functions across 16 test files.
