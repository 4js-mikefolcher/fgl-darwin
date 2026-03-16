# fgl-darwin

Genero Darwin Project — A demonstration application showing how to evolve an Informix 4GL application into a modern web-ready application using Genero BDL (Business Development Language).

## Overview

This project is built on the Northwind database schema and provides CRUD (Create, Read, Update, Delete) functionality for managing business data including employees, customers, orders, products, and more. It also includes report modules that generate text-based reports with flexible query criteria.

The application has been modernized with:
- Dynamic arrays replacing static `ARRAY[n]` declarations
- Modern form layouts with `VBOX`, `GROUP`, `GRID`, and `TABLE` containers
- Professional toolbars with Font Awesome icons
- Centralized action definitions (`generic.4ad`) and stylesheets (`generic.4st`)
- `COMBOBOX`, `CHECKBOX`, `BUTTONEDIT`, `DATEEDIT`, and `TEXTEDIT` form controls
- `CONSTRUCT BY NAME` for flexible report criteria
- A reusable report viewer with modal dialog display
- `ON ACTION` pattern replacing legacy `ON KEY` handlers — zero `ON KEY` statements remain
- `BUTTONEDIT` with `ON ACTION zoom_*` for foreign key lookups (customer, employee, order, product)
- PostgreSQL `SERIAL` columns with `INSERT ... VALUES (DEFAULT, ...)` and `sqlca.sqlerrd[2]` for auto-generated IDs
- Form initializer hook for automatic action defaults loading
- Module window style — secondary windows open as modal dialogs via `STYLE="modulewindow"`
- Three-layer architecture: Model (`model_*.4gl`) → UI (`ui_*.4gl`) → Main (`main_*.4gl`)
- `IMPORT FGL` with individual `fglcomp -M` compilation replacing `fgl2p` multi-module linking
- Controller/Dispatch pattern centralizing CRUD navigation across all modules
- Record type methods (`validateRec`, `insertRec`, `updateRec`, `deleteRec`) with `t_valid_rec` result type
- REST web services for all 14 data modules via `main_rest_server.4gl`
- Comprehensive REST API test suite — 14 test programs, 141 tests, all passing
- Master-detail order entry with combined search/results DIALOG
- Cross-module view commands for context-sensitive navigation

## Project Structure

```
fgl-darwin/
├── dbs/
│   ├── northwind.4db                 # Database definition
│   ├── northwind.sch                 # Database schema
│   ├── northwind_pgs_84x.4gl        # PostgreSQL database creation script
│   ├── informix/
│   │   └── northwind.informix.sql    # Informix SQL schema
│   └── postgres/
│       ├── createdb.txt              # PostgreSQL setup instructions
│       └── fglprofile.pgs            # PostgreSQL FGLPROFILE
├── bin/                               # Compiled output (.42f, .42m, .42r)
├── hrm/
│   ├── bin/                          # Legacy compiled output (symlink or copy)
│   ├── src/                          # Source code
│   │   ├── Makefile                  # Build configuration
│   │   ├── generic.4ad               # Shared action defaults (36 actions)
│   │   ├── generic.4st               # Shared stylesheet
│   │   ├── main_lib.4gl              # Common library (init, utilities)
│   │   ├── report_helper.4gl         # Report viewer utility
│   │   ├── report_viewer.per         # Report viewer form (modal dialog)
│   │   ├── model_*.4gl               # Model layer (types, validation, CRUD)
│   │   ├── ui_*.4gl                  # UI layer (forms, dialogs, dispatch)
│   │   ├── main_<entity>.4gl         # Entry point per entity
│   │   ├── controller.4gl            # Generic CRUD navigation controller
│   │   ├── dispatch.4gl              # Central routing for all modules
│   │   ├── rest_*.4gl                # REST web service endpoints (14 modules)
│   │   ├── main_rest_server.4gl      # REST server entry point
│   │   ├── test_rest_lib.4gl         # Shared REST test library (HTTP helpers)
│   │   ├── test_rest_*.4gl           # REST API test programs (14 modules)
│   │   ├── rpt_<report>.4gl          # Report logic
│   │   ├── rpt_<report>.per          # Report criteria form
│   │   └── main_rpt_<report>.4gl     # Report entry point
│   └── Makefile                      # Root build file (delegates to src/)
├── fgl-darwin.4pw                    # Genero Studio project file
├── northwind.sch                     # Schema reference
├── GENERO_MODERNIZATION_GUIDE.md     # Detailed modernization documentation
└── README.md
```

## Modules

### Data Management Modules

| Module | Description | Key Controls |
|--------|-------------|--------------|
| `categories` | Product category management | TEXTEDIT for description |
| `customers` | Customer management | 11 fields, CHAR-based ID |
| `suppliers` | Supplier management | 12 fields including homepage |
| `products` | Product catalog | COMBOBOX (supplier/category), CHECKBOX (discontinued) |
| `shippers` | Shipping company management | Simple 3-field module |
| `usstates` | US States reference data | 4 fields |
| `employees` | Employee management | COMBOBOX (courtesy), DATEEDIT (dates), BUTTONEDIT (reportsto), TEXTEDIT (notes) |
| `territories` | Territory management | COMBOBOX (region) |
| `region` | Region management | Simple 2-field module |
| `empl_terr` | Employee-Territory relationships | TABLE container, BUTTONEDIT lookups |
| `orders` | Order management | BUTTONEDIT (customer/employee), COMBOBOX (shipvia), DATEEDIT (dates) |
| `order_details` | Order line items | BUTTONEDIT (order/product) |

### Report Modules

| Module | Description | Criteria Fields |
|--------|-------------|-----------------|
| `rpt_orders_by_customer` | Orders grouped by customer | Customer ID, company name |
| `rpt_orders_by_employee` | Orders grouped by employee | Employee ID, last name, first name |
| `rpt_orders_by_product` | Orders grouped by product/category | Category name, product name |
| `rpt_orders_by_daterange` | Orders within a date range | Order date (DATEEDIT) |

### Reports

| Module | Description |
|--------|-------------|
| `rpt_orders_generic` | Generic order report |
| `rpt_orders_by_customer` | Orders grouped by customer |
| `rpt_orders_by_employee` | Orders grouped by employee |
| `rpt_orders_by_product` | Orders grouped by product |
| `rpt_orders_by_daterange` | Orders filtered by date range |

### GUI Menu

| Module | Description |
|--------|-------------|
| `bdl_menu` | GUI tree menu with toolbar, 6 root categories, 16 leaf programs |
| `ifx_menu` | Legacy Informix-style character menu |

## Features

### CRUD Operations
Each data management module provides:
- **Query** — Search records using query-by-example (CONSTRUCT)
- **Add** — Create new records (serial primary keys use `INSERT ... DEFAULT` with `sqlca.sqlerrd[2]`)
- **Modify** — Edit existing records
- **Delete** — Remove records with dialog confirmation

### Navigation Controls
- **First / Previous / Next / Last** — Navigate through result sets
- **Cross-module navigation** — View related records (e.g., products for a supplier)

### Modern Form Controls
- **COMBOBOX** — Drop-down selection for foreign keys (supplier, category, region, courtesy title, ship via)
- **CHECKBOX** — Boolean fields (discontinued)
- **BUTTONEDIT** — Lookup/zoom buttons for foreign key fields (employee, territory, customer, product, order)
- **DATEEDIT** — Date picker for date fields (birthdate, hiredate, orderdate, etc.)
- **TEXTEDIT** — Multi-line scrollable text (notes, description)

### REST Web Services

A complete REST API layer serves all 14 data modules via `main_rest_server.4gl`, which registers each service and runs the event loop on port 8899.

| Module | Path Prefix | Endpoints |
|--------|-------------|----------|
| Categories | `/cat/categories` | GET all, GET by ID, POST, PUT, DELETE |
| Customers | `/cust/customers` | GET all, GET by ID, POST, PUT, DELETE |
| Employees | `/emp/employees` | GET all, GET by ID, POST, PUT, DELETE |
| Orders | `/ord/orders` | GET all, GET by ID, POST, PUT, DELETE |
| Order Details | `/odtl/order-details` | GET all, GET by ID, GET by order, POST, PUT, DELETE |
| Products | `/prod/products` | GET all, GET by ID, POST, PUT, DELETE |
| Suppliers | `/sup/suppliers` | GET all, GET by ID, POST, PUT, DELETE |
| Shippers | `/ship/shippers` | GET all, GET by ID, POST, PUT, DELETE |
| Region | `/regn/regions` | GET all, GET by ID, POST, PUT, DELETE |
| Territories | `/terr/territories` | GET all, GET by ID, POST, PUT, DELETE |
| US States | `/st/usstates` | GET all, GET by ID, POST, PUT, DELETE |
| Employee Territories | `/empt/employee-territories` | GET all, GET by ID, GET by employee, POST, DELETE |
| Customer Demographics | `/demo/customer-demographics` | GET all, GET by ID, POST, PUT, DELETE |
| Customer-Customer Demo | `/cust_demo/customer-customer-demo` | GET all, GET by ID, GET by customer, POST, DELETE |

### REST API Test Suite

14 independent test programs validate every REST endpoint with database cross-checks. Each test program creates, verifies, and cleans up test data.

| Test Program | Tests | Status |
|-------------|-------|---------|
| `test_rest_shippers` | 11 | PASS |
| `test_rest_categories` | 10 | PASS |
| `test_rest_suppliers` | 10 | PASS |
| `test_rest_region` | 10 | PASS |
| `test_rest_usstates` | 10 | PASS |
| `test_rest_products` | 10 | PASS |
| `test_rest_customers` | 10 | PASS |
| `test_rest_territories` | 10 | PASS |
| `test_rest_employees` | 10 | PASS |
| `test_rest_orders` | 10 | PASS |
| `test_rest_order_details` | 10 | PASS |
| `test_rest_cust_demo` | 10 | PASS |
| `test_rest_empl_terr` | 10 | PASS |
| `test_rest_cust_cust_demo` | 10 | PASS |
| **Total** | **141** | **ALL PASS** |

Each test covers: GET all (with DB count validation), GET by ID (with DB cross-check), GET not found (404), POST create (with DB verification and cleanup), PUT update (with DB verification and cleanup), DELETE (with DB verification), full CRUD lifecycle, error cases (duplicate, missing required fields, not-found update/delete).

```bash
# Run the REST server
cd bin
FGL_LENGTH_SEMANTICS=CHAR FGLPROFILE=<path>/fglprofile.pgs fglrun main_rest_server.42m &

# Run all REST tests
cd hrm/src
make test_rest

# Run individual test
cd bin
FGL_LENGTH_SEMANTICS=CHAR FGLPROFILE=<path>/fglprofile.pgs FGLGUI=0 fglrun test_rest_suppliers.42m
```

### Reports
- **Flexible criteria** — CONSTRUCT BY NAME generates WHERE clauses from user input
- **Text file output** — Reports written to timestamped text files via the REPORT engine
- **Report viewer** — Modal dialog displays report output in a monospace table with no row highlighting
- **Run action** — Dedicated "Run Report" toolbar button (fa-play icon)

### Shared Infrastructure

| File | Purpose |
|------|---------|
| `generic.4ad` | 36 action defaults with Font Awesome icons and accelerator keys |
| `generic.4st` | Stylesheet with `Window.modulewindow` (modal, no actions/ring), `Window.reportviewer` (modal, bottom actions), `Table.reportviewer`, `Table.MenuTree`, and base `form`/`formField`/`label`/`button`/`toolBar` styles |
| `main_lib.4gl` | `init_pgm()` — loads styles and registers form initializer; `confirm_delete()` — dialog-based deletion; `generate_temp_filename()` — unique timestamped filenames; `form_initializer()` — auto-loads action defaults for every form |
| `report_helper.4gl` | `display_report_file()` — reads text file via `base.Channel` and displays in DISPLAY ARRAY |
| `report_viewer.per` | Modal form with TABLE, monospace font, STRETCHCOLUMNS |

### Toolbar Actions (generic.4ad)

| Category | Actions |
|----------|---------|
| Navigation | first, previous, next, last |
| Data Operations | query, add, modify, delete |
| Related Entities | products, orders, supplier, category, region, employees, territories, customer, employee, shipper, details, reportsto, order, product, select |
| Zoom/Lookup | zoom_employee, zoom_territory, zoom_customer, zoom_product, zoom_order, zoom |
| Reports | run |
| Application | launch, to_pdf |
| Standard | accept, cancel, exit |

## Database Schema

The application uses the Northwind database with the following tables:

| Table | Description |
|-------|-------------|
| `employees` | Employee information (18 fields) |
| `employeeterritories` | Employee-territory assignments (link table) |
| `territories` | Sales territories |
| `region` | Geographic regions |
| `orders` | Customer orders with shipping details |
| `order_details` | Order line items (product, quantity, price) |
| `customers` | Customer information (CHAR-based ID) |
| `products` | Product catalog with supplier/category references |
| `suppliers` | Product suppliers |
| `categories` | Product categories |
| `shippers` | Shipping companies |
| `usstates` | US state reference data |

## Building

### Prerequisites
- Genero BDL 6.00.02+ (`fgl2p` compiler, `fglform` form compiler)
- Genero Form Compiler (`fglform`)
- PostgreSQL or Informix database with Northwind schema

### Create the Database
```bash
cd dbs
fglrun northwind_pgs_84x.42r
```

### Compile All Modules
```bash
cd hrm
make all
```

### Clean Build
```bash
cd hrm
make clean
make all
# or
make rebuild
```

## Running

After compilation, executables are located in `hrm/bin/`. Run the GUI menu or individual modules:

```bash
cd hrm/bin
# Ensure FGLPROFILE and database are configured

# GUI tree menu (recommended entry point)
fglrun bdl_menu.42r

# Individual modules
fglrun main_employees.42r
fglrun main_customers.42r
fglrun main_products.42r
fglrun main_rpt_orders_by_customer.42r
fglrun main_rpt_orders_by_employee.42r
fglrun main_rpt_orders_by_product.42r
fglrun main_rpt_orders_by_daterange.42r
# etc.

# Reports
fglrun main_rpt_orders_by_customer.42r
fglrun main_rpt_orders_by_employee.42r
```

## File Types

| Extension | Description |
|-----------|-------------|
| `.4gl` | Genero BDL source code |
| `.per` | Form definition (screen layout, controls, attributes) |
| `.4ad` | Action defaults (XML — icons, text, accelerators) |
| `.4st` | Stylesheet (XML — window types, colors, fonts) |
| `.4pw` | Genero Studio project file |
| `.42f` | Compiled form file |
| `.42m` | Compiled module file |
| `.42r` | Compiled runnable program |
| `.sch` | Database schema definition |

## Architecture

### Data Module Structure
Each entity typically has three files:
- `<entity>.4gl` — Business logic (CRUD operations, validation, combo population)
- `<entity>.per` — Form layout with TOOLBAR, VBOX/GROUP/GRID containers, and modern controls
- `main_<entity>.4gl` — Entry point that calls `init_pgm()`, opens the form, populates combos, and starts the menu

### Report Module Structure
Each report has three files:
- `rpt_<report>.4gl` — CONSTRUCT criteria, SQL execution, OUTPUT TO REPORT, calls `display_report_file()`
- `rpt_<report>.per` — Criteria form with database column fields for CONSTRUCT
- `main_rpt_<report>.4gl` — Entry point that calls `init_pgm()` and opens the criteria form

### Shared Modules
- `main_lib.4gl` — Common library: `init_pgm()` (styles + form initializer), `confirm_delete()`, `generate_temp_filename()`, `form_initializer()`
- `report_helper.4gl` — Report viewer: `display_report_file()` reads text files and displays in modal dialog
- `generic.4ad` — 36 action defaults with Font Awesome icons
- `generic.4st` — Stylesheet with `Window.modulewindow`, `Window.reportviewer`, `Table.reportviewer`, `Table.MenuTree`, and base element styles
- `report_viewer.per` — Modal report viewer form

### Key Patterns
- **Form Initializer Hook** — `ui.Form.setDefaultInitializer("form_initializer")` auto-loads action defaults for every form opened
- **Module Window Style** — All secondary (non-main) windows use `ATTRIBUTES(STYLE="modulewindow")` to open as modal dialogs with no action panel or ring menu
- **Dynamic Arrays** — `DYNAMIC ARRAY OF t_recordtype` with `.appendElement()`, `.deleteElement()`, `.getLength()`
- **CONSTRUCT BY NAME** — Generates flexible WHERE clauses from form input without explicit field mapping
- **base.Channel** — File I/O for reading/writing report text files

## Documentation

See [GENERO_MODERNIZATION_GUIDE.md](GENERO_MODERNIZATION_GUIDE.md) for detailed documentation of the modernization process (Phases 1-35).

See [REFACTORING_CHANGELOG.md](REFACTORING_CHANGELOG.md) for post-guide changes (Phases 36-54) including list views, controller/dispatch, model/UI split, REST services, test suite, and master-detail order entry.

### Window Styles
- **Main windows** — Use the base `Window` style (no action panels or ring menus)
- **Module windows** — Secondary windows opened from entity modules use `Window.modulewindow` (modal, no action panels or ring menus)
- **Report viewer** — Report output windows use `Window.reportviewer` style

### Serial Column Handling
- All 7 tables with `SERIAL` primary keys use `INSERT ... VALUES (DEFAULT, ...)` instead of explicit ID values
- After INSERT, `sqlca.sqlerrd[2]` retrieves the auto-generated ID
- Form fields for serial columns use `NOENTRY` and `DEFAULT=0` attributes
- Affected tables: categories, customers (orders FK), employees, orders, order_details, products, region, shippers, suppliers, territories, usstates

## License

This is a demonstration project for educational purposes.
