# fgl-darwin

Genero Darwin Project — A demonstration application showing how to evolve a legacy Informix 4GL application with Genero BDL (Business Development Language), using the Northwind database schema.

## Overview

This project is an Informix 4GL application built on the Northwind database schema. It provides CRUD (Create, Read, Update, Delete) functionality for managing business data including employees, customers, orders, products, and more.

## Project Structure

```
fgl-darwin/
├── dbs/
│   ├── informix/
│   │   └── northwind.informix.sql       # Informix create database
│   ├── postgres/
│   │   ├── createdb.txt                  # PostgreSQL setup instructions
│   │   └── fglprofile.pgs               # Genero database profile for PostgreSQL
│   ├── northwind.4db                     # Genero schema definition (XML)
│   ├── northwind.sch                     # Genero schema file
│   └── northwind_pgs_84x.4gl            # Database creation script
├── hrm/
│   ├── bin/                              # Compiled output (.42f, .42m, .42r files)
│   └── src/                              # Source code
│       ├── *.4gl                         # Genero BDL source files (26 modules)
│       ├── *.per                         # Form definition files (12 forms)
│       ├── northwind.42d                 # Compiled database schema
│       ├── northwind.sch                 # Schema reference
│       └── Makefile                      # Build configuration
├── Makefile                              # Root build file
├── northwind.sch                         # Root schema reference
└── README.md
```

## Modules

The application consists of the following modules:

| Module | Description |
|--------|-------------|
| `employees` | Employee management with territory assignments |
| `empl_terr` | Employee-Territory relationships |
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
| `ifx_menu` | Informix-style character menu |

## Features

### CRUD Operations
Each module provides:
- **Query** — Search records using query-by-example (CONSTRUCT)
- **Add** — Create new records (serial IDs are database-generated)
- **Modify** — Edit existing records
- **Delete** — Remove records with PROMPT confirmation

### PostgreSQL SERIAL Column Handling
Tables with auto-increment primary keys use the PostgreSQL `DEFAULT` keyword in INSERT statements. After insert, the generated ID is captured via `sqlca.sqlerrd[2]` and the form is refreshed to display the new value. Affected tables: `categories`, `employees`, `orders`, `products`, `region`, `shippers`, `suppliers`, `usstates`.

### Navigation Controls
- **First / Previous / Next / Last** — Navigate through result sets
- **Cross-module navigation** — View related records (e.g., view orders for a customer, territories for an employee)

### Field Lookups
Foreign key fields support Ctrl-T lookup functionality:
- Opens a lookup window to search and select related records
- Automatically populates the field with the selected value
- Available for employee, territory, customer, product, order, supplier, category, shipper, and region lookups

### Common Library
- **`main_lib.4gl`** — Common initialization (`init_pgm()`) and utility functions (`get_arr_max()`)

### Keyboard Shortcuts
| Key | Action |
|-----|--------|
| Accept | Submit/confirm input |
| Ctrl-P | Cancel/exit current operation |
| Ctrl-T | Open lookup window for foreign key fields |

## Database Schema

The application uses the Northwind database. The schema is defined in `dbs/northwind_pgs_84x.4gl` and `northwind.informix.sql` with the following tables:

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
- PostgreSQL or Informix database with Northwind schema

### Create the Database
```bash
cd dbs
fglcomp northwind_pgs_84x.4gl
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

After compilation, executables are located in `hrm/bin/`. Run modules using:

```bash
cd hrm/bin

# Individual modules
fglrun main_employees.42r
fglrun main_orders.42r
fglrun main_products.42r
# etc.

# Informix-style menu
fglrun ifx_menu.42r
```

## File Types

| Extension | Description |
|-----------|-------------|
| `.4gl` | Genero BDL source code |
| `.per` | Form definition (screen layout) |
| `.42f` | Compiled form file |
| `.42m` | Compiled module file |
| `.42r` | Compiled runnable program |
| `.42d` | Compiled database schema |
| `.4db` | Genero database schema definition (XML) |
| `.sch` | Genero schema file |

## Architecture

### Module Structure
Each entity typically has:
- `<entity>.4gl` — Business logic (CRUD operations, validation, lookups, display)
- `<entity>.per` — Form layout definition
- `main_<entity>.4gl` — Entry point that opens the form and runs the MENU

### Core Modules
The following modules are compiled together to support cross-module navigation:
- `main_lib.4gl` — Common library functions (`init_pgm()`, `get_arr_max()`)
- `employees.4gl`, `empl_terr.4gl`, `territories.4gl`, `region.4gl`
- `orders.4gl`, `order_details.4gl`
- `customers.4gl`, `shippers.4gl`
- `products.4gl`, `suppliers.4gl`, `categories.4gl`

## License

This is a demonstration project for educational purposes.
