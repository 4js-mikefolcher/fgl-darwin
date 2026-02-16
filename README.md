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
- `ON ACTION` pattern replacing legacy `ON KEY` handlers
- Form initializer hook for automatic action defaults loading
- Module window style — secondary windows open as modal dialogs via `STYLE="modulewindow"`

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
├── hrm/
│   ├── bin/                          # Compiled output (.42f, .42m, .42r)
│   ├── src/                          # Source code
│   │   ├── Makefile                  # Build configuration
│   │   ├── generic.4ad               # Shared action defaults (36 actions)
│   │   ├── generic.4st               # Shared stylesheet
│   │   ├── main_lib.4gl              # Common library (init, utilities)
│   │   ├── report_helper.4gl         # Report viewer utility
│   │   ├── report_viewer.per         # Report viewer form (modal dialog)
│   │   ├── <entity>.4gl              # Business logic per entity
│   │   ├── <entity>.per              # Form definition per entity
│   │   ├── main_<entity>.4gl         # Entry point per entity
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
- **Add** — Create new records
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

See [GENERO_MODERNIZATION_GUIDE.md](GENERO_MODERNIZATION_GUIDE.md) for detailed documentation of the modernization process, code patterns, technical decisions, and lessons learned.

### Window Styles
- **Main windows** — Use the base `Window` style (no action panels or ring menus)
- **Module windows** — Secondary windows opened from entity modules use `Window.modulewindow` (modal, no action panels or ring menus)
- **Report viewer** — Report output windows use `Window.reportviewer` style

## Documentation

See [GENERO_MODERNIZATION_GUIDE.md](GENERO_MODERNIZATION_GUIDE.md) for a detailed account of all modernization phases, patterns, code examples, and technical decisions made during the conversion from legacy Informix 4GL to modern Genero BDL.

## License

This is a demonstration project for educational purposes.
