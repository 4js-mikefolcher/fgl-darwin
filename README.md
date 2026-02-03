# fgl-darwin

Genero Darwin Project - Demo application demonstrating how to evolve your Informix 4GL application with Genero BDL (Business Development Language).

## Overview

This project is an Informix 4GL application built on the Northwind database schema. It provides CRUD (Create, Read, Update, Delete) functionality for managing business data including employees, customers, orders, products, and more.

## Project Structure

```
fgl-darwin/
├── dbs/
│   └── informix/
│       └── northwind.informix.sql    # Database schema
├── hrm/
│   ├── bin/                          # Compiled output (.42f, .42m, .42r files)
│   └── src/                          # Source code
│       ├── *.4gl                     # Genero BDL source files
│       ├── *.per                     # Form definition files
│       └── Makefile                  # Build configuration
├── Makefile                          # Root build file
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

## Features

### CRUD Operations
Each module provides:
- **Query** - Search records using query-by-example
- **Add** - Create new records
- **Modify** - Edit existing records
- **Delete** - Remove records with confirmation

### Navigation Controls
- **First/Previous/Next/Last** - Navigate through result sets
- **Cross-module navigation** - View related records (e.g., view orders for a customer)

### Field Lookups
Foreign key fields support Ctrl-T lookup functionality:
- Opens a lookup window to search and select related records
- Automatically populates the field with the selected value
- Displays "Use Ctrl-T to open lookup window" message

### Keyboard Shortcuts
| Key | Action |
|-----|--------|
| Accept | Submit/confirm input |
| Ctrl-P | Cancel/exit current operation |
| Ctrl-T | Open lookup window for foreign key fields |

## Database Schema

The application uses the Northwind database with the following main tables:

- `employees` - Employee information
- `employeeterritories` - Employee-territory assignments (link table)
- `territories` - Sales territories
- `region` - Geographic regions
- `orders` - Customer orders
- `order_details` - Order line items
- `customers` - Customer information
- `products` - Product catalog
- `suppliers` - Product suppliers
- `categories` - Product categories
- `shippers` - Shipping companies
- `usstates` - US state reference data

## Building

### Prerequisites
- Genero BDL (fgl2p compiler)
- Genero Form Compiler (fglform)
- Informix database with Northwind schema

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

After compilation, executables are located in `hrm/bin/`. Run a module using:

```bash
cd hrm/bin
fglrun main_employees.42r
fglrun main_orders.42r
# etc.
```

## File Types

| Extension | Description |
|-----------|-------------|
| `.4gl` | Genero BDL source code |
| `.per` | Form definition (screen layout) |
| `.42f` | Compiled form file |
| `.42m` | Compiled module file |
| `.42r` | Compiled runnable program |

## Architecture

### Module Structure
Each entity typically has:
- `<entity>.4gl` - Business logic (CRUD operations, validation, lookups)
- `<entity>.per` - Form layout definition
- `main_<entity>.4gl` - Entry point that opens the form and calls submenu

### Core Modules
The following modules are compiled together to support cross-module navigation:
- `main_lib.4gl` - Common library functions
- `employees.4gl`, `territories.4gl`, `region.4gl`
- `orders.4gl`, `order_details.4gl`
- `customers.4gl`, `shippers.4gl`
- `products.4gl`, `suppliers.4gl`, `categories.4gl`

## License

This is a demonstration project for educational purposes.
