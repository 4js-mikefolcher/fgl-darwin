# Northwind Genero Application — Refactoring Changelog
## Changes Since GENERO_MODERNIZATION_GUIDE.md (Post Phase 35)

**Baseline:** GENERO_MODERNIZATION_GUIDE.md — Phases 1-35, dated February 9-16, 2026  
**This Document Covers:** February 17, 2026 — March 16, 2026  
**Branch:** step2-refactor

---

## Table of Contents

1. [Timeline Overview](#timeline-overview)
2. [Phase 36: List View for All Modules](#phase-36-list-view-for-all-modules)
3. [Phase 37: Employee Territories UI/UX Standardization](#phase-37-employee-territories-uiux-standardization)
4. [Phase 38: Controller/Dispatch Architecture](#phase-38-controllerdispatch-architecture)
5. [Phase 39: Record Type Methods (Model Layer)](#phase-39-record-type-methods-model-layer)
6. [Phase 40: Org Chart Report](#phase-40-org-chart-report)
7. [Phase 41: IMPORT FGL Build Refactoring](#phase-41-import-fgl-build-refactoring)
8. [Phase 42: Model/UI Layer Separation](#phase-42-modelui-layer-separation)
9. [Phase 43: Model Helper — Validation Result Type](#phase-43-model-helper--validation-result-type)
10. [Phase 44: Customer Demographics Modules](#phase-44-customer-demographics-modules)
11. [Phase 45: Dialog Prompt Utility](#phase-45-dialog-prompt-utility)
12. [Phase 46: REST Web Services](#phase-46-rest-web-services)
13. [Phase 47: Advanced Order Search](#phase-47-advanced-order-search)
14. [Phase 48: Master-Detail Order Entry](#phase-48-master-detail-order-entry)
15. [Phase 49: MD Helper Constants](#phase-49-md-helper-constants)
16. [Phase 50: Cross-Module View Commands](#phase-50-cross-module-view-commands)
17. [Phase 51: New Action Defaults and Styles](#phase-51-new-action-defaults-and-styles)
18. [Phase 52: Menu Expansion](#phase-52-menu-expansion)
19. [Phase 53: Makefile Cleanup](#phase-53-makefile-cleanup)
20. [Phase 54: REST API Test Suite](#phase-54-rest-api-test-suite)
21. [New File Inventory](#new-file-inventory)
22. [Architecture Summary](#architecture-summary)

---

## Timeline Overview

| Date | Commit | Description |
|------|--------|-------------|
| Feb 17 | `6f6e73b` | Implement list view in modules |
| Feb 17 | `06ccb4a` | Add list view to all the tables |
| Feb 17 | `6bfc0a0` | Standardize the employee territories UI/UX |
| Feb 18 | `0a0ee7d` | Refactor code to centralize user navigation (controller/dispatch) |
| Feb 18 | `cc70164` | Fix navigation issues with controller |
| Feb 18 | `d5e70df` | Refactor record types with methods |
| Feb 19 | `81f2088` | Add org chart report to the project |
| Mar 10 | `276eca5` | Major refactoring (IMPORT FGL, model/UI split, REST services, cust_demo, advanced search) |
| Mar 11 | `1c3cfa2` | Add master/detail order entry to main structure |
| Mar 16 | — | REST API test suite: 14 test programs, 141 tests, all passing |

---

## Phase 36: List View for All Modules

**Date:** February 17, 2026  
**Commits:** `6f6e73b`, `06ccb4a`  
**Objective:** Add scrollable table-based list views to every data module, allowing users to browse all query results at once instead of navigating one record at a time.

### Files Created

**13 new list form files (`*_list.per`):**
- `categories_list.per`, `customers_list.per`, `employees_list.per`
- `empl_terr_list.per`, `orders_list.per`, `order_details_list.per`
- `products_list.per`, `region_list.per`, `shippers_list.per`
- `territories_list.per`, `usstates_list.per`
- `cust_demo_list.per`, `cust_cust_demo_list.per`

**1 new helper module:**
- `list_view_helper.4gl` — Defines constants for DISPLAY ARRAY action routing

**1 documentation file:**
- `LIST_VIEW_FEATURE.md` — Reference documentation using the suppliers module as a template

### List View Helper Constants

```4gl
PUBLIC CONSTANT cAddRecord = 1
PUBLIC CONSTANT cEditRecord = 2
PUBLIC CONSTANT cDeleteRecord = 3
PUBLIC CONSTANT cViewRecord = 4
PUBLIC CONSTANT cRefreshList = 5
PUBLIC CONSTANT cExportToExcel = 6
```

### List Form Pattern

Each `*_list.per` form uses a TABLE container with action buttons:
```per
TOOLBAR
  ITEM add
  ITEM modify
  ITEM delete
  SEPARATOR
  ITEM exit
END

LAYOUT (TEXT="Suppliers List")
  VBOX
    TABLE (DOUBLECLICK=modify)
    {
      [c1     |c2                    |c3              |c4              ]
      [c1     |c2                    |c3              |c4              ]
    }
    END
  END
END
```

### Key Pattern

Each ui module's `*_list_display()` function returns `(selectedIdx, selectedOption)`:
```4gl
PUBLIC FUNCTION suppliers_list_display(p_arr) RETURNS (INTEGER, INTEGER)
    DEFINE p_arr DYNAMIC ARRAY OF model_suppliers.t_supplier
    DEFINE selected_option INTEGER

    OPEN WINDOW w_suppliers_list WITH FORM "suppliers_list"
        ATTRIBUTES(STYLE="modulewindow")

    DISPLAY ARRAY p_arr TO sa_suppliers.*
        ATTRIBUTES(UNBUFFERED, DOUBLECLICK=modify)
        ON ACTION modify
            LET selected_option = cEditRecord
            EXIT DISPLAY
        ON ACTION add
            LET selected_option = cAddRecord
            EXIT DISPLAY
        ON ACTION delete
            LET selected_option = cDeleteRecord
            EXIT DISPLAY
        ON ACTION exit
            LET selected_option = 0
            EXIT DISPLAY
    END DISPLAY

    CLOSE WINDOW w_suppliers_list
    RETURN arr_curr(), selected_option
END FUNCTION
```

The controller interprets the returned `selectedOption` to route back to add, edit, or delete operations.

---

## Phase 37: Employee Territories UI/UX Standardization

**Date:** February 17, 2026  
**Commit:** `6bfc0a0`  
**Objective:** Standardize the empl_terr module to follow the same controller/dispatch pattern as all other modules.

### Changes

- Integrated empl_terr into the controller/dispatch framework
- Added list view (`empl_terr_list.per`) with the standard action routing pattern
- Ensured consistent BUTTONEDIT zoom actions for employee and territory lookups
- Applied the same INPUT ARRAY inline editing pattern established in Phase 30 of the original guide

---

## Phase 38: Controller/Dispatch Architecture

**Date:** February 18, 2026  
**Commits:** `0a0ee7d`, `cc70164`  
**Objective:** Centralize user navigation into a reusable controller that handles the CRUD lifecycle (Menu-Query-View-Edit) for all modules through a dispatch routing layer.

### Files Created

- `controller.4gl` — Generic navigation controller
- `dispatch.4gl` — Central routing layer for all modules

### Controller Types

```4gl
PUBLIC TYPE t_controller_config RECORD
    moduleName      STRING,   -- e.g., "suppliers"
    formName        STRING,   -- e.g., "suppliers"
    listFormName    STRING,   -- e.g., "suppliers_list"
    windowTitle     STRING,   -- e.g., "Supplier Maintenance"
    hasModify       BOOLEAN,
    hasQuery        BOOLEAN,
    hasLookup       BOOLEAN,
    entityName      STRING,   -- e.g., "Supplier"
    availableCommands DYNAMIC ARRAY OF t_view_command
END RECORD

PUBLIC TYPE t_view_command RECORD
    commandName    STRING,   -- e.g., "cmd_products"
    commandLabel   STRING,   -- e.g., "Products"
    commandComment STRING    -- e.g., "View products for this supplier"
END RECORD
```

### Controller Functions

| Function | Purpose |
|----------|---------|
| `controller_init(cfg)` | Configure controller for a specific module |
| `controller_navigate()` | Full CRUD navigation loop with First/Prev/Next/Last, Add/Modify/Delete, List, Query, and dynamic view commands |
| `controller_navigate_view()` | Read-only navigation (no CRUD operations) |
| `controller_query_then_navigate()` | Convenience: query first, then navigate results |
| `controller_add()` | Single add operation from root menu |
| `controller_list_view()` | Open list form, dispatch selected action back |
| `controller_get_index()` / `controller_set_index()` | Index accessors |

### Dispatch Interface

Each ui module implements a standard set of dispatch interface functions:

```4gl
-- Example for suppliers module (in ui_suppliers.4gl)
PUBLIC FUNCTION suppliers_get_count() RETURNS INTEGER
PUBLIC FUNCTION suppliers_load_at(idx INTEGER)
PUBLIC FUNCTION suppliers_display()
PUBLIC FUNCTION suppliers_clear()
PUBLIC FUNCTION suppliers_do_query() RETURNS INTEGER
PUBLIC FUNCTION suppliers_do_add()
PUBLIC FUNCTION suppliers_do_edit()
PUBLIC FUNCTION suppliers_do_delete()
PUBLIC FUNCTION suppliers_do_refresh(idx, operation) RETURNS INTEGER
PUBLIC FUNCTION suppliers_list_display(p_arr) RETURNS (INTEGER, INTEGER)
PUBLIC FUNCTION suppliers_do_command(commandName STRING)
```

The `dispatch.4gl` module routes controller calls to the correct module using CASE statements:

```4gl
PUBLIC FUNCTION dispatch_query(moduleName STRING) RETURNS INTEGER
    CASE moduleName
        WHEN "suppliers"
            RETURN suppliers_do_query()
        WHEN "customers"
            RETURN customers_do_query()
        -- ... all 14 modules
    END CASE
END FUNCTION
```

### Integration with Main Programs

Each main program becomes a thin entry point:

```4gl
-- main_suppliers.4gl
IMPORT FGL main_lib
IMPORT FGL controller
IMPORT FGL ui_suppliers

DATABASE northwind

MAIN
    CALL init_pgm()

    CALL controller_init(suppliers_get_config())
    CALL controller_query_then_navigate()
END MAIN
```

### Key Learnings

- The controller pattern eliminates duplicate navigation code from every module
- Dynamic view commands allow context-sensitive cross-module navigation buttons
- The dispatch layer decouples the controller from specific module implementations
- `DIALOG` with dynamically shown/hidden actions enables the controller to adapt its toolbar per module

---

## Phase 39: Record Type Methods (Model Layer)

**Date:** February 18, 2026  
**Commit:** `d5e70df`  
**Objective:** Refactor record types to use Genero BDL method syntax for validation and CRUD operations.

### Pattern

Each model module defines methods on its record type:

```4gl
-- model_suppliers.4gl
PUBLIC TYPE t_supplier RECORD
    supplierid   LIKE suppliers.supplierid,
    companyname  LIKE suppliers.companyname,
    contactname  LIKE suppliers.contactname,
    -- ... all fields
END RECORD

PUBLIC FUNCTION (self t_supplier) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
    DEFINE result t_valid_rec
    CALL result.init()

    IF self.companyname IS NULL OR self.companyname.getLength() = 0 THEN
        CALL result.failed("Company name is required")
        RETURN result
    END IF

    CALL result.success("Validation passed")
    RETURN result
END FUNCTION

PUBLIC FUNCTION (self t_supplier) insertRec() RETURNS (t_valid_rec)
    DEFINE result t_valid_rec
    CALL result.init()

    TRY
        INSERT INTO suppliers (companyname, contactname, ...)
            VALUES (DEFAULT, self.companyname, self.contactname, ...)
        LET self.supplierid = sqlca.sqlerrd[2]
        CALL result.success("Supplier added successfully")
    CATCH
        CALL result.failed(SFMT("Insert failed: %1", SQLCA.SQLERRM))
    END TRY
    RETURN result
END FUNCTION

PUBLIC FUNCTION (self t_supplier) updateRec() RETURNS (t_valid_rec)
    -- UPDATE pattern with TRY/CATCH
END FUNCTION

PUBLIC FUNCTION (self t_supplier) deleteRec() RETURNS (t_valid_rec)
    -- DELETE pattern with TRY/CATCH
END FUNCTION
```

### Key Learnings

- Genero BDL supports method syntax: `FUNCTION (self TYPE_NAME) methodName(...) RETURNS (...)`
- The `self` parameter provides access to the record's fields within the method
- Methods are called with dot notation: `LET result = my_record.validateRec("A")`
- The `mode` parameter distinguishes add ("A") vs edit ("C") for conditional validation
- All CRUD methods return `t_valid_rec` for consistent error handling

---

## Phase 40: Org Chart Report

**Date:** February 19, 2026  
**Commit:** `81f2088`  
**Objective:** Add a corporate organization chart report showing the employee reporting structure.

### Files Created/Modified

- `rpt_org_chart.4gl` — Report logic generating an organization chart from the employees table
- `rpt_org_chart.per` — Criteria form for the report
- `main_rpt_org_chart.4gl` — Main program entry point
- `bdl_menu.4gl` — Added "Corporate Org Chart" menu entry (id=65)
- `main_lib.4gl` — Added `fa-sitemap` icon mapping

### Menu Entry

```
Reports (id=6)
└── Corporate Org Chart (id=65, program=main_rpt_org_chart, icon=fa-sitemap)
```

---

## Phase 41: IMPORT FGL Build Refactoring

**Date:** March 10, 2026 (part of `276eca5` — Major refactoring)  
**Objective:** Refactor the entire build system from fgl2p multi-module linking to IMPORT FGL individual module compilation.

### Before (Guide-era Build)

```makefile
# Each main program linked all dependent modules together
fgl2p -o main_suppliers.42r main_suppliers.4gl main_lib.4gl suppliers.4gl
```

All `.4gl` files were passed to `fgl2p` together. Cross-module function calls were resolved at link time.

### After (Current Build)

```makefile
# Each .4gl compiled individually to a .42m module
MODCOMP = fglcomp -M

MODULE_SOURCES = main_lib.4gl list_view_helper.4gl controller.4gl dispatch.4gl \
                 model_helper.4gl \
                 model_employees.4gl model_empl_terr.4gl model_territories.4gl model_region.4gl \
                 model_orders.4gl model_order_details.4gl model_customers.4gl model_shippers.4gl \
                 model_products.4gl model_suppliers.4gl model_categories.4gl model_usstates.4gl \
                 ui_employees.4gl ui_empl_terr.4gl ui_territories.4gl ui_region.4gl \
                 ui_orders.4gl ui_order_details.4gl ui_customers.4gl ui_shippers.4gl \
                 ui_products.4gl ui_suppliers.4gl ui_categories.4gl ui_usstates.4gl \
                 model_cust_demo.4gl model_cust_cust_demo.4gl \
                 ui_cust_demo.4gl ui_cust_cust_demo.4gl \
                 md_order_details.4gl md_helper.4gl \
                 advsearch_orders.4gl dialog_prompt.4gl \
                 report_helper.4gl \
                 rpt_orders_by_customer.4gl rpt_orders_by_employee.4gl \
                 rpt_orders_by_product.4gl rpt_orders_by_daterange.4gl \
                 rpt_orders_generic.4gl rpt_org_chart.4gl \
                 rpt_products_by_category.4gl rpt_employees_with_totals.4gl \
                 rest_categories.4gl rest_customers.4gl rest_employees.4gl \
                 rest_orders.4gl rest_order_details.4gl rest_products.4gl \
                 rest_suppliers.4gl rest_shippers.4gl rest_region.4gl \
                 rest_territories.4gl rest_usstates.4gl rest_empl_terr.4gl \
                 rest_cust_demo.4gl rest_cust_cust_demo.4gl

# Generic rule: compile any .4gl module to .42m
$(BINDIR)/%.42m: %.4gl
	$(MODCOMP) $<
	mv $*.42m $(BINDIR)/

# Main programs link only themselves; IMPORT FGL resolves deps at runtime
LDPATH = FGLLDPATH=$(BINDIR):$$FGLLDPATH

$(BINDIR)/main_suppliers.42r: main_suppliers.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_suppliers.42r main_suppliers.4gl
	mv main_suppliers.42r main_suppliers.42m $(BINDIR)/
```

### Impact

- **Every `.4gl` file** now has explicit `IMPORT FGL` statements at the top
- Dependencies are resolved at **runtime** via `FGLLDPATH` instead of link-time
- Each module compiles independently — faster incremental builds
- `PUBLIC` keyword required on types and functions that are exported to other modules
- `PRIVATE` keyword used for module-internal symbols

### Key Learnings

- `fglcomp -M` compiles a single `.4gl` to a `.42m` module
- `fgl2p` still creates the `.42r` runner, but only needs the main `.4gl` file
- `FGLLDPATH` tells the runtime where to find imported `.42m` modules
- `IMPORT FGL module_name` replaces link-time resolution with explicit imports
- The generic Makefile rule `$(BINDIR)/%.42m: %.4gl` handles all modules uniformly

---

## Phase 42: Model/UI Layer Separation

**Date:** March 10, 2026 (part of `276eca5`)  
**Objective:** Split every monolithic module `.4gl` file into separate model and UI layers for clean separation of concerns.

### Architecture

| Layer | File Pattern | Responsibility |
|-------|-------------|----------------|
| **Model** | `model_*.4gl` | PUBLIC TYPE definition, validation methods (`validateRec`), CRUD methods (`insertRec`, `updateRec`, `deleteRec`), query/load functions |
| **UI** | `ui_*.4gl` | Form display, CONSTRUCT queries, INPUT dialogs, DISPLAY ARRAY list views, dispatch interface functions (`get_config`, `*_do_query`, `*_do_add`, `*_do_edit`, `*_do_delete`, `*_list_display`, `*_do_command`) |
| **Main** | `main_*.4gl` | Entry point, calls `init_pgm()`, initializes controller with `get_config()`, starts navigation |

### Files Created

**14 model modules:**
- `model_helper.4gl` — Shared `t_valid_rec` type
- `model_categories.4gl`, `model_customers.4gl`, `model_employees.4gl`
- `model_empl_terr.4gl`, `model_orders.4gl`, `model_order_details.4gl`
- `model_products.4gl`, `model_region.4gl`, `model_shippers.4gl`
- `model_suppliers.4gl`, `model_territories.4gl`, `model_usstates.4gl`
- `model_cust_demo.4gl`, `model_cust_cust_demo.4gl`

**14 UI modules:**
- `ui_categories.4gl`, `ui_customers.4gl`, `ui_employees.4gl`
- `ui_empl_terr.4gl`, `ui_orders.4gl`, `ui_order_details.4gl`
- `ui_products.4gl`, `ui_region.4gl`, `ui_shippers.4gl`
- `ui_suppliers.4gl`, `ui_territories.4gl`, `ui_usstates.4gl`
- `ui_cust_demo.4gl`, `ui_cust_cust_demo.4gl`

### Model Layer Pattern

```4gl
-- model_categories.4gl
IMPORT FGL model_helper

SCHEMA northwind

PUBLIC TYPE t_category RECORD
    categoryid   LIKE categories.categoryid,
    categoryname LIKE categories.categoryname,
    description  LIKE categories.description
END RECORD

PUBLIC FUNCTION (self t_category) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
    DEFINE result t_valid_rec
    CALL result.init()
    IF self.categoryname IS NULL OR self.categoryname.getLength() = 0 THEN
        CALL result.failed("Category name is required")
        RETURN result
    END IF
    CALL result.success("Validation passed")
    RETURN result
END FUNCTION

PUBLIC FUNCTION (self t_category) insertRec() RETURNS (t_valid_rec)
    DEFINE result t_valid_rec
    CALL result.init()
    TRY
        INSERT INTO categories (categoryid, categoryname, description)
            VALUES (DEFAULT, self.categoryname, self.description)
        LET self.categoryid = sqlca.sqlerrd[2]
        CALL result.success("Category added successfully")
    CATCH
        CALL result.failed(SFMT("Insert failed: %1", SQLCA.SQLERRM))
    END TRY
    RETURN result
END FUNCTION
```

### UI Layer Pattern

```4gl
-- ui_categories.4gl
IMPORT FGL controller
IMPORT FGL list_view_helper
IMPORT FGL model_helper
IMPORT FGL model_categories
IMPORT FGL dialog_prompt

SCHEMA northwind

PRIVATE DEFINE categories_arr DYNAMIC ARRAY OF model_categories.t_category
PRIVATE DEFINE curr_category model_categories.t_category

PUBLIC FUNCTION categories_get_config() RETURNS (t_controller_config)
    DEFINE cfg t_controller_config
    LET cfg.moduleName   = "categories"
    LET cfg.formName     = "categories"
    LET cfg.listFormName = "categories_list"
    LET cfg.windowTitle  = "Category Maintenance"
    LET cfg.hasModify    = TRUE
    LET cfg.hasQuery     = TRUE
    LET cfg.entityName   = "Category"
    CALL categories_init_view_commands(cfg)
    RETURN cfg
END FUNCTION

PUBLIC FUNCTION categories_do_query() RETURNS INTEGER
    -- CONSTRUCT, load, return count
END FUNCTION

PUBLIC FUNCTION categories_do_add()
    -- INPUT BY NAME with validation
END FUNCTION
```

### Benefits

- **Separation of concerns** — Business logic (model) is independent of UI
- **Reusability** — REST services reuse model types and validation
- **Testability** — Model methods can be tested independently
- **Consistency** — All modules follow the same three-layer structure

---

## Phase 43: Model Helper — Validation Result Type

**Date:** March 10, 2026 (part of `276eca5`)  
**Objective:** Create a shared validation result type used by all model methods.

### File Created

**`model_helper.4gl`:**

```4gl
PUBLIC TYPE t_valid_rec RECORD
   valid_status BOOLEAN,
   valid_msg STRING
END RECORD

PUBLIC FUNCTION (self t_valid_rec) init() RETURNS ()
   LET self.valid_status = FALSE
   LET self.valid_msg = ""
END FUNCTION

PUBLIC FUNCTION (self t_valid_rec) success(msg STRING) RETURNS ()
   LET self.valid_status = TRUE
   LET self.valid_msg = msg
END FUNCTION

PUBLIC FUNCTION (self t_valid_rec) failed(msg STRING) RETURNS ()
   LET self.valid_status = FALSE
   LET self.valid_msg = msg
END FUNCTION
```

### Usage

```4gl
DEFINE result model_helper.t_valid_rec
LET result = my_record.validateRec("A")
IF NOT result.valid_status THEN
    ERROR result.valid_msg
    RETURN
END IF
```

---

## Phase 44: Customer Demographics Modules

**Date:** March 10, 2026 (part of `276eca5`)  
**Objective:** Add two new modules for managing customer demographics — a lookup table and a junction table.

### Module 1: Customer Demographics (cust_demo)

**Files Created:**
- `model_cust_demo.4gl` — `t_cust_demo` type with `validateRec`, `insertRec`, `updateRec`, `deleteRec`
- `ui_cust_demo.4gl` — Dispatch interface, query, add, edit, delete, list display
- `main_cust_demo.4gl` — Entry point with controller
- `cust_demo.per` — Detail form
- `cust_demo_list.per` — List form

**Record Type:**
```4gl
PUBLIC TYPE t_cust_demo RECORD
    customertypeid LIKE customerdemographics.customertypeid,
    customerdesc   LIKE customerdemographics.customerdesc
END RECORD
```

### Module 2: Customer-Customer Demographics (cust_cust_demo)

**Files Created:**
- `model_cust_cust_demo.4gl` — `t_cust_cust_demo` type with custom validation methods
- `ui_cust_cust_demo.4gl` — Dispatch interface with zoom lookups
- `main_cust_cust_demo.4gl` — Entry point with controller
- `cust_cust_demo.per` — Detail form with BUTTONEDIT zoom for customer and type
- `cust_cust_demo_list.per` — List form

**Record Type:**
```4gl
PUBLIC TYPE t_cust_cust_demo RECORD
    customerid     LIKE customercustomerdemo.customerid,
    companyname    LIKE customers.companyname,
    customertypeid LIKE customercustomerdemo.customertypeid,
    customerdesc   LIKE customerdemographics.customerdesc
END RECORD
```

**Custom Validation Methods:**
- `validateCustomer()` — Validates customerid exists in customers table
- `validateCustomerType()` — Validates customertypeid exists in customerdemographics table

---

## Phase 45: Dialog Prompt Utility

**Date:** March 10, 2026 (part of `276eca5`)  
**Objective:** Create a standalone, IMPORT FGL-compatible delete confirmation dialog.

### File Created

**`dialog_prompt.4gl`:**

```4gl
PUBLIC FUNCTION delete_prompt() RETURNS (BOOLEAN)
   VAR do_delete = FALSE
   MENU "Delete Confirmation"
      ATTRIBUTES(COMMENT="Are you sure you want to delete this record?", STYLE="dialog")
      COMMAND "Yes"
         LET do_delete = TRUE
         EXIT MENU
      COMMAND "No"
         EXIT MENU
   END MENU
   RETURN do_delete
END FUNCTION
```

### Purpose

Supplements the `confirm_delete()` function in `main_lib.4gl`. The `dialog_prompt` module uses modern `VAR` syntax and `RETURNS (BOOLEAN)` typed return. Being a standalone module with `PUBLIC FUNCTION`, it can be cleanly imported via `IMPORT FGL dialog_prompt`.

---

## Phase 46: REST Web Services

**Date:** March 10, 2026 (part of `276eca5`)  
**Objective:** Create a complete REST API layer for all 14 data modules.

### Server

**`main_rest_server.4gl`:**
- Registers 14 REST service modules via `com.WebServiceEngine.RegisterRestService()`
- Runs event loop with `com.WebServiceEngine.ProcessServices(-1)`

### REST Module Pattern

Each `rest_*.4gl` implements standard CRUD endpoints:

```4gl
-- rest_categories.4gl
IMPORT FGL model_categories
IMPORT FGL model_helper

PUBLIC FUNCTION getAll()
    ATTRIBUTES(WSGet, WSPath="/categories", WSMedia="application/json",
               WSDescription="Get all categories")
    RETURNS DYNAMIC ARRAY OF model_categories.t_category
    -- SELECT all categories, return array
END FUNCTION

PUBLIC FUNCTION getById(p_categoryid INTEGER
    ATTRIBUTES(WSParam))
    ATTRIBUTES(WSGet, WSPath="/categories/{p_categoryid}",
               WSMedia="application/json",
               WSThrows="404:Not Found")
    RETURNS model_categories.t_category
    -- SELECT by ID, return record or WSError 404
END FUNCTION

PUBLIC FUNCTION create(p_rec model_categories.t_category)
    ATTRIBUTES(WSPost, WSPath="/categories", WSMedia="application/json",
               WSThrows="400:Bad Request")
    RETURNS model_categories.t_category
    -- validateRec, insertRec, return created record
END FUNCTION
```

### REST Modules Created (14 total)

| Module | Path Prefix | Operations |
|--------|-------------|------------|
| `rest_categories.4gl` | `/categories` | GET all, GET by ID, POST |
| `rest_customers.4gl` | `/customers` | GET all, GET by ID, POST |
| `rest_employees.4gl` | `/employees` | GET all, GET by ID, POST |
| `rest_orders.4gl` | `/orders` | GET all, GET by ID, POST |
| `rest_order_details.4gl` | `/order_details` | GET all, GET by ID, POST |
| `rest_products.4gl` | `/products` | GET all, GET by ID, POST |
| `rest_suppliers.4gl` | `/suppliers` | GET all, GET by ID, POST |
| `rest_shippers.4gl` | `/shippers` | GET all, GET by ID, POST |
| `rest_region.4gl` | `/region` | GET all, GET by ID, POST |
| `rest_territories.4gl` | `/territories` | GET all, GET by ID, POST |
| `rest_usstates.4gl` | `/usstates` | GET all, GET by ID, POST |
| `rest_empl_terr.4gl` | `/empl_terr` | GET all, GET by ID, POST |
| `rest_cust_demo.4gl` | `/cust_demo` | GET all, GET by ID, POST |
| `rest_cust_cust_demo.4gl` | `/cust_cust_demo` | GET all, GET by ID, POST |

### Key Features

- **Reuses model layer** — REST modules import `model_*.4gl` types and validation methods
- **JSON media type** — All endpoints use `WSMedia="application/json"`
- **Error handling** — Uses `WSThrows` for HTTP error codes (400, 404)
- **Validation** — POST operations call `validateRec()` before inserting

---

## Phase 47: Advanced Order Search

**Date:** March 10, 2026 (part of `276eca5`)  
**Objective:** Create a multi-field CONSTRUCT search for orders with customer and employee joins.

### Files Created

- `advsearch_orders.4gl` — Advanced search module
- `advsearch_orders.per` — Multi-field search form

### Implementation

```4gl
PUBLIC FUNCTION advsearch_orders() RETURNS (STRING)
    DEFINE where_clause STRING

    OPEN WINDOW w_advsearch WITH FORM "advsearch_orders"
        ATTRIBUTES(STYLE="modulewindow")

    CONSTRUCT where_clause
        ON orders.orderid, orders.customerid, customers.companyname,
           orders.employeeid, employees.firstname, employees.lastname,
           orders.orderdate, orders.requireddate, orders.shippeddate, ...
        FROM s_advsearch.*

        ON ACTION accept
            ACCEPT CONSTRUCT
        ON ACTION exit
            EXIT CONSTRUCT
    END CONSTRUCT

    CLOSE WINDOW w_advsearch
    RETURN where_clause
END FUNCTION
```

### New Action Default

```xml
<ActionDefault name="adv_search"
    text="Advanced Search"
    image="fa-search-plus"
    comment="Open advanced search dialog" />
```

---

## Phase 48: Master-Detail Order Entry

**Date:** March 11, 2026  
**Commit:** `1c3cfa2`  
**Objective:** Create a master-detail order entry program combining order header with line items.

### Files

- `mstr_dtl_order.4gl` — Main program entry point
- `md_order_details.4gl` — Master-detail logic with `mstr_detail_orders()` function
- `mstr_order_list.per` — Order list form with search and table display

### Entry Point

```4gl
-- mstr_dtl_order.4gl
IMPORT FGL main_lib
IMPORT FGL md_order_details
DATABASE northwind

MAIN
    CALL init_pgm()
    CALL mstr_detail_orders()
END MAIN
```

### Architecture

The `mstr_detail_orders()` function uses a DIALOG combining CONSTRUCT (search) and DISPLAY ARRAY (results):

```4gl
OPEN WINDOW mainWindow WITH FORM "mstr_order_list"
    ATTRIBUTES(STYLE="noaction")

DIALOG ATTRIBUTES(UNBUFFERED)
    CONSTRUCT where_clause
        ON orders.orderid, orders.orderdate
        FROM s_search.orderid, s_search.orderdate
    END CONSTRUCT

    DISPLAY ARRAY order_result_list TO s_table.*
    END DISPLAY

    ON ACTION search     -- Basic search
    ON ACTION adv_search -- Advanced search dialog
    ON ACTION ADD        -- Add new order with details
    ON ACTION MODIFY     -- Edit existing order
    ON ACTION delete     -- Delete order
    ON ACTION VIEW       -- View order details
END DIALOG
```

### Key Features

- Combined search + results in a single DIALOG
- Action-based routing with constants from `md_helper.4gl`
- DICTIONARY-based caching of order headers and detail lines
- Supports basic search, advanced search, add, edit, view, and delete

---

## Phase 49: MD Helper Constants

**Date:** March 10, 2026 (part of `276eca5`)  
**Objective:** Define constants for master-detail action routing and icon references.

### File Created

**`md_helper.4gl`:**

```4gl
PUBLIC CONSTANT cQuit = 0
PUBLIC CONSTANT cSearch = 1
PUBLIC CONSTANT cAdd = 2
PUBLIC CONSTANT cEdit = 3
PUBLIC CONSTANT cDelete = 4
PUBLIC CONSTANT cView = 5
PUBLIC CONSTANT cAdvSearch = 6

PUBLIC CONSTANT cViewImage = "fa-eye"
PUBLIC CONSTANT cEditImage = "fa-pencil"
PUBLIC CONSTANT cDeleteImage = "fa-trash"
```

---

## Phase 50: Cross-Module View Commands

**Date:** February 18 – March 10, 2026  
**Objective:** Enable context-sensitive navigation between related modules via dynamic toolbar buttons.

### Pattern

Each ui module defines its available view commands:

```4gl
-- ui_suppliers.4gl
PRIVATE FUNCTION suppliers_init_view_commands(cfg t_controller_config INOUT)
    CALL cfg.availableCommands.clear()
    CALL cfg.availableCommands.appendElement()
    LET cfg.availableCommands[cfg.availableCommands.getLength()].commandName    = "cmd_products"
    LET cfg.availableCommands[cfg.availableCommands.getLength()].commandLabel   = "Products"
    LET cfg.availableCommands[cfg.availableCommands.getLength()].commandComment = "View products for this supplier"
END FUNCTION

PUBLIC FUNCTION suppliers_do_command(commandName STRING)
    CASE commandName
        WHEN "cmd_products"
            -- Navigate to products filtered by current supplier
    END CASE
END FUNCTION
```

### Examples of View Commands

| From Module | Command | Navigates To |
|-------------|---------|-------------|
| suppliers | `cmd_products` | Products filtered by supplier |
| orders | `cmd_customer` | Customer record for this order |
| orders | `cmd_employee` | Employee record for this order |
| orders | `cmd_details` | Order details for this order |
| cust_demo | `cmd_cust_cust_demo` | Customer type assignments |

The controller dynamically shows/hides these action buttons based on the current module's `availableCommands` array.

---

## Phase 51: New Action Defaults and Styles

**Date:** Various (Feb 17 – Mar 10, 2026)  
**Objective:** Add action defaults and styles needed by new features.

### New Actions Added to generic.4ad

| Action | Icon | Purpose |
|--------|------|---------|
| `search` | `fa-search` | Search (list context) |
| `adv_search` | `fa-search-plus` | Advanced Search |
| `excel_export` | `fa-file-excel-o` | Export to Excel |
| `append` | `fa-plus-square` | Add Item (detail rows) |
| `view` | `fa-eye` | View current record |
| `close` | `fa-window-close` | Close screen |
| `cust_cust_demo` | `fa-tags` | Customer type assignments |
| `zoom_cust_type` | `zoom` | Look up customer type |
| `to_pdf` | `fa-file-pdf-o` | Export to PDF |

### New Styles Added to generic.4st

| Style | Purpose |
|-------|---------|
| `Window.dialog` | Modal dialog with bottom action panel |
| `Window.noaction` | Explicit no-action style |
| `Table.MenuTree` | bdl_menu tree table (alternateRows=no, rowHover, singleClick) |
| `Label.info` | Dark blue, large font label |
| `form`, `formField`, `label`, `button`, `toolBar` | Base form-level styling |

---

## Phase 52: Menu Expansion

**Date:** Various (Feb 17 – Mar 11, 2026)  
**Objective:** Expand the bdl_menu tree with new modules and programs.

### New Menu Entries Added

| ID | Parent | Menu Name | Program | Icon |
|----|--------|-----------|---------|------|
| 21 | 2 | Customer Demographics | `main_cust_demo` | `fa-id-badge` |
| 22 | 2 | Customer Type Assignments | `main_cust_cust_demo` | `fa-tags` |
| 33 | 3 | Order Entry (Master-Detail) | `mstr_dtl_order` | `fa-clipboard` |
| 64 | 6 | Generic Orders (XML) | `main_rpt_orders_generic` | `fa-file-text` |
| 65 | 6 | Corporate Org Chart | `main_rpt_org_chart` | `fa-sitemap` |
| 66 | 6 | Products by Category | `main_rpt_products_by_category` | `fa-bar-chart` |
| 67 | 6 | Employees with Order Totals | `main_rpt_employees_with_totals` | `fa-bar-chart` |

### Updated Menu Totals

- **7 root categories** (Employee, Customer, Order, Product, Reference, Reports)
- **23 leaf programs** (up from 16 in the original guide)

---

## Phase 53: Makefile Cleanup

**Date:** March 11, 2026  
**Commit:** `1c3cfa2`  
**Objective:** Remove phantom file references and add missing convenience targets.

### Changes

**Removed phantom references** from `hrm/src/Makefile`:
- `md_orders.per` — form file that was never created
- `md_orders.4gl` — module source that was never created  
- `main_md_orders.4gl` — main program that was never created

These were leftover references from an earlier design that was replaced by the `mstr_dtl_order` / `md_order_details` approach.

**Added `mstr_dtl_order` convenience targets** to parent Makefiles:
- `Makefile` (root) — delegates to `hrm/`
- `hrm/Makefile` — delegates to `src/`

**Removed phantom menu entry:**
- `bdl_menu.4gl` — Removed id=33 entry for non-existent `main_md_orders`, consolidated `mstr_dtl_order` as id=33

---

## Phase 54: REST API Test Suite

**Date:** March 16, 2026  
**Objective:** Create a comprehensive REST API test suite covering all 14 REST service modules with database cross-validation.

### Files Created

**1 shared test library:**
- `test_rest_lib.4gl` — HTTP helper functions (`http_get`, `http_post`, `http_put`, `http_delete`), test result tracking (`test_pass`, `test_fail`), and summary reporting (`test_summary`)

**14 test programs:**
- `test_rest_shippers.4gl` — 11 tests (full CRUD + validation + duplicates)
- `test_rest_categories.4gl` — 10 tests
- `test_rest_suppliers.4gl` — 10 tests
- `test_rest_region.4gl` — 10 tests
- `test_rest_usstates.4gl` — 10 tests
- `test_rest_products.4gl` — 10 tests
- `test_rest_customers.4gl` — 10 tests
- `test_rest_territories.4gl` — 10 tests
- `test_rest_employees.4gl` — 10 tests
- `test_rest_orders.4gl` — 10 tests
- `test_rest_order_details.4gl` — 10 tests (creates temp orders for FK references)
- `test_rest_cust_demo.4gl` — 10 tests
- `test_rest_empl_terr.4gl` — 10 tests (creates temp territories for FK references)
- `test_rest_cust_cust_demo.4gl` — 10 tests (creates temp customer demographics for FK references)

### Test Pattern

Each test program follows a consistent pattern:

```4gl
-- test_rest_suppliers.4gl
IMPORT FGL test_rest_lib

SCHEMA northwind

DEFINE m_base_url STRING

TYPE t_supplier RECORD
    supplierid   STRING,
    companyname  STRING,
    contactname  STRING,
    -- ... all fields as STRING
END RECORD

MAIN
    DATABASE northwind
    LET m_base_url = "http://localhost:8899/sup/suppliers"

    CALL test_rest_lib.test_init("REST Suppliers Service Test Suite", m_base_url)

    CALL test_get_all()
    CALL test_get_by_id()
    CALL test_get_not_found()
    CALL test_create()
    CALL test_update()
    CALL test_delete()
    CALL test_lifecycle()
    CALL test_update_not_found()
    CALL test_delete_not_found()
    CALL test_create_invalid()

    CALL test_rest_lib.test_summary()
END MAIN
```

### Test Coverage Per Module

Each test program validates:
1. **GET all** — Returns records, count matches database `SELECT COUNT(*)`
2. **GET by ID** — Returns correct record, fields match direct SQL query
3. **GET not found** — Returns 404 for non-existent ID
4. **POST create** — Creates record, verifies via GET and database SELECT, cleans up
5. **PUT update** — Creates record, updates it, verifies changes in database, cleans up
6. **DELETE** — Creates record, deletes it, verifies 404 and database absence
7. **Full CRUD lifecycle** — Create → Read → Update → Read → Delete → Verify gone, with database checks at each step
8. **Update not found** — PUT to non-existent ID returns 400/404
9. **Delete not found** — DELETE of non-existent ID returns 404
10. **Create invalid** — POST with missing required fields returns 400

Junction tables (empl_terr, cust_cust_demo) test create/delete only (no update endpoint) plus duplicate detection.

### Shared Test Library

```4gl
-- test_rest_lib.4gl
PUBLIC FUNCTION test_init(suite_name STRING, base_url STRING)
PUBLIC FUNCTION test_pass(msg STRING)
PUBLIC FUNCTION test_fail(msg STRING)
PUBLIC FUNCTION test_summary()
PUBLIC FUNCTION http_get(url STRING) RETURNS (INTEGER, STRING)
PUBLIC FUNCTION http_post(url STRING, body STRING) RETURNS (INTEGER, STRING)
PUBLIC FUNCTION http_put(url STRING, body STRING) RETURNS (INTEGER, STRING)
PUBLIC FUNCTION http_delete(url STRING) RETURNS (INTEGER, STRING)
```

HTTP functions use `com.HttpRequest` / `com.HttpResponse` with JSON content type. Each returns the HTTP status code and response body.

### Build and Run

```bash
# Build all test programs
cd hrm/src
make test_rest

# Build individual test
make test_rest_suppliers

# Run (requires REST server running on port 8899)
cd ../../bin
FGL_LENGTH_SEMANTICS=CHAR FGLPROFILE=<path>/fglprofile.pgs FGLGUI=0 fglrun test_rest_suppliers.42m
```

Makefile targets: `test_rest` (builds all 14), plus individual targets (`test_rest_shippers`, `test_rest_categories`, etc.).

### Key Technical Discoveries

1. **`util.JSON.stringify()` bug with STRING records** — When all record fields are declared as `STRING`, `util.JSON.stringify()` sends `""` (empty string) for unset fields. The REST server cannot deserialize `""` into `DATE`, `INTEGER`, or `DECIMAL` model types, returning 400 errors. **Solution:** Use hand-crafted JSON string literals with proper types (unquoted numbers, only populated fields) for create and update operations.

2. **`ord` is a reserved word** — Genero BDL has a built-in `ORD()` function. Using `ord` as a variable name causes compilation errors. Renamed to `l_order`.

3. **Test isolation** — Each test creates its own data, verifies it against both REST responses and direct database queries, and cleans up afterwards. Junction table tests (order_details, empl_terr, cust_cust_demo) create temporary parent records via the REST API before testing.

### Final Results

| Test Program | Tests | Status |
|-------------|-------|---------|
| test_rest_shippers | 11 | PASS |
| test_rest_categories | 10 | PASS |
| test_rest_suppliers | 10 | PASS |
| test_rest_region | 10 | PASS |
| test_rest_usstates | 10 | PASS |
| test_rest_products | 10 | PASS |
| test_rest_customers | 10 | PASS |
| test_rest_territories | 10 | PASS |
| test_rest_employees | 10 | PASS |
| test_rest_orders | 10 | PASS |
| test_rest_order_details | 10 | PASS |
| test_rest_cust_demo | 10 | PASS |
| test_rest_empl_terr | 10 | PASS |
| test_rest_cust_cust_demo | 10 | PASS |
| **Total** | **141** | **ALL PASS** |

---

## New File Inventory

### Summary by Category

| Category | Count | Files |
|----------|-------|-------|
| Model layer (`model_*.4gl`) | 15 | model_helper + 14 entity modules |
| UI layer (`ui_*.4gl`) | 14 | All 12 original + cust_demo + cust_cust_demo |
| Controller/Dispatch | 2 | controller.4gl, dispatch.4gl |
| List view helper | 1 | list_view_helper.4gl |
| Dialog prompt | 1 | dialog_prompt.4gl |
| List forms (`*_list.per`) | 13 | All modules |
| REST services | 14 | rest_*.4gl for all modules |
| REST server | 1 | main_rest_server.4gl |
| REST test library | 1 | test_rest_lib.4gl |
| REST test programs | 14 | test_rest_*.4gl for all modules |
| Advanced search | 2 | advsearch_orders.4gl, advsearch_orders.per |
| Master-detail | 2 | mstr_dtl_order.4gl, mstr_order_list.per |
| MD helper | 1 | md_helper.4gl |
| New main programs | 2 | main_cust_demo.4gl, main_cust_cust_demo.4gl |
| New detail forms | 2 | cust_demo.per, cust_cust_demo.per |
| Documentation | 1 | LIST_VIEW_FEATURE.md |
| **Total new files** | **~86** | |

---

## Architecture Summary

### Before (Guide-era — Phases 1-35)

```
main_*.4gl ──► monolithic_module.4gl ──► database
     │
     └── fgl2p links all .4gl files together
```

- Single-file modules containing types, SQL, validation, and UI
- `fgl2p` multi-module linking
- Navigation code duplicated in every module
- No REST API layer
- No list views (except suppliers)

### After (Current — Phases 36-53)

```
main_*.4gl
    │
    ├── IMPORT FGL controller    ◄── Generic CRUD navigation
    ├── IMPORT FGL dispatch      ◄── Routes to correct module
    ├── IMPORT FGL ui_*          ◄── UI: forms, dialogs, lists
    │       │
    │       ├── IMPORT FGL model_*     ◄── Types, validation, CRUD
    │       │       │
    │       │       └── IMPORT FGL model_helper  ◄── t_valid_rec
    │       │
    │       ├── IMPORT FGL list_view_helper  ◄── Action constants
    │       └── IMPORT FGL dialog_prompt     ◄── Delete confirmation
    │
    └── fglcomp -M individual compilation
        fgl2p links only the main file

rest_*.4gl ──► IMPORT FGL model_*  ◄── Reuses same model types/validation
    │
    └── main_rest_server.4gl  ◄── Registers all 14 REST services
```

- **Three-layer architecture**: Model → UI → Main
- **IMPORT FGL** with individual `fglcomp -M` compilation
- **Controller/Dispatch pattern** eliminates navigation duplication
- **Record type methods** (`validateRec`, `insertRec`, `updateRec`, `deleteRec`)
- **Validation result type** (`t_valid_rec`) for consistent error handling
- **REST API layer** reusing model types and validation
- **REST API test suite** — 14 test programs, 141 tests, all passing
- **List views** for all 14 modules
- **Cross-module view commands** for context-sensitive navigation
- **Master-detail order entry** with combined search/results DIALOG
- **Advanced search** with multi-field CONSTRUCT
