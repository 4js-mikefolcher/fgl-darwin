# fgl-darwin

Genero Darwin Project — A demonstration application showing how to evolve a legacy Informix 4GL application into a modern Genero BDL (Business Development Language) web application, using the Northwind database schema.

## Overview

This project provides CRUD (Create, Read, Update, Delete) functionality for managing business data including employees, customers, orders, products, and more. It has been progressively modernized from terminal-style Informix 4GL to modern Genero BDL with contemporary UI patterns, PostgreSQL support, dynamic arrays, professional toolbars, and centralized styling.

## Project Structure

```
fgl-darwin/
├── dbs/
│   ├── informix/
│   │   └── northwind.informix.sql       # Original Informix schema
│   ├── postgres/
│   │   ├── createdb.txt                  # PostgreSQL setup instructions
│   │   └── fglprofile.pgs               # Genero database profile for PostgreSQL
│   ├── northwind.4db                     # Genero schema definition
│   ├── northwind.sch                     # Genero schema file
│   └── northwind_pgs_84x.4gl            # PostgreSQL 8.4+ database creation script
├── hrm/
│   ├── bin/                              # Compiled output (.42f, .42m, .42r files)
│   └── src/                              # Source code
│       ├── *.4gl                         # Genero BDL source files (26 modules)
│       ├── *.per                         # Form definition files (12 forms)
│       ├── northwind.42d                 # Compiled database schema
│       ├── northwind.sch                 # Schema reference
│       └── Makefile                      # Build configuration
├── Makefile                              # Root build file
├── GENERO_MODERNIZATION_GUIDE.md         # Detailed modernization documentation
└── README.md
```

## Modules

The application consists of the following modules:

| Module | Description |
|--------|-------------|
| `employees` | Employee management with territory assignments |
| `empl_terr` | Employee-Territory relationships (inline INPUT ARRAY editing) |
| `territories` | Territory management |
| `region` | Region management |
| `orders` | Order management with customer/employee/shipper associations |
| `order_details` | Order line items with product details |
| `customers` | Customer management |
| `products` | Product catalog with supplier/category associations |
| `suppliers` | Supplier management |
| `categories` | Product category management |
| `shippers` | Shipping company management |
| `usstates` | US States reference data |

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
Each module provides:
- **Query** — Search records using query-by-example (CONSTRUCT)
- **Add** — Create new records (serial IDs are database-generated)
- **Modify** — Edit existing records
- **Delete** — Remove records with `confirm_delete()` dialog

### PostgreSQL SERIAL Column Handling
Tables with auto-increment primary keys use the PostgreSQL `DEFAULT` keyword in INSERT statements. After insert, the generated ID is captured via `sqlca.sqlerrd[2]` and the form is refreshed to display the new value. Affected tables: `categories`, `employees`, `orders`, `products`, `region`, `shippers`, `suppliers`, `usstates`.

### Navigation Controls
- **First / Previous / Next / Last** — Navigate through result sets
- **Cross-module navigation** — View related records (e.g., view orders for a customer, territories for an employee)

### Field Lookups
Foreign key fields support BUTTONEDIT zoom lookup functionality:
- Opens a module window to search and select related records
- Automatically populates the field with the selected value
- Available for employee, territory, customer, product, order, supplier, category, shipper, and region lookups

### Modern UI Features
- **Dynamic arrays** (`DYNAMIC ARRAY OF t_recordtype`) replacing legacy static arrays
- **Professional toolbars** with Font Awesome icons
- **COMBOBOX / CHECKBOX controls** for products, territories, and employees modules
- **TABLE container** for empl_terr list view with inline INPUT ARRAY editing
- **VBOX / GROUP / GRID containers** for modern form layouts
- **Report viewer** — modal dialog with monospace TABLE display for report output

### Centralized Configuration
- **`generic.4ad`** — 36 action defaults with Font Awesome icons and accelerators
- **`generic.4st`** — Stylesheet with base `Window` style (no action panels/ring menus), `Window.modulewindow` for secondary windows (modal), and `Window.reportviewer` / `Table.reportviewer` for reports
- **`main_lib.4gl`** — Common initialization (`init_pgm()`) and utility functions
- **`report_helper.4gl`** — Reusable report viewer using `base.Channel` and `DISPLAY ARRAY`

### Keyboard Shortcuts
| Key | Action |
|-----|--------|
| Accept | Submit/confirm input |
| Ctrl-P | Cancel/exit current operation |
| Ctrl-T | Open lookup window for foreign key fields |

## Database Schema

The application uses the Northwind database with PostgreSQL. The schema is defined in `dbs/northwind_pgs_84x.4gl` with the following tables:

| Table | Primary Key | Description |
|-------|-------------|-------------|
| `categories` | `categoryid` (SERIAL) | Product categories |
| `customers` | `customerid` (CHAR) | Customer information |
| `employees` | `employeeid` (SERIAL) | Employee information |
| `employeeterritories` | composite | Employee-territory assignments |
| `orders` | `orderid` (SERIAL) | Customer orders |
| `order_details` | composite | Order line items |
| `products` | `productid` (SERIAL) | Product catalog |
| `region` | `regionid` (SERIAL) | Geographic regions |
| `shippers` | `shipperid` (SERIAL) | Shipping companies |
| `suppliers` | `supplierid` (SERIAL) | Product suppliers |
| `territories` | `territoryid` (VARCHAR) | Sales territories |
| `usstates` | `stateid` (SERIAL) | US state reference data |

## Building

### Prerequisites
- Genero BDL 6.00+ (`fgl2p` compiler and `fglcomp` compiler)
- Genero Form Compiler (`fglform`)
- PostgreSQL database with Northwind schema

### Create the Database
```bash
cd dbs
fglrun northwind_pgs_84x.42r
```

### Compile All Modules
```bash
cd hrm/src
make all
```

### Compile Individual Module
```bash
make employees
make orders
make products
# etc.
```

### Clean Build
```bash
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
fglrun main_orders.42r
fglrun main_products.42r
# etc.

# Reports
fglrun main_rpt_orders_by_customer.42r
fglrun main_rpt_orders_by_employee.42r
```

## File Types

| Extension | Description |
|-----------|-------------|
| `.4gl` | Genero BDL source code |
| `.per` | Form definition (screen layout) |
| `.4ad` | Action defaults definition |
| `.4st` | Stylesheet definition |
| `.42f` | Compiled form file |
| `.42m` | Compiled module file |
| `.42r` | Compiled runnable program |
| `.42d` | Compiled database schema |

## Architecture

### Module Structure
Each entity typically has:
- `<entity>.4gl` — Business logic (CRUD operations, validation, lookups, display)
- `<entity>.per` — Modern form layout with VBOX/GROUP/GRID containers
- `main_<entity>.4gl` — Entry point that opens the form and runs the MENU

### Core Modules
The following modules are compiled together to support cross-module navigation:
- `main_lib.4gl` — Common library functions (`init_pgm()`, `get_arr_max()`)
- `employees.4gl`, `empl_terr.4gl`, `territories.4gl`, `region.4gl`
- `orders.4gl`, `order_details.4gl`
- `customers.4gl`, `shippers.4gl`
- `products.4gl`, `suppliers.4gl`, `categories.4gl`

### Window Styles
- **Main windows** — Use the base `Window` style (no action panels or ring menus)
- **Module windows** — Secondary windows opened from entity modules use `Window.modulewindow` (modal, no action panels or ring menus)
- **Report viewer** — Report output windows use `Window.reportviewer` style

## Documentation

See [GENERO_MODERNIZATION_GUIDE.md](GENERO_MODERNIZATION_GUIDE.md) for a detailed account of all modernization phases, patterns, code examples, and technical decisions made during the conversion from legacy Informix 4GL to modern Genero BDL.

## License

This is a demonstration project for educational purposes.
