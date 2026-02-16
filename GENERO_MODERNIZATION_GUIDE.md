# Genero Module Modernization with AI Agent
## Chat Documentation & Learning Guide

**Date:** February 9-16, 2026  
**Project:** Northwind Genero Application Modernization  
**Scope:** Converting legacy terminal-style forms to modern web applications

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Conversation Summary](#conversation-summary)
3. [Technical Foundation](#technical-foundation)
4. [Modernization Patterns](#modernization-patterns)
5. [Code Examples](#code-examples)
6. [Modules Converted](#modules-converted)
7. [Key Learnings](#key-learnings)
8. [Troubleshooting](#troubleshooting)

---

## Project Overview

This conversation demonstrates how to use the **Genero AI Agent** to modernize legacy Genero BDL applications. The project involved converting twelve database modules from terminal-based UIs to modern web applications, including creating modern form designs with BUTTONEDIT lookups, COMBOBOX controls, TABLE containers, and a centralized form initializer pattern.

### Primary Objectives

- Convert static `ARRAY[1000]` declarations to `DYNAMIC ARRAY OF recordtype`
- Create proper `TYPE` record definitions for structured data
- Implement modern form layouts using `LAYOUT`, `VBOX`, `GROUP`, and `GRID` containers
- Add professional toolbars with Font Awesome icons
- Centralize action definitions and stylesheets for code reuse
- Eliminate legacy terminal-style form code
- Replace `ON KEY (ACCEPT)` / `ON KEY (CONTROL-P)` with `ON ACTION accept` / `ON ACTION cancel`
- Replace `PROMPT`-based delete confirmations with `confirm_delete()` dialog
- Use COMBOBOX and CHECKBOX form controls where appropriate
- Create report modules with CONSTRUCT-based criteria, text file output, and report viewer

### Key Achievements

- ✅ **12 modules with modern forms** (all .per files redesigned)
- ✅ **9 modules fully modernized** (.4gl + .per + main) — categories, suppliers, customers, shippers, usstates, products, territories, region, empl_terr
- ✅ **Reusable generic files** created (generic.4ad, generic.4st)
- ✅ **Dynamic arrays implemented** throughout (replacing static arrays)
- ✅ **Professional toolbars** with Font Awesome icons added
- ✅ **Modern form structure** with proper containers and layouts
- ✅ **ON ACTION pattern** replacing legacy ON KEY throughout
- ✅ **confirm_delete() dialog** replacing PROMPT-based deletion
- ✅ **COMBOBOX/CHECKBOX controls** for products, territories, employees modules
- ✅ **BUTTONEDIT with zoom** for employee, territory, customer, product, and order lookups
- ✅ **TABLE container** for empl_terr list view with INPUT ARRAY inline editing
- ✅ **36 action defaults** in generic.4ad with Font Awesome icons (added launch action)
- ✅ **Form initializer hook** — `ui.Form.setDefaultInitializer()` auto-loads action defaults
- ✅ **populate_courtesy_combo()** for employee title of courtesy
- ✅ **4 report modules** created with CONSTRUCT criteria, text file output, and report viewer
- ✅ **report_helper.4gl** — reusable report viewer using base.Channel and DISPLAY ARRAY
- ✅ **report_viewer.per** — modal dialog form with TABLE, monospace font, no row highlighting
- ✅ **Custom "reportviewer" style** in generic.4st for modal window and table formatting
- ✅ **"run" action** in generic.4ad for report execution
- ✅ **Centralized Window style** — base `Window` style in generic.4st with actionPanelPosition=none, ringMenuPosition=none (applies to all windows)
- ✅ **GUI tree menu** (bdl_menu) with toolbar, Reports category (6 root categories, 16 leaf programs)
- ✅ **Program icons** — `build_program_icons()` maps 17 programs to Font Awesome icons including bdl_menu and 4 reports
- ✅ **INPUT ARRAY with modification triggers** — empl_terr fully modernized with inline editing, transactional save, validation
- ✅ **Module window style** — `Window.modulewindow` in generic.4st for all secondary windows (32 OPEN WINDOW statements across 17 modules)

---

## Conversation Summary

### Phase 1: Categories Module (Template Pattern)

**Objective:** Create a modernization template with categories module
  
**Files Modified:**
- `categories.4gl` - Converted to TYPE and dynamic arrays
- `categories.per` - Redesigned with modern form layout
- `main_categories.4gl` - Set up to load action defaults

**Key Decisions:**
- Established dynamic array pattern: `DEFINE arr DYNAMIC ARRAY OF t_recordtype`
- Created toolbar with Font Awesome icons
- Removed ACTION DEFAULTS from form (to load programmatically)

### Phase 2: Stylesheet & Global Setup

**Objective:** Create shared stylesheet and configure global initialization

**Files Created:**
- `generic.4st` - Stylesheet with base `Window` style to disable action panels (originally `Window.noactions`, later centralized in Phase 27)
- Updated `main_lib.4gl` - Added `ui.Interface.loadStyles()` call

**Key Learnings:**
- Style names in .4st files use qualified format: `name="Window.stylename"` for named styles, or bare `name="Window"` for base style
- Named styles (e.g., `Window.reportviewer`) override the base style when applied with `STYLE="reportviewer"`
- Base `Window` style applies to ALL windows without needing explicit STYLE attribute
- Initializing styles in main_lib.4gl ensures availability across all modules

### Phase 3: Action Defaults (Reusable Actions)

**Objective:** Create centralized action definitions for multiple modules

**File Created:**
- `generic.4ad` - 12 shared actions with Font Awesome icons and accelerators

**Key Actions Defined:**
- Navigation: first, previous, next, last (fa-step-backward, fa-arrow-left, etc.)
- Data Ops: query (find), add (fa-plus), modify (fa-pencil), delete (fa-trash)
- Related: products (fa-list), orders (fa-shopping-cart)
- Standard: accept (fa-check), cancel (fa-ban), exit (fa-power-off)

### Phase 4: Suppliers Module Conversion

**Objective:** Apply categories pattern to suppliers module

**Files Modified:**
- `suppliers.4gl` - Full dynamic array conversion, more complex than categories (12 fields)
- `suppliers.per` - Modern form design with cleaned legacy code
- `main_suppliers.4gl` - Identical structure to main_categories

**Pattern Recognition:**
- Each module follows identical structure
- Shared generic files reduce code duplication
- Form cleanup needed to remove duplicate ATTRIBUTES/INSTRUCTIONS sections

### Phase 5: Customers Module Conversion

**Objective:** Complete final module using established patterns

**Files Modified:**
- `customers.4gl` - ~60% → 100% dynamic array conversion
- `customers.per` - Modern form design, cleaned of legacy code
- `main_customers.4gl` - Updated with ui.Form variable and generic.4ad loading

**Special Consideration:**
- customerid is CHAR type (unlike categories/suppliers which use integer IDs)
- Same dynamic array pattern applied despite different data types

### Phase 6: Orders Action Enhancement

**Objective:** Add missing Orders action with icon

**File Modified:**
- `generic.4ad` - Added "orders" action with fa-shopping-cart icon

### Phase 7: Shippers Module Conversion

**Objective:** Apply full modernization pattern to shippers module

**Files Modified:**
- `shippers.4gl` - TYPE t_shipper, DYNAMIC ARRAY, getLength(), ON ACTION, confirm_delete()
- `shippers.per` - TOOLBAR, LAYOUT/VBOX/GROUP/GRID layout
- `main_shippers.4gl` - ui.Form, loadActionDefaults, STYLE="noactions"

**Key Points:**
- Simple 3-field module (shipperid, companyname, phone)
- Demonstrated pattern applies cleanly to all module sizes

### Phase 8: Delete Confirmation Refactor

**Objective:** Replace PROMPT-based delete confirmations with confirm_delete() dialog

**Files Modified:**
- `shippers.4gl` - PROMPT → confirm_delete()
- `categories.4gl` - PROMPT → confirm_delete()
- `suppliers.4gl` - PROMPT → confirm_delete()

**Key Learning:**
- `confirm_delete()` lives in `main_lib.4gl` and uses `MENU ... ATTRIBUTES(STYLE="dialog")` for a proper Yes/No dialog
- Cross-module function references are resolved at link time by `fgl2p`, not during individual `fglcomp -r` compilation

### Phase 9: ON KEY to ON ACTION Migration

**Objective:** Replace legacy `ON KEY (ACCEPT)` and `ON KEY (CONTROL-P)` with modern `ON ACTION accept` and `ON ACTION cancel`

**Files Modified:**
- `shippers.4gl` - 2 replacements (CONSTRUCT, INPUT)
- `categories.4gl` - 6 replacements
- `suppliers.4gl` - 6 replacements

**Pattern:**
```4gl
-- OLD
ON KEY (ACCEPT)
    ACCEPT INPUT
ON KEY (CONTROL-P)
    LET int_flag = TRUE
    EXIT INPUT

-- NEW
ON ACTION accept
    ACCEPT INPUT
ON ACTION cancel
    LET int_flag = TRUE
    EXIT INPUT
```

### Phase 10: US States Module Conversion

**Objective:** Apply all modernization changes to the usstates module

**Files Modified:**
- `usstates.4gl` - TYPE t_usstate (4 fields), DYNAMIC ARRAY, ON ACTION, confirm_delete()
- `usstates.per` - TOOLBAR, LAYOUT/VBOX/GROUP/GRID layout
- `main_usstates.4gl` - ui.Form, loadActionDefaults, STYLE="noactions"

**Build Insight:**
- Individual `fglcomp -r usstates.4gl` fails on `confirm_delete()` since it's in `main_lib.4gl`
- The Makefile correctly builds with `fgl2p -o main_usstates.42r main_usstates.4gl main_lib.4gl usstates.4gl` which links all modules together

### Phase 11: Products Module Conversion

**Objective:** Apply full modernization plus COMBOBOX and CHECKBOX controls

**Files Modified:**
- `products.4gl` - TYPE t_product (10 fields), DYNAMIC ARRAY, ON ACTION, confirm_delete()
- `products.per` - TOOLBAR, modern layout, COMBOBOX for supplier/category, CHECKBOX for discontinued
- `main_products.4gl` - ui.Form, loadActionDefaults, STYLE="noactions", combo population on form open

**Special Features:**
- Removed `suppliername` and `categoryname` from record (comboboxes display the names)
- Removed old CTRL-T lookup mechanism (replaced by comboboxes)
- Removed `validate_supplier_field()` and `validate_category_field()` (combobox handles selection)
- Simplified SQL in `load_products()` — no longer needs JOIN to suppliers/categories tables
- Added `populate_supplier_combo()` and `populate_category_combo()` using `ui.ComboBox.forName()`
- Discontinued field defaults to 0 in add mode
- Comboboxes populated once when form opens (in `main_products.4gl`), not per add/edit

### Phase 12: Action Defaults Enhancement

**Objective:** Add Supplier and Category action icons to generic.4ad

**File Modified:**
- `generic.4ad` - Added "supplier" (fa-truck) and "category" (fa-tag) actions

### Phase 13: Territories Module Conversion

**Objective:** Modernize territories module with COMBOBOX for region selection

**Files Modified:**
- `territories.4gl` - TYPE t_territory, DYNAMIC ARRAY, ON ACTION, confirm_delete(), populate_region_combo()
- `territories.per` - TOOLBAR, LAYOUT/VBOX/GROUP/GRID, COMBOBOX for regionid
- `main_territories.4gl` - Loads generic.4ad, calls populate_region_combo()

**Key Features:**
- COMBOBOX for regionid populated from region table
- Same pattern as products (combo populated once on form open)

### Phase 14: Batch Form Modernization

**Objective:** Create modern .per files for all remaining modules

**Files Created/Modified:**
- `region.per` - Simple GRID with regionid/regiondescription
- `employees.per` - 3 GROUPs (Personal, Contact, Employment), COMBOBOX titleofcourtesy, DATEEDIT for dates, BUTTONEDIT reportsto, TEXTEDIT notes
- `empl_terr.per` - TABLE container for DISPLAY ARRAY, BUTTONEDIT for employee/territory lookups
- `orders.per` - BUTTONEDIT customerid/employeeid, COMBOBOX shipvia, DATEEDIT for dates
- `order_details.per` - BUTTONEDIT orderid/productid, computed fields

**New Form Controls Introduced:**
- **BUTTONEDIT** with ACTION=zoom_xxx for lookup/zoom windows
- **DATEEDIT** for date fields (birthdate, hiredate, orderdate, etc.)
- **TEXTEDIT** with SCROLL for multi-line text (employees.notes)
- **TABLE** container with pipe-separated columns for list views

### Phase 15: Main Program Modernization

**Objective:** Modernize main_region.4gl and main_employees.4gl

**Files Modified:**
- `main_region.4gl` - Converted to ON ACTION pattern (query/add/exit)
- `main_employees.4gl` - Converted to ON ACTION, calls populate_courtesy_combo()

### Phase 16: Action Defaults Audit

**Objective:** Ensure all actions used across the codebase have icons in generic.4ad

**File Modified:**
- `generic.4ad` - Expanded from 15 to 34 ActionDefault entries

**Actions Added:**
- Related: region (fa-globe), employees (fa-users), territories (fa-map-marker), customer (fa-user), employee (fa-id-card), shipper (fa-ship), details (fa-list-alt), reportsto (fa-sitemap), order (fa-file-text), product (fa-cube), select (fa-check-circle)
- Zoom/Lookup: zoom_employee, zoom_territory, zoom_customer, zoom_product, zoom_order, zoom (all use "zoom" image)

**All icon names validated against:** `/Applications/Genero Studio 6.00.02-202512011639.app/Contents/Resources/fgl/lib/image2font.txt` (919 mappings, Font Awesome 4.7.0)

### Phase 17: populate_courtesy_combo() Function

**Objective:** Add missing function for employee title of courtesy COMBOBOX

**File Modified:**
- `employees.4gl` - Added `populate_courtesy_combo()` with static values: Dr., Mr., Mrs., Ms.

**Pattern:** Unlike other combo functions that query the database, this uses static `cb.addItem()` calls since courtesy titles are a fixed set.

### Phase 18: Form Initializer Hook

**Objective:** Centralize action defaults loading using `ui.Form.setDefaultInitializer()`


**Files Modified:**
- `main_lib.4gl` - Added `form_initializer(frm ui.Form)` function that calls `frm.loadActionDefaults("generic.4ad")`, registered via `ui.Form.setDefaultInitializer("form_initializer")` in `init_pgm()`
- All 9 `main_*.4gl` files — Removed `DEFINE f ui.Form`, `LET f = ui.Window.getCurrent().getForm()`, and `CALL f.loadActionDefaults("generic.4ad")` boilerplate

**Key Learning:**
- `ui.Form.setDefaultInitializer("function_name")` registers a callback that runs automatically every time any form opens
- The callback receives a `ui.Form` parameter — perfect for loading shared resources
- Eliminates repetitive boilerplate from every main program
- Register once in `init_pgm()`, applies globally to all windows

**Total Actions in generic.4ad: 35**
- Navigation: first, previous, next, last
- Data Ops: query, add, modify, delete
- Related: products, orders, supplier, category, region, employees, territories, customer, employee, shipper, details, reportsto, order, product, select
- Zoom/Lookup: zoom_employee, zoom_territory, zoom_customer, zoom_product, zoom_order, zoom
- Reports: run
- Standard: accept, cancel, exit

### Phase 19: Report Modules — CONSTRUCT Criteria with Text File Output

**Objective:** Create 4 report programs that use CONSTRUCT for flexible criteria entry, generate text file reports, and display results in a report viewer dialog.

**Files Created:**
- `main_rpt_orders_by_customer.4gl` — Main program for Orders By Customer report
- `main_rpt_orders_by_employee.4gl` — Main program for Orders By Employee report
- `main_rpt_orders_by_product.4gl` — Main program for Orders By Product report
- `main_rpt_orders_by_daterange.4gl` — Main program for Orders By Date Range report
- `rpt_orders_by_customer.4gl` — Report logic with CONSTRUCT, SQL, and OUTPUT TO REPORT
- `rpt_orders_by_employee.4gl` — Report logic for employee-based orders
- `rpt_orders_by_product.4gl` — Report logic for product-based orders
- `rpt_orders_by_daterange.4gl` — Report logic for date range orders
- `rpt_orders_by_customer.per` — Criteria form with CONSTRUCT fields
- `rpt_orders_by_employee.per` — Criteria form
- `rpt_orders_by_product.per` — Criteria form
- `rpt_orders_by_daterange.per` — Criteria form with DATEEDIT for dates

**Key Design Decisions:**
- Used CONSTRUCT BY NAME (no FROM clause) for flexible WHERE clause generation
- SQL uses full table names (no aliases) to match CONSTRUCT output
- Reports output to text files via REPORT engine with START REPORT TO filename
- `generate_temp_filename(prefix, extension)` creates unique filenames using `util.Datetime.format(CURRENT, "%Y%m%d_%H%M%S")`
- ON ACTION run replaces accept for report execution
- All forms have TABLES section AFTER LAYOUT (required placement)
- Message shows record count and filename after report runs

**CONSTRUCT BY NAME Pattern:**
```4gl
CONSTRUCT BY NAME where_clause ON customers.customerid, customers.companyname
   ON ACTION run
      ACCEPT CONSTRUCT
   ON ACTION exit
      EXIT CONSTRUCT
END CONSTRUCT
```

**Key Learning — CONSTRUCT BY NAME Syntax:**
- `CONSTRUCT BY NAME where_clause ON table.col1, table.col2` — maps form fields to columns by name
- Do NOT use `FROM s_criteria.*` — that syntax does not apply to BY NAME variant
- The ON clause uses full `table.column` names, and CONSTRUCT generates WHERE clauses using those same names
- SQL must use matching full table names (no aliases) so the WHERE clause works directly

**Key Learning — SQL Alias Mismatch:**
- CONSTRUCT generates WHERE clauses with full table names: `customers.customerid = 'ALFKI'`
- If SQL uses aliases (`SELECT ... FROM customers c`), the WHERE fails: `customers.customerid` doesn't match `c.customerid`
- Solution: Remove all table aliases from SQL, use full table names everywhere
- Note: `STRING.replace()` method does NOT exist in Genero BDL 6.00.02

**Key Learning — TABLES Section Placement:**
- The TABLES section in .per forms must come AFTER the LAYOUT section
- Placing it before TOOLBAR causes compile errors

### Phase 20: Run Action in generic.4ad

**Objective:** Add a "Run Report" action for report execution

**File Modified:**
- `generic.4ad` — Added "run" action with fa-play icon and text "Run Report"

**Action Definition:**
```xml
<ActionDefault name="run"
  text="Run Report"
  image="fa-play"
  comment="Execute the report" />
```

### Phase 21: Report Helper Library — Text File Viewer

**Objective:** Create a reusable library module that reads a text file and displays its contents in a DISPLAY ARRAY dialog.

**Files Created:**
- `report_helper.4gl` — Library module with `display_report_file()` function
- `report_viewer.per` — Modal dialog form with TABLE for displaying report lines

**report_helper.4gl — Key Function:**
```4gl
FUNCTION display_report_file(rpt_file)
   DEFINE rpt_file STRING
   DEFINE lines DYNAMIC ARRAY OF RECORD
      line_text STRING
   END RECORD
   DEFINE ch base.Channel
   DEFINE line STRING

   LET ch = base.Channel.create()
   TRY
      CALL ch.openFile(rpt_file, "r")
   CATCH
      ERROR "Unable to open file: ", rpt_file
      RETURN
   END TRY

   WHILE TRUE
      LET line = ch.readLine()
      IF ch.isEof() THEN EXIT WHILE END IF
      CALL lines.appendElement()
      LET lines[lines.getLength()].line_text = line
   END WHILE
   CALL ch.close()

   OPEN WINDOW rptViewerWindow WITH FORM "report_viewer"
   DISPLAY ARRAY lines TO s_lines.*
      ON ACTION exit
         EXIT DISPLAY
   END DISPLAY
   CLOSE WINDOW rptViewerWindow
END FUNCTION
```

**Key Patterns:**
- `base.Channel` for file I/O: `create()`, `openFile(path, "r")`, `readLine()`, `isEof()`, `close()`
- TRY/CATCH for file open error handling
- Dynamic array of anonymous record for line storage
- DISPLAY ARRAY with ON ACTION exit for simple viewer
- Separate OPEN WINDOW / CLOSE WINDOW to isolate the viewer

**Integration:** All 4 report modules call `display_report_file(rpt_file)` after generating the text file, in the ELSE branch (only when records are found).

### Phase 22: Report Viewer Form with Custom Style

**Objective:** Create a modal report viewer form with fixed-width monospace table and no row highlighting.

**report_viewer.per:**
```per
TOOLBAR
  ITEM exit
END

LAYOUT (TEXT="Report Viewer", STYLE="reportviewer")
  VBOX
    TABLE (STYLE="reportviewer", STRETCHCOLUMNS, height=25 LINES, width=80 CHARACTERS)
    {
      [line_text                                                                              ]
    }
    END
  END
END

ATTRIBUTES
  EDIT line_text = FORMONLY.line_text TYPE VARCHAR, SCROLL;
END

INSTRUCTIONS
  SCREEN RECORD s_lines(line_text);
END
```

**generic.4st — Custom Styles Added:**
```xml
<Style name="Window.reportviewer">
  <StyleAttribute name="windowType" value="modal" />
  <StyleAttribute name="actionPanelPosition" value="bottom" />
  <StyleAttribute name="ringMenuPosition" value="bottom" />
  <StyleAttribute name="toolBarPosition" value="none" />
</Style>

<Style name="Table.reportviewer">
  <StyleAttribute name="fontFamily" value="monospace" />
  <StyleAttribute name="highlightCurrentRow" value="no" />
</Style>
```

**Key Learnings:**
- `STYLE="reportviewer"` on LAYOUT maps to `Window.reportviewer` in the stylesheet
- `STYLE="reportviewer"` on TABLE maps to `Table.reportviewer` in the stylesheet
- `windowType="modal"` makes the window a modal dialog
- `highlightCurrentRow="no"` removes current row highlighting from the table
- `fontFamily="monospace"` ensures report text aligns properly
- `TYPE STRING` is NOT valid in .per ATTRIBUTES — use `TYPE VARCHAR` or `TYPE CHAR` instead
- FORMONLY fields without `TYPE CHAR` or `TYPE VARCHAR` cause compile error -6803
- TABLE without parenthesized attributes compiles; `TABLE (STYLE="name")` also works
- `STRETCHCOLUMNS` (without `="column"`) stretches all columns

### Phase 23: Project File Updates

**Objective:** Add new report files to the Genero project file (.4pw)

**File Modified:**
- `fgl-darwin.4pw` — Added entries for all new report files

**Files Added to Report Application Nodes:**
- `main_rpt_orders_by_customer.4gl`, `rpt_orders_by_customer.4gl`, `rpt_orders_by_customer.per`
- `main_rpt_orders_by_employee.4gl`, `rpt_orders_by_employee.4gl`, `rpt_orders_by_employee.per`
- `main_rpt_orders_by_product.4gl`, `rpt_orders_by_product.4gl`, `rpt_orders_by_product.per`
- `main_rpt_orders_by_daterange.4gl`, `rpt_orders_by_daterange.4gl`, `rpt_orders_by_daterange.per`

**Files Added to Shared Library:**
- `report_helper.4gl` — Report viewer function
- `report_viewer.per` — Report viewer form

**Key Learning:** Shared library files (used by multiple applications) belong in the Shared library node, not duplicated in each Application node.

### Phase 24: Toolbar for bdl_menu Program

**Objective:** Add a toolbar to the GUI tree menu program with launch and exit actions, and apply the noactions window style.

**Files Modified:**
- `bdl_menu.per` — Added TOOLBAR with ITEM launch, SEPARATOR, ITEM exit
- `bdl_menu.4gl` — Added `STYLE="noactions"` to OPEN WINDOW (later removed when centralized)

**Toolbar Definition:**
```
TOOLBAR
  ITEM launch
  SEPARATOR
  ITEM exit
END
```

**Key Decision:** Used `STYLE="noactions"` to hide the action panel and ring menu since the toolbar provides all needed controls. This was later centralized in Phase 27.

### Phase 25: Launch Action Icon and Centralized Action Defaults

**Objective:** Select a Font Awesome icon for the launch action from `$FGLDIR/lib/image2font.txt`, move ACTION DEFAULTS from bdl_menu.per to generic.4ad, and rename the close action to exit for consistency.

**Files Modified:**
- `bdl_menu.per` — Removed ACTION DEFAULTS section (now sourced from generic.4ad)
- `generic.4ad` — Added "launch" ActionDefault with fa-rocket icon and acceleratorName=Return

**Action Definition Added:**
```xml
<ActionDefault name="launch"
  text="Launch"
  image="fa-rocket"
  comment="Launch the selected program"
  acceleratorName="Return" />
```

**Key Decisions:**
- Searched `$FGLDIR/lib/image2font.txt` (919 Font Awesome 4.7.0 mappings) for suitable launch icon
- Selected `fa-rocket` (`FontAwesome.ttf:f135`) as the launch icon
- Set `acceleratorName="Return"` so Enter key triggers launch (same as TREE DOUBLECLICK)
- Renamed toolbar ITEM from "close" to "exit" for consistency with the exit ActionDefault in generic.4ad

**Total Actions in generic.4ad: 36**

### Phase 26: Launch Icon as Application Icon

**Objective:** Use the fa-rocket icon as the application/form icon for the bdl_menu program.

**File Modified:**
- `main_lib.4gl` — Added `bdl_menu` → `fa-rocket` mapping in `build_program_icons()`

**Code Added:**
```4gl
CALL add_program_icon("bdl_menu", "fa-rocket")
```

**Key Learning:** The `form_initializer()` callback already sets window and app icons automatically using `get_program_icon()`. Adding the mapping to `build_program_icons()` is all that's needed — no code changes in bdl_menu.4gl required.

### Phase 27: Centralized Window Style (noactions)

**Objective:** Instead of adding `STYLE="noactions"` to every OPEN WINDOW statement, centralize it by making the base `Window` style in generic.4st apply actionPanelPosition=none and ringMenuPosition=none to all windows.

**Files Modified:**
- `generic.4st` — Renamed `Window.noactions` to base `Window` style (applies to ALL windows automatically)
- `bdl_menu.4gl` — Removed explicit `STYLE="noactions"` from OPEN WINDOW (no longer needed)

**generic.4st — Before:**
```xml
<Style name="Window.noactions">
  <StyleAttribute name="actionPanelPosition" value="none" />
  <StyleAttribute name="ringMenuPosition" value="none" />
</Style>
```

**generic.4st — After:**
```xml
<Style name="Window">
  <StyleAttribute name="actionPanelPosition" value="none" />
  <StyleAttribute name="ringMenuPosition" value="none" />
</Style>
```

**Key Learning:**
- A base `Window` style (without a dot-suffix) applies to ALL windows in the application
- Named styles like `Window.reportviewer` override the base style when explicitly referenced with `STYLE="reportviewer"`
- This eliminates the need for `STYLE="noactions"` on every OPEN WINDOW — all 18+ forms with toolbars benefit automatically
- The `Window.reportviewer` style correctly overrides with its own `actionPanelPosition="bottom"` for report viewer windows

### Phase 28: Reports Added to Menu

**Objective:** Add a Reports category to the bdl_menu tree menu with 4 report programs as children.

**Files Modified:**
- `bdl_menu.4gl` — Added Reports root category (id=6) with 4 children in `build_menu()`
- `main_lib.4gl` — Added fa-file-text icon mappings for all 4 report programs in `build_program_icons()`

**Menu Structure Added:**
```
Reports (id=6, pid=0)
├── Orders by Customer    (id=60, pid=6, program=main_rpt_orders_by_customer)
├── Orders by Employee    (id=61, pid=6, program=main_rpt_orders_by_employee)
├── Orders by Product     (id=62, pid=6, program=main_rpt_orders_by_product)
└── Orders by Date Range  (id=63, pid=6, program=main_rpt_orders_by_daterange)
```

**Icon Mappings Added:**
```4gl
CALL add_program_icon("main_rpt_orders_by_customer",  "fa-file-text")
CALL add_program_icon("main_rpt_orders_by_employee",  "fa-file-text")
CALL add_program_icon("main_rpt_orders_by_product",   "fa-file-text")
CALL add_program_icon("main_rpt_orders_by_daterange", "fa-file-text")
```

**Updated Menu Totals:** 6 root categories, 16 leaf programs (12 data management + 4 reports)

### Phase 29: empl_terr ON KEY to ON ACTION Migration

**Objective:** Replace all legacy ON KEY handlers in empl_terr.4gl with modern ON ACTION handlers, across DISPLAY ARRAY, CONSTRUCT, and INPUT statements.

**File Modified:**
- `empl_terr.4gl` — Replaced all ON KEY blocks with ON ACTION equivalents

**Migrations Performed:**

**DISPLAY ARRAY (submenu):**
```4gl
-- OLD                           -- NEW
ON KEY (CONTROL-P)               ON ACTION exit
   EXIT DISPLAY                     EXIT DISPLAY
ON KEY (CONTROL-D)               ON ACTION delete
   -- delete logic                  -- delete logic
ON KEY (CONTROL-A)               ON ACTION add
   -- add logic                     -- add logic
                                 ON ACTION query
                                    -- new: query functionality
```

**CONSTRUCT:**
```4gl
-- OLD                           -- NEW
ON KEY (ACCEPT)                  ON ACTION accept
   ACCEPT CONSTRUCT                 ACCEPT CONSTRUCT
ON KEY (CONTROL-P)               ON ACTION cancel
   EXIT CONSTRUCT                   EXIT CONSTRUCT
```

**INPUT:**
```4gl
-- OLD                           -- NEW
ON KEY (ACCEPT)                  ON ACTION accept
   ACCEPT INPUT                     ACCEPT INPUT
ON KEY (CONTROL-P)               ON ACTION cancel
   LET int_flag = TRUE              LET int_flag = TRUE
   EXIT INPUT                       EXIT INPUT
ON KEY (CONTROL-T) INFIELD ...   ON ACTION zoom_employee INFIELD ...
   -- zoom logic                    -- zoom logic
                                 ON ACTION zoom_territory INFIELD ...
                                    -- zoom logic
```

**Additional Changes:**
- Replaced PROMPT-based delete confirmation with `confirm_delete()`
- Removed unused variables

### Phase 30: empl_terr Complete Modernization with INPUT ARRAY

**Objective:** Complete rewrite of empl_terr.4gl to use INPUT ARRAY with modification triggers for inline editing, replacing the old DISPLAY ARRAY + separate INPUT add pattern.

**Files Modified:**
- `empl_terr.4gl` — Complete rewrite with INPUT ARRAY, TYPE, DYNAMIC ARRAY, validation, transactional save
- `main_empl_terr.4gl` — Simplified to call `submenu_empl_terr()` (replaced old MENU with COMMAND blocks)

**New Architecture:**

**Type Definition:**
```4gl
TYPE t_empl_terr RECORD
   employeeid LIKE employees.employeeid,
   fullname VARCHAR(32),
   territoryid LIKE territories.territoryid,
   territorydescription LIKE territories.territorydescription,
   regiondescription LIKE region.regiondescription
END RECORD

DEFINE empl_terr_arr DYNAMIC ARRAY OF t_empl_terr
DEFINE contrl_empl_id LIKE employees.employeeid
```

**Entry Points:**
- `terr_by_empl(employ_id)` — Called from employees module (sub-window, pre-filtered by employee)
- `submenu_empl_terr()` — Standalone entry (query first via CONSTRUCT, then manage results)

**Core Function — manage_empl_terr():**
```4gl
INPUT ARRAY empl_terr_arr WITHOUT DEFAULTS FROM sa_empl_terr.*
   ATTRIBUTES(UNBUFFERED, INSERT ROW = FALSE, APPEND ROW = FALSE,
              DELETE ROW = FALSE, AUTO APPEND = FALSE)
```

**Key INPUT ARRAY Attributes:**
- `UNBUFFERED` — Display changes reflect immediately in the array
- `INSERT ROW = FALSE` / `APPEND ROW = FALSE` — Disable built-in row insertion (managed by ON ACTION add)
- `DELETE ROW = FALSE` — Disable built-in deletion (managed by ON ACTION delete)
- `AUTO APPEND = FALSE` — Prevent automatic row addition when tabbing past last row

**Modification Triggers:**
- `BEFORE ROW` — Track current row via `arr_curr()`
- `BEFORE FIELD fullname/territorydescription/regiondescription` — Skip derived (display-only) columns using `NEXT FIELD` to jump to next editable field
- `AFTER FIELD employeeid` — Validate employee ID, populate fullname
- `AFTER FIELD territoryid` — Validate territory ID, populate territorydescription and regiondescription
- `ON ACTION zoom_employee INFIELD employeeid` — Lookup employee via BUTTONEDIT
- `ON ACTION zoom_territory INFIELD territoryid` — Lookup territory via BUTTONEDIT
- `ON ACTION query` — Re-run CONSTRUCT and reload data
- `ON ACTION add` — Append new row via `append_new_row()`
- `ON ACTION delete` — Delete current row with `confirm_delete()` confirmation
- `ON ACTION accept` — Save all changes via `save_all_changes()`, exit INPUT ARRAY
- `ON ACTION cancel` / `ON ACTION exit` — Discard changes, exit

**New Functions:**

| Function | Purpose |
|----------|---------|
| `append_new_row(p_arr)` | Appends empty row to dynamic array, pre-fills employee ID when in single-employee context |
| `save_all_changes(p_arr)` | Transactional save: BEGIN WORK, DELETE existing, re-INSERT all rows, COMMIT WORK (ROLLBACK on error) |
| `delete_empl_terr_row(p_rec)` | Deletes single row from database |
| `validate_territory(p_territory_id)` | Returns BOOLEAN, message, description, region (4 return values) |
| `validate_empl_id(p_employee_id)` | Returns BOOLEAN, fullname (parameterized, no module-global dependency) |

**Transactional Save Pattern:**
```4gl
FUNCTION save_all_changes(p_arr)
   DEFINE p_arr DYNAMIC ARRAY OF t_empl_terr
   DEFINE idx INTEGER

   BEGIN WORK
   TRY
      -- Delete all existing records for the employee(s) in the array
      DELETE FROM employeeterritories
         WHERE employeeid = contrl_empl_id

      -- Re-insert all current rows
      FOR idx = 1 TO p_arr.getLength()
         INSERT INTO employeeterritories (employeeid, territoryid)
            VALUES (p_arr[idx].employeeid, p_arr[idx].territoryid)
      END FOR

      COMMIT WORK
   CATCH
      ROLLBACK WORK
      ERROR "Save failed: ", SQLCA.SQLERRM
   END TRY
END FUNCTION
```

**Removed Functions/Variables:**
- `curr_empl_terr` record (no longer needed — array rows edited inline)
- `arr_size`, `arr_max` (replaced by `.getLength()`)
- `set_count()` calls (INPUT ARRAY handles display automatically)
- `refresh_empl_terr()`, `clear_empl_terr()`, `load_curr_empl_terr()`, `display_curr_empl_terr()`
- `clear_curr_empl_terr()`, `insert_curr_empl_terr()`, `delete_curr_empl_terr()`
- `add_empl_terr()` (old INPUT-based add function)

**Key Learnings:**
- **DEFINE placement:** All DEFINE statements MUST be at the top of a function before any executable code. Placing DEFINE inside IF or FOR blocks causes compile error: `"A grammatical error has been found at 'DEFINE' expecting: ACCEPT ALTER BEGIN..."`
- **Module-private variables:** Variables defined at module scope (DEFINE outside functions) are private to that module. `main_empl_terr.4gl` cannot directly reference `empl_terr_arr` — call `submenu_empl_terr()` instead.
- **BEFORE FIELD for derived columns:** Use `BEFORE FIELD fieldname` + `NEXT FIELD nextfield` to skip non-editable computed fields in the tab order.
- **INPUT ARRAY without built-in controls:** Disabling INSERT ROW, APPEND ROW, DELETE ROW, and AUTO APPEND gives full control over row management via ON ACTION handlers.

### Phase 31: Module Window Style for Secondary Windows

**Objective:** Define a dedicated `Window.modulewindow` style in generic.4st for all secondary (non-main) windows, and update every OPEN WINDOW statement in non-main_* modules to use `STYLE="modulewindow"`. This removes legacy `AT row,col` positioning, `BORDER`, `MESSAGE LINE LAST`, `ERROR LINE LAST` attributes, and the old `STYLE="noactions"` references from module windows.

**Files Modified:**
- `generic.4st` — Added `Window.modulewindow` style (windowType=modal, actionPanelPosition=none, ringMenuPosition=none)
- 17 non-main_* .4gl files — Updated all 32 OPEN WINDOW statements to use `STYLE="modulewindow"`

**generic.4st — New Style Added:**
```xml
<Style name="Window.modulewindow">
  <StyleAttribute name="windowType" value="modal" />
  <StyleAttribute name="actionPanelPosition" value="none" />
  <StyleAttribute name="ringMenuPosition" value="none" />
</Style>
```

**OPEN WINDOW — Before (various patterns):**
```4gl
-- Pattern 1: Legacy positioning with terminal attributes
OPEN WINDOW viewCustomerWindow AT 5,5 WITH FORM "customers"
   ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

-- Pattern 2: No attributes at all
OPEN WINDOW subw1 AT 5,5 WITH FORM "empl_terr"

-- Pattern 3: Old noactions style
OPEN WINDOW rptCustWindow WITH FORM "rpt_orders_by_customer"
   ATTRIBUTES(BORDER, STYLE="noactions")
```

**OPEN WINDOW — After (unified pattern):**
```4gl
OPEN WINDOW viewCustomerWindow WITH FORM "customers"
   ATTRIBUTES(STYLE="modulewindow")
```

**Files Updated (32 OPEN WINDOW statements across 17 files):**

| File | Windows Updated |
|------|----------------|
| categories.4gl | 2 |
| customers.4gl | 2 |
| empl_terr.4gl | 1 |
| employees.4gl | 2 |
| order_details.4gl | 1 |
| orders.4gl | 4 |
| products.4gl | 4 |
| region.4gl | 2 |
| report_helper.4gl | 1 |
| rpt_orders_by_customer.4gl | 1 |
| rpt_orders_by_daterange.4gl | 1 |
| rpt_orders_by_employee.4gl | 1 |
| rpt_orders_by_product.4gl | 1 |
| rpt_orders_generic.4gl | 1 |
| shippers.4gl | 2 |
| suppliers.4gl | 2 |
| territories.4gl | 4 |

**Excluded Files (main programs, not secondary windows):**
- `bdl_menu.4gl` — Main menu entry point
- `ifx_menu.4gl` — Legacy text-based menu entry point

**Key Learnings:**
- **Module windows vs main windows:** Secondary windows opened by non-main modules benefit from a dedicated style to control their appearance consistently
- **AT row,col is legacy:** The `AT row,col` positioning is a terminal-era pattern; removing it lets the GDC/GBC position windows automatically
- **BORDER, MESSAGE LINE LAST, ERROR LINE LAST are legacy:** These terminal-style attributes are not needed in modern GUI applications
- **Named styles override base styles:** `Window.modulewindow` overrides the base `Window` style when explicitly applied with `STYLE="modulewindow"`
- **Style consolidation:** The 4 report criteria modules (rpt_orders_by_*) previously used `STYLE="noactions"` — now unified under `STYLE="modulewindow"`

---

## Technical Foundation

### Genero Version
- **Genero BDL 6.00.02-202512011639**
- Installation: `/Applications/Genero Studio 6.00.02-202512011639.app/Contents/Resources/fgl/`

### Core Technologies

#### 1. Dynamic Arrays
Replace static arrays with dynamic alternatives:

```4gl
-- OLD: Static array with max size
DEFINE arr ARRAY[1000] OF t_customer
DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

-- NEW: Dynamic array (grows/shrinks automatically)
DEFINE arr DYNAMIC ARRAY OF t_customer
```

**Available Methods:**
- `.appendElement()` - Add element to end
- `.deleteElement(idx)` - Remove element at index
- `.getLength()` - Get current count (replaces arr_size)
- `.clear()` - Empty all elements

#### 2. Record Type Definitions
Replaced inline field definitions with structured types:

```4gl
-- Define a record type
TYPE t_customer RECORD
   customerid CHAR(5),
   companyname VARCHAR(40),
   contactname VARCHAR(30),
   contacttitle VARCHAR(30),
   address VARCHAR(60),
   city VARCHAR(15),
   region VARCHAR(15),
   postalcode VARCHAR(10),
   country VARCHAR(15),
   phone VARCHAR(24),
   fax VARCHAR(24)
END RECORD
```

#### 3. Form Design Structure

Modern .per files follow this structure:

```
SCHEMA
  <database schema>

TOOLBAR
  <toolbar definition with ITEM, SEPARATOR, AUTOITEMS>

LAYOUT
  <VBOX, GROUP, GRID container structure>

ATTRIBUTES
  <TEXTEDIT and other special widgets>

INSTRUCTIONS
  <SCREEN RECORD definitions>
```

#### 4. Toolbar Syntax

Correct toolbar format (not brace syntax):

```
TOOLBAR
  ITEM "first" "First Record"
  ITEM "previous" "Previous Record"
  ITEM "next" "Next Record"
  ITEM "last" "Last Record"
  SEPARATOR
  ITEM "add" "Add New"
  ITEM "modify" "Modify"
  ITEM "delete" "Delete"
  SEPARATOR
  AUTOITEMS (CONTENT=actions)
  SEPARATOR
  ITEM "products" "View Products"
  ITEM "exit" "Exit"
```

#### 5. Action Defaults (.4ad) Format

XML format with Font Awesome icons:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ActionDefaultList>
  <ActionDefault name="add"
    text="Add"
    image="fa-plus"
    comment="Add a new record"
    acceleratorName="Control-n" />
</ActionDefaultList>
```

#### 6. Stylesheet (.4st) Format

XML format with named styles:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<StyleList>
  <Style name="Window.noactions">
    <Property name="actionPanelPosition" value="none"/>
    <Property name="ringMenuPosition" value="none"/>
  </Style>
</StyleList>
```

#### 7. BUTTONEDIT Controls (Zoom/Lookup)

In the form (.per):
```per
BUTTONEDIT reportsto = formonly.reportsto TYPE SMALLINT, ACTION=zoom_employee;
```

**Key Points:**
- ACTION=zoom_xxx triggers the corresponding ON ACTION in the dialog
- Paired with a NOENTRY description field for display:
```per
reportsto_name = formonly.reportsto_name TYPE VARCHAR, NOENTRY;
```
- The zoom function typically opens a lookup window and returns an ID + description

#### 8. DATEEDIT Controls

In the form (.per):
```per
DATEEDIT birthdate = formonly.birthdate TYPE DATE;
DATEEDIT hiredate = formonly.hiredate TYPE DATE;
```

Provides a date picker widget instead of plain text entry.

#### 9. TABLE Container (List Views)

For DISPLAY ARRAY / INPUT ARRAY forms:
```per
TABLE
{
  [col1     |col2                |col3     ]
  [col1     |col2                |col3     ]
  [col1     |col2                |col3     ]
}
END
```

**Critical Rules:**
- Columns separated by pipe `|` characters (NOT adjacent brackets `][`)
- Row template must be repeated — the count defines visible rows
- SCREEN RECORD array size must match the number of repeated rows
- Example: 5 repeated rows → `SCREEN RECORD sa_name[5](...)`

**TABLE with STYLE:**
```per
TABLE (STYLE="reportviewer", STRETCHCOLUMNS, height=25 LINES, width=80 CHARACTERS)
{
  [line_text                                                                              ]
}
END
```

- `STYLE` applies the matching `Table.stylename` from the stylesheet
- `STRETCHCOLUMNS` (no value) stretches all columns to fill the width
- `height=25 LINES` sets the visible row count
- `width=80 CHARACTERS` sets the table width

#### 10. COMBOBOX Controls (Dynamic Population)

In the form (.per):
```per
COMBOBOX supplierid = formonly.supplierid TYPE SMALLINT;
```

In the code (.4gl) — populate from database:
```4gl
FUNCTION populate_supplier_combo()
   DEFINE cb ui.ComboBox
   DEFINE sup_id SMALLINT
   DEFINE sup_name VARCHAR(40)

   LET cb = ui.ComboBox.forName("supplierid")
   IF cb IS NULL THEN
      RETURN
   END IF
   CALL cb.clear()
   DECLARE c_sup_combo CURSOR FOR
      SELECT supplierid, companyname FROM suppliers ORDER BY companyname
   FOREACH c_sup_combo INTO sup_id, sup_name
      CALL cb.addItem(sup_id, sup_name)
   END FOREACH
END FUNCTION
```

**Best Practice:** Populate comboboxes once when the form opens (in MAIN), not per add/edit operation.

#### 11. COMBOBOX Controls (Static Population)

For fixed value sets (not from database):
```4gl
FUNCTION populate_courtesy_combo()
   DEFINE cb ui.ComboBox

   LET cb = ui.ComboBox.forName("titleofcourtesy")
   IF cb IS NULL THEN
      RETURN
   END IF
   CALL cb.clear()
   CALL cb.addItem("Dr.",  "Dr.")
   CALL cb.addItem("Mr.",  "Mr.")
   CALL cb.addItem("Mrs.", "Mrs.")
   CALL cb.addItem("Ms.",  "Ms.")
END FUNCTION
```

#### 12. CHECKBOX Controls

In the form (.per):
```per
CHECKBOX discontinued = formonly.discontinued TYPE INTEGER,
  VALUECHECKED=1, VALUEUNCHECKED=0, TEXT="Discontinued";
```

**Key:** Set a default value in code when adding records:
```4gl
LET curr_products.discontinued = 0
```

#### 13. Form Initializer Hook

Register a callback that runs automatically when any form opens:
```4gl
FUNCTION init_pgm()
    CALL ui.Interface.loadStyles("generic.4st")
    CALL ui.Form.setDefaultInitializer("form_initializer")
END FUNCTION

FUNCTION form_initializer(frm ui.Form)
    CALL frm.loadActionDefaults("generic.4ad")
END FUNCTION
```

**Benefits:**
- Eliminates repetitive `DEFINE f ui.Form` / `LET f = ...getForm()` / `CALL f.loadActionDefaults()` from every main program
- Any new module automatically gets action defaults just by calling `init_pgm()`
- Single place to add global form initialization logic

#### 14. ON ACTION Pattern (Replacing ON KEY)

```4gl
-- OLD (legacy)
ON KEY (ACCEPT)
    ACCEPT INPUT
ON KEY (CONTROL-P)
    LET int_flag = TRUE
    EXIT INPUT

-- NEW (modern)
ON ACTION accept
    ACCEPT INPUT
ON ACTION cancel
    LET int_flag = TRUE
    EXIT INPUT
```

Works in CONSTRUCT, INPUT BY NAME, and other dialog statements.

#### 15. CONSTRUCT BY NAME Pattern (Report Criteria)

Generate flexible WHERE clauses from user input:
```4gl
CONSTRUCT BY NAME where_clause ON customers.customerid, customers.companyname
   ON ACTION run
      ACCEPT CONSTRUCT
   ON ACTION exit
      EXIT CONSTRUCT
END CONSTRUCT

IF int_flag THEN
   LET int_flag = FALSE
   RETURN
END IF
```

**Critical Rules:**
- `BY NAME` maps form fields to columns automatically — do NOT add `FROM s_criteria.*`
- ON clause uses `table.column` format
- CONSTRUCT output must match SQL table names (no aliases)
- Use `ON ACTION run` + `ACCEPT CONSTRUCT` for a "Run Report" button

#### 16. base.Channel File I/O Pattern

Reading a text file line-by-line:
```4gl
DEFINE ch base.Channel
DEFINE line STRING

LET ch = base.Channel.create()
TRY
   CALL ch.openFile(filename, "r")
CATCH
   ERROR "Unable to open file: ", filename
   RETURN
END TRY

WHILE TRUE
   LET line = ch.readLine()
   IF ch.isEof() THEN EXIT WHILE END IF
   -- process line
END WHILE
CALL ch.close()
```

**Key Methods:**
- `base.Channel.create()` — create a channel instance
- `ch.openFile(path, mode)` — modes: "r" (read), "w" (write), "a" (append)
- `ch.readLine()` — read one line (returns STRING)
- `ch.isEof()` — check for end of file
- `ch.close()` — close the channel
- Always wrap `openFile()` in TRY/CATCH for error handling

#### 17. generate_temp_filename() Pattern

Create unique temporary file names:
```4gl
FUNCTION generate_temp_filename(prefix, extension)
   DEFINE prefix STRING
   DEFINE extension STRING
   DEFINE ts STRING

   LET ts = util.Datetime.format(CURRENT, "%Y%m%d_%H%M%S")
   RETURN SFMT("%1_%2.%3", prefix, ts, extension)
END FUNCTION
```

**Key Learning:**
- `util.Datetime.format(CURRENT, pattern)` is a **static method** call
- `CURRENT` is a built-in that returns the current datetime
- Pattern uses `%Y`, `%m`, `%d`, `%H`, `%M`, `%S` format specifiers
- Requires `IMPORT util` at the module level

#### 18. Custom Window/Table Styles

Define custom styles in the stylesheet for specialized windows:
```xml
<Style name="Window.reportviewer">
  <StyleAttribute name="windowType" value="modal" />
  <StyleAttribute name="actionPanelPosition" value="bottom" />
  <StyleAttribute name="ringMenuPosition" value="bottom" />
  <StyleAttribute name="toolBarPosition" value="none" />
</Style>

<Style name="Table.reportviewer">
  <StyleAttribute name="fontFamily" value="monospace" />
  <StyleAttribute name="highlightCurrentRow" value="no" />
</Style>
```

**Usage in .per form:**
```per
LAYOUT (TEXT="Report Viewer", STYLE="reportviewer")
  VBOX
    TABLE (STYLE="reportviewer")
    ...
```

**Key Attributes:**
- `windowType="modal"` — makes window a modal dialog
- `highlightCurrentRow="no"` — removes row highlighting in tables
- `fontFamily="monospace"` — ensures text alignment for report output
- `actionPanelPosition`, `ringMenuPosition`, `toolBarPosition` — control UI element visibility

#### 19. REPORT Engine with Text File Output

Generate text file reports:
```4gl
DEFINE rpt_file STRING
LET rpt_file = generate_temp_filename("orders_by_customer", "txt")

START REPORT rpt_orders_customer TO rpt_file

FOREACH c_cursor INTO rec.*
   OUTPUT TO REPORT rpt_orders_customer(rec.*)
   LET count = count + 1
END FOREACH

FINISH REPORT rpt_orders_customer
```

**REPORT function structure:**
```4gl
REPORT rpt_orders_customer(r)
   DEFINE r RECORD ... END RECORD

   ORDER EXTERNAL BY r.companyname

   FORMAT
      PAGE HEADER
         PRINT "Orders By Customer Report"
         PRINT COLUMN 1, "Date: ", TODAY USING "mm/dd/yyyy"
         SKIP 1 LINE

      BEFORE GROUP OF r.companyname
         PRINT COLUMN 1, "Customer: ", r.companyname CLIPPED

      ON EVERY ROW
         PRINT COLUMN 3, r.orderid USING "<<<<<", ...  

      PAGE TRAILER
         PRINT COLUMN 30, "Page ", PAGENO USING "<<<"
END REPORT
```

#### 20. confirm_delete() Dialog Pattern

Defined in `main_lib.4gl`:
```4gl
FUNCTION confirm_delete()
   MENU "Confirm Deletion"
      ATTRIBUTES(COMMENT="Are you sure you want to delete this record?", STYLE="dialog")
      COMMAND "Yes"
         RETURN TRUE
      COMMAND "No"
         EXIT MENU
   END MENU
   RETURN FALSE
END FUNCTION
```

Usage (replaces PROMPT):
```4gl
-- OLD
PROMPT "Are you sure you want to delete this record? (Y/N)" FOR answer
IF answer != "Y" THEN ...

-- NEW
IF NOT confirm_delete() THEN
    ERROR "Record delete canceled"
    LET int_flag = TRUE
    RETURN
END IF
```

#### 21. Building with fgl2p (Multi-Module Linking)

Individual `fglcomp -r module.4gl` cannot resolve cross-module function references.
Use `fgl2p` to compile and link multiple modules together:

```bash
fgl2p -o main_products.42r main_products.4gl main_lib.4gl products.4gl
```

The Makefile manages this automatically with dependency rules.

#### 22. Centralized Base Window Style

Apply actionPanelPosition and ringMenuPosition to ALL windows via a base `Window` style (no dot-suffix):

```xml
<!-- generic.4st -->
<Style name="Window">
  <StyleAttribute name="actionPanelPosition" value="none" />
  <StyleAttribute name="ringMenuPosition" value="none" />
</Style>
```

**Key Points:**
- A base `Window` style applies to ALL windows automatically — no `STYLE=` attribute needed on OPEN WINDOW
- Named styles like `Window.reportviewer` override the base style when explicitly applied with `STYLE="reportviewer"`
- Eliminates repetitive `STYLE="noactions"` on every OPEN WINDOW statement

#### 23. Module Window Style for Secondary Windows

Define a dedicated style for secondary (non-main) module windows that controls window type, action panels, and toolbar visibility:

```xml
<!-- generic.4st -->
<Style name="Window.modulewindow">
  <StyleAttribute name="windowType" value="modal" />
  <StyleAttribute name="actionPanelPosition" value="none" />
  <StyleAttribute name="ringMenuPosition" value="none" />
</Style>
```

Apply it in non-main_* modules:
```4gl
-- All secondary module windows use the modulewindow style
OPEN WINDOW viewCustomerWindow WITH FORM "customers"
   ATTRIBUTES(STYLE="modulewindow")
```

**Key Points:**
- Removes legacy `AT row,col` positioning (terminal-era, not needed in GUI)
- Removes legacy `BORDER`, `MESSAGE LINE LAST`, `ERROR LINE LAST` attributes
- `windowType="modal"` makes secondary windows modal dialogs
- Named style `Window.modulewindow` overrides the base `Window` style when applied
- Consistent behavior across all 32 secondary windows in 17 modules

#### 24. INPUT ARRAY with Modification Triggers

Inline editing pattern using INPUT ARRAY with manual row management:

```4gl
INPUT ARRAY my_arr WITHOUT DEFAULTS FROM sa_record.*
   ATTRIBUTES(UNBUFFERED, INSERT ROW = FALSE, APPEND ROW = FALSE,
              DELETE ROW = FALSE, AUTO APPEND = FALSE)

   BEFORE ROW
      LET curr_row = arr_curr()

   BEFORE FIELD derived_column
      NEXT FIELD next_editable_column  -- Skip display-only fields

   AFTER FIELD editable_id_field
      -- Validate and populate derived fields
      IF NOT validate_id(my_arr[curr_row].id_field) THEN
         NEXT FIELD editable_id_field
      END IF
      LET my_arr[curr_row].description = looked_up_value

   ON ACTION zoom_xxx INFIELD id_field
      -- Lookup logic via BUTTONEDIT
      
   ON ACTION add
      CALL append_new_row(my_arr)
   ON ACTION delete
      IF confirm_delete() THEN
         CALL my_arr.deleteElement(curr_row)
      END IF
   ON ACTION accept
      CALL save_all_changes(my_arr)
      EXIT INPUT
   ON ACTION cancel
      EXIT INPUT
END INPUT
```

**Key Attributes:**
- `UNBUFFERED` — Array changes display immediately
- `INSERT ROW = FALSE` / `APPEND ROW = FALSE` — Custom add via ON ACTION
- `DELETE ROW = FALSE` — Custom delete via ON ACTION with confirmation
- `AUTO APPEND = FALSE` — Prevents automatic row creation on tab-through
- `BEFORE FIELD` + `NEXT FIELD` — Skips derived (display-only) columns in tab order

#### 25. Transactional Save (Delete-Reinsert)

For many-to-many tables like employee-territories, delete all existing and re-insert:

```4gl
FUNCTION save_all_changes(p_arr)
   DEFINE p_arr DYNAMIC ARRAY OF t_empl_terr
   DEFINE idx INTEGER

   BEGIN WORK
   TRY
      DELETE FROM employeeterritories
         WHERE employeeid = contrl_empl_id

      FOR idx = 1 TO p_arr.getLength()
         INSERT INTO employeeterritories (employeeid, territoryid)
            VALUES (p_arr[idx].employeeid, p_arr[idx].territoryid)
      END FOR

      COMMIT WORK
   CATCH
      ROLLBACK WORK
      ERROR "Save failed: ", SQLCA.SQLERRM
   END TRY
END FUNCTION
```

**Key Points:**
- `BEGIN WORK` / `COMMIT WORK` / `ROLLBACK WORK` for transaction control
- TRY/CATCH ensures rollback on any error
- Delete-reinsert is simpler than tracking individual row changes for junction tables

#### 26. Program Icon Mapping

Map program names to Font Awesome icons for automatic window/app icon assignment:

```4gl
FUNCTION build_program_icons()
    CALL add_program_icon("main_employees",    "fa-id-card")
    CALL add_program_icon("main_customers",    "fa-user")
    CALL add_program_icon("bdl_menu",          "fa-rocket")
    -- ... more mappings
END FUNCTION
```

Icons are automatically applied by `form_initializer()` using `ui.Window.getCurrent().setImage()` and `ui.Interface.setImage()`. Adding a mapping to `build_program_icons()` is all that's needed — no code changes in the program itself.

---

## Modernization Patterns

### Pattern 1: Dynamic Array Conversion

**Step 1: Add Type Definition**
```4gl
TYPE t_customer RECORD
   customerid CHAR(5),
   companyname VARCHAR(40),
   contactname VARCHAR(30),
   -- ... other fields
END RECORD
```

**Step 2: Replace Array Declaration**
```4gl
-- OLD
DEFINE customers_arr ARRAY[1000] OF RECORD
   customerid CHAR(5),
   companyname VARCHAR(40),
   -- ...
END RECORD
DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

-- NEW
DEFINE customers_arr DYNAMIC ARRAY OF t_customer
```

**Step 3: Update array operations**

Appending elements:
```4gl
-- OLD: Manual append
LET newIdx = arr_size + 1
LET customers_arr[newIdx] = curr_customer
LET arr_size = newIdx

-- NEW: Use appendElement()
CALL customers_arr.appendElement()
LET customers_arr[customers_arr.getLength()] = curr_customer
```

Deleting elements:
```4gl
-- OLD: Manual deletion with copy loop
FOR idx = 1 TO arr_size
   IF customers_arr[idx].customerid = curr_customer.customerid THEN
      -- complex copy logic
   END IF
END FOR

-- NEW: Use deleteElement()
FOR idx = 1 TO customers_arr.getLength()
   IF customers_arr[idx].customerid = curr_customer.customerid THEN
      CALL customers_arr.deleteElement(idx)
      EXIT FOR
   END IF
END FOR
```

Getting array size:
```4gl
-- OLD
IF arr_size == 0 THEN
   -- handle empty
END IF
LET currentIdx = arr_size

-- NEW
IF customers_arr.getLength() == 0 THEN
   -- handle empty
END IF
LET currentIdx = customers_arr.getLength()
```

### Pattern 2: Form Structure Modernization

**Old Structure (Terminal-style):**
- Flat GRID with all fields
- No container structure
- Basic layout

**New Structure (Web-style):**
```
LAYOUT
  VBOX
    GROUP "Customer Information"
      GRID
        EDIT customerid
        EDIT companyname
        -- standard fields
      END GRID
    END GROUP
    GROUP "Contact Information"
      GRID
        EDIT contactname
        EDIT contacttitle
      END GRID
    END GROUP
  END VBOX
END LAYOUT
```

### Pattern 3: Toolbar with Shared Actions

**Step 1: Define toolbar in .per file**
```
TOOLBAR
  ITEM "first" "First Record"
  ITEM "previous" "Previous Record"
  ITEM "next" "Next Record"
  ITEM "last" "Last Record"
  SEPARATOR
  ITEM "add" "Add New"
  ITEM "modify" "Modify"
  ITEM "delete" "Delete"
  SEPARATOR
  AUTOITEMS (CONTENT=actions)
  SEPARATOR
  ITEM "products" "View Products"
  ITEM "exit" "Exit"
```

**Step 2: Action defaults loaded automatically via form initializer**

Since `init_pgm()` registers a form initializer that calls `frm.loadActionDefaults("generic.4ad")`, no manual loading is needed in main programs:
```4gl
MAIN
    CALL init_pgm()  -- Registers form_initializer + loads styles
    
    OPEN WINDOW mainWindow WITH FORM "customers"
    -- Action defaults are automatically loaded by form_initializer
    -- Base Window style applies actionPanelPosition=none automatically
    
    -- rest of program
END MAIN
```

### Pattern 4: Refresh Operations

Unified refresh function handles Add/Change/Delete:

```4gl
FUNCTION refresh_customers(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"  -- Add
         CALL customers_arr.appendElement()
         LET customers_arr[customers_arr.getLength()] = curr_customers
      WHEN "C"  -- Change
         LET customers_arr[currIdx] = curr_customers
      WHEN "D"  -- Delete
         FOR idx = 1 TO customers_arr.getLength()
            IF customers_arr[idx].customerid = curr_customers.customerid THEN
               CALL customers_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE
END FUNCTION
```

---

## Code Examples

### Complete Type Definition Example

```4gl
TYPE t_supplier RECORD
   supplierid SMALLINT,
   companyname VARCHAR(40),
   contactname VARCHAR(30),
   contacttitle VARCHAR(30),
   address VARCHAR(60),
   city VARCHAR(15),
   region VARCHAR(15),
   postalcode VARCHAR(10),
   country VARCHAR(15),
   phone VARCHAR(24),
   fax VARCHAR(24),
   homepage VARCHAR(100)
END RECORD
```

### Complete Load Function Example

```4gl
FUNCTION load_customers(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE temp_customer t_customer

    LET sql_stmt = " SELECT customerid, companyname, contactname, contacttitle,",
                   " address, city, region, postalcode, country, phone, fax",
                   " FROM customers",
                   " WHERE ", where_clause CLIPPED, " ORDER BY companyname"

    CALL clear_customers()

    PREPARE p_customers FROM sql_stmt
    DECLARE c_customers CURSOR FOR p_customers
    OPEN c_customers

    FOREACH c_customers INTO temp_customer.*
        CALL customers_arr.appendElement()
        LET customers_arr[customers_arr.getLength()] = temp_customer
    END FOREACH

    CLOSE c_customers
    FREE p_customers
    LET currentIdx = 1
END FUNCTION
```

### Complete Navigation Menu Example

```4gl
FUNCTION submenu_customers()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   CALL query_customers()
   IF customers_arr.getLength() == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= customers_arr.getLength()

       CALL load_curr_customers(currentIdx)
       CALL display_curr_customers()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", 
                           customers_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Customers Management"
          COMMAND "First" "View first record in result set"
              LET currentIdx = 1
              EXIT MENU
          COMMAND "Previous" "View previous record in result set"
              LET currentIdx = currentIdx - 1
              IF currentIdx < 1 THEN LET currentIdx = 1 END IF
              EXIT MENU
          COMMAND "Next" "View next record in result set"
              LET currentIdx = currentIdx + 1
              IF currentIdx > customers_arr.getLength() THEN
                  LET currentIdx = customers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = customers_arr.getLength()
              EXIT MENU
          COMMAND "Add" "Add a new customer"
              CALL add_customers()
              IF int_flag == FALSE THEN
                 CALL refresh_customers(currentIdx, "A")
                 LET currentIdx = customers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE
END FUNCTION
```

---

## Modules Converted

### 1. Categories Module
**Purpose:** Manage product categories  
**Fields:** 3 (categoryid, categoryname, description)  
**Status:** 100% Complete

**Key Features:**
- Multi-line description field using TEXTEDIT
- Linked to products module for viewing related products

**Files:**
- `categories.4gl` - Complete CRUD operations
- `categories.per` - Modern form with VBOX/GROUP/GRID
- `main_categories.4gl` - Entry point with generic.4ad loading

### 2. Suppliers Module
**Purpose:** Manage suppliers  
**Fields:** 12 (company info, contact, address, phone, fax, homepage)  
**Status:** 100% Complete

**Key Features:**
- More complex than categories (12 fields)
- Includes homepage URL field
- Linked to products module

**Files:**
- `suppliers.4gl` - Complete CRUD with complex data
- `suppliers.per` - Modern form with proper layout
- `main_suppliers.4gl` - Entry point with generic.4ad loading

### 3. Customers Module
**Purpose:** Manage customers  
**Fields:** 11 (customerid [CHAR], company info, contact, address, phone, fax)  
**Status:** 100% Complete

**Key Features:**
- customerid is CHAR type (unlike other modules)
- Linked to orders module for viewing related orders
- Most complex after suppliers

**Files:**
- `customers.4gl` - Complete CRUD with dynamic arrays
- `customers.per` - Modern form with cleaned layout
- `main_customers.4gl` - Entry point with generic.4ad loading

### 4. Shippers Module
**Purpose:** Manage shipping companies  
**Fields:** 3 (shipperid, companyname, phone)  
**Status:** 100% Complete

**Key Features:**
- Simplest module (3 fields)
- Good reference for minimal modernization pattern
- ON ACTION pattern, confirm_delete(), TOOLBAR, VBOX/GROUP/GRID

**Files:**
- `shippers.4gl` - Complete CRUD operations
- `shippers.per` - Modern form with TOOLBAR and VBOX/GROUP/GRID
- `main_shippers.4gl` - Entry point with generic.4ad loading

### 5. US States Module
**Purpose:** Manage US state reference data  
**Fields:** 4 (stateid, statename, stateabbr, stateregion)  
**Status:** 100% Complete

**Key Features:**
- Reference/lookup data table
- 4 fields, straightforward conversion
- ON ACTION pattern, confirm_delete(), TOOLBAR, VBOX/GROUP/GRID

**Files:**
- `usstates.4gl` - Complete CRUD operations
- `usstates.per` - Modern form with TOOLBAR and VBOX/GROUP/GRID
- `main_usstates.4gl` - Entry point with generic.4ad loading

### 6. Products Module
**Purpose:** Manage products with supplier/category relationships  
**Fields:** 10 (productid, productname, supplierid, categoryid, quantityperunit, unitprice, unitsinstock, unitsonorder, reorderlevel, discontinued)  
**Status:** 100% Complete

**Key Features:**
- **COMBOBOX** for supplierid (populated from suppliers table) and categoryid (populated from categories table)
- **CHECKBOX** for discontinued field (VALUECHECKED=1, VALUEUNCHECKED=0)
- Removed suppliername/categoryname from record (replaced by combobox display)
- Simplified SQL (no JOINs to suppliers/categories)
- populate_supplier_combo() and populate_category_combo() functions
- Combos populated once on form open (not per add/edit)
- Discontinued defaults to 0 in add_products()

**Files:**
- `products.4gl` - Complete CRUD with COMBOBOX/CHECKBOX support
- `products.per` - Modern form with COMBOBOX, CHECKBOX, TOOLBAR, VBOX/GROUP/GRID
- `main_products.4gl` - Entry point, populates combos on form open

### 7. Territories Module
**Purpose:** Manage territories with region assignment  
**Fields:** 3 (territoryid, territorydescription, regionid)  
**Status:** 100% Complete (.4gl + .per + main)

**Key Features:**
- **COMBOBOX** for regionid (populated from region table)
- populate_region_combo() function
- Same combo population pattern as products

**Files:**
- `territories.4gl` - Complete CRUD with COMBOBOX support
- `territories.per` - Modern form with COMBOBOX, TOOLBAR, VBOX/GROUP/GRID
- `main_territories.4gl` - Entry point, populates region combo on form open

### 8. Region Module
**Purpose:** Manage regions  
**Fields:** 2 (regionid, regiondescription)  
**Status:** .per modernized, main_region.4gl modernized (ON ACTION), .4gl still legacy

**Key Features:**
- Simplest module (2 fields)
- main_region.4gl uses modern ON ACTION pattern

**Files:**
- `region.per` - Modern form with TOOLBAR, VBOX/GROUP/GRID
- `main_region.4gl` - Modernized with ON ACTION
- `region.4gl` - Still legacy (pending .4gl conversion)

### 9. Employees Module
**Purpose:** Manage employee records  
**Fields:** 18 (personal info, contact, employment details)  
**Status:** .per modernized, main_employees.4gl modernized, .4gl still legacy

**Key Features:**
- **3 GROUPs** in form: Personal Info, Contact Info, Employment Details
- **COMBOBOX** for titleofcourtesy (static values: Dr., Mr., Mrs., Ms.)
- **DATEEDIT** for birthdate and hiredate
- **BUTTONEDIT** reportsto with ACTION=zoom_employee
- **TEXTEDIT** for notes field with SCROLL
- fullname computed field (NOENTRY)
- populate_courtesy_combo() function in employees.4gl

**Files:**
- `employees.per` - Modern form with 3 groups, COMBOBOX, DATEEDIT, BUTTONEDIT, TEXTEDIT
- `main_employees.4gl` - Modernized with ON ACTION, populates courtesy combo
- `employees.4gl` - Still legacy (pending .4gl conversion), has populate_courtesy_combo()

### 10. Employee Territories Module
**Purpose:** Manage employee-territory assignments (many-to-many)  
**Fields:** 5 (employeeid, fullname, territoryid, territorydescription, regiondescription)  
**Status:** 100% Complete — fully modernized with INPUT ARRAY inline editing

**Key Features:**
- **INPUT ARRAY with modification triggers** for inline editing (replaces DISPLAY ARRAY + separate INPUT)
- **TABLE** container for list view with inline editing
- **BUTTONEDIT** for employeeid (ACTION=zoom_employee) and territoryid (ACTION=zoom_territory)
- **BEFORE FIELD** triggers skip derived columns (fullname, territorydescription, regiondescription)
- **AFTER FIELD** validation on employeeid and territoryid with auto-population of descriptions
- **Transactional save** — BEGIN WORK / DELETE / re-INSERT / COMMIT WORK
- **TYPE t_empl_terr** with DYNAMIC ARRAY
- **validate_territory()** and **validate_empl_id()** as parameterized validation functions
- Two entry points: `terr_by_empl()` (from employees) and `submenu_empl_terr()` (standalone)

**Files:**
- `empl_terr.4gl` - Complete rewrite with INPUT ARRAY, TYPE, DYNAMIC ARRAY, validation, transactional save
- `empl_terr.per` - Modern form with TABLE, BUTTONEDIT, TOOLBAR
- `main_empl_terr.4gl` - Simplified to call `submenu_empl_terr()`

### 11. Orders Module
**Purpose:** Manage customer orders  
**Status:** .per modernized, main/4gl still legacy

**Key Features:**
- **BUTTONEDIT** for customerid (ACTION=zoom_customer) and employeeid (ACTION=zoom_employee)
- **COMBOBOX** for shipvia (shipper selection)
- **DATEEDIT** for orderdate, requireddate, shippeddate
- customername and employeename as NOENTRY display fields

**Files:**
- `orders.per` - Modern form with BUTTONEDIT, COMBOBOX, DATEEDIT
- `main_orders.4gl` - Still legacy (pending conversion)
- `orders.4gl` - Still legacy (pending .4gl conversion)

### 12. Order Details Module
**Purpose:** Manage line items within orders  
**Status:** .per modernized, main/4gl still legacy

**Key Features:**
- **BUTTONEDIT** for orderid (ACTION=zoom_order) and productid (ACTION=zoom_product)
- productname as NOENTRY display field

**Files:**
- `order_details.per` - Modern form with BUTTONEDIT
- `main_order_details.4gl` - Still legacy (pending conversion)
- `order_details.4gl` - Still legacy (pending .4gl conversion)

---

## Key Learnings

### 1. Dynamic Array Methods Are Essential

**Why Important:**
- Eliminate manual size tracking (arr_size, arr_max variables)
- Prevent off-by-one errors in loops
- Cleaner, more maintainable code

**Critical Methods:**
```4gl
CALL array.appendElement()           -- Add to end
CALL array.deleteElement(idx)        -- Remove at index
LET len = array.getLength()          -- Get count
CALL array.clear()                   -- Empty all
```

**Common Mistake to Avoid:**
```4gl
-- WRONG: Using old arr_size after dynamic array conversion
IF currentIdx > arr_size THEN
   -- This will fail if arr_size not updated

-- RIGHT: Always use getLength()
IF currentIdx > array.getLength() THEN
   -- This always works
```

### 2. Form File Structure is Rigid

**Important Rule:**
Form files (.per) must have NO content after `INSTRUCTIONS END`

**What Happened:**
When converting suppliers and customers forms, there were duplicate ATTRIBUTES and INSTRUCTIONS sections left over from old code. These caused issues.

**Solution Used:**
```bash
head -63 suppliers.per > suppliers_clean.per
mv suppliers_clean.per suppliers.per
```

**Lesson:**
Always verify form files end cleanly after INSTRUCTIONS END section.

### 3. Toolbar Syntax (The Hard Way Learned)

**Initial Mistake:**
```
TOOLBAR
  {ACTION "first"}  -- WRONG: ActionScript syntax
END TOOLBAR
```

**Correct Syntax:**
```
TOOLBAR
  ITEM "first" "First Record"
  ITEM "previous" "Previous Record"
  SEPARATOR
  AUTOITEMS (CONTENT=actions)  -- Renders actions from generic.4ad
END TOOLBAR
```

**Key Points:**
- ITEM for toolbar buttons
- SEPARATOR for visual breaks
- AUTOITEMS with CONTENT=actions to include defined actions
- NOT brace syntax like {ACTION}

### 4. Style References Use Different Names

**In .4st File (Definition):**
```xml
<Style name="Window.modulewindow">
```
Uses fully qualified name with `Window.` prefix.

**In OPEN WINDOW Statement (Usage):**
```4gl
OPEN WINDOW viewCustomerWindow WITH FORM "customers"
  ATTRIBUTES(STYLE="modulewindow")
```
Uses just the style name part, NOT the qualified name.

**Why?**
The qualified name is a namespace/category prefix. When using it, Genero understands the category from context.

**Style Hierarchy:**
- Base `Window` style applies to ALL windows (actionPanelPosition=none, ringMenuPosition=none)
- Named styles like `Window.modulewindow` or `Window.reportviewer` override the base when explicitly applied
- Main program windows use the base style (no STYLE= needed)
- Secondary module windows use `STYLE="modulewindow"` for modal behavior

### 5. Action Defaults Must Have Images

**Discovery:** Orders action had no icon in toolbar

**Root Cause:** generic.4ad didn't define an action for "orders"

**Solution Added:**
```xml
<ActionDefault name="orders"
  text="Orders"
  image="fa-shopping-cart"
  comment="View related orders" />
```

**Font Awesome Icons Used:**
Navigation: fa-step-backward, fa-arrow-left, fa-arrow-right, fa-step-forward  
Data Ops: fa-plus (add), fa-pencil (modify), fa-trash (delete)  
Standard: fa-check (accept), fa-ban (cancel), fa-power-off (exit)  
Related: fa-list (products), fa-shopping-cart (orders), fa-truck (supplier), fa-tag (category)  
Search: find (built-in)

### 6. Type Definitions Improve Code Quality

**Benefits:**
- Self-documenting code (clear what fields exist)
- Compiler catches typos in field names
- Easier refactoring when schema changes
- Can be reused across functions

**Pattern:**
```4gl
TYPE t_EntityName RECORD
   field1 TYPE,
   field2 TYPE,
   -- ... clearly named fields
END RECORD

DEFINE entities_arr DYNAMIC ARRAY OF t_EntityName
DEFINE current_entity t_EntityName
```

### 7. Main Programs Load Global Configuration

**Pattern Used (Current — with Form Initializer):**
```4gl
MAIN
    CALL init_pgm()  -- Loads styles + registers form_initializer
    
    OPEN WINDOW mainWindow WITH FORM "customers"
    -- Action defaults auto-loaded by form_initializer
    -- Base Window style disables action panels automatically
    
    -- Module-specific combo population (if needed)
    CALL populate_supplier_combo()
    
    -- Module-specific menu
END MAIN
```

**Key Points:**
- `init_pgm()` called first — loads generic.4st AND registers `form_initializer`
- `form_initializer(frm ui.Form)` automatically calls `frm.loadActionDefaults("generic.4ad")` for every form
- No need for `DEFINE f ui.Form` / `LET f = ...getForm()` boilerplate
- Base `Window` style applies actionPanelPosition=none, ringMenuPosition=none to all windows automatically
- Secondary module windows use `STYLE="modulewindow"` for modal behavior with no toolbar
- Module-specific initialization (combo population) still done in MAIN after OPEN WINDOW

### 8. ON ACTION Replaces ON KEY

**Why Important:**
- ON KEY uses key codes tied to terminal emulators (CTRL-P, ACCEPT)
- ON ACTION uses named actions that work with toolbars, buttons, and keyboard
- Actions map to generic.4ad for consistent icons and accelerators

**Migration Pattern:**
```4gl
-- Before (terminal-dependent)
ON KEY (ACCEPT)
    ACCEPT INPUT
ON KEY (CONTROL-P)
    LET int_flag = TRUE
    EXIT INPUT

-- After (platform-independent)
ON ACTION accept
    ACCEPT INPUT
ON ACTION cancel
    LET int_flag = TRUE
    EXIT INPUT
```

**Applied In:** CONSTRUCT, INPUT BY NAME across all modules.

### 9. confirm_delete() is a Reusable Pattern

**Why Important:**
- PROMPT requires terminal-style text input ("Y/N")
- confirm_delete() uses MENU with STYLE="dialog" for GUI dialog
- Defined once in main_lib.4gl, used everywhere
- Returns BOOLEAN for clean conditional logic

**Applied In:** categories, suppliers, shippers, usstates, products, customers modules.

### 10. COMBOBOX Population Strategy

**Key Insight:** Populate comboboxes ONCE when the form opens in MAIN, not in each add/edit function.

**Why:**
- Combobox items persist for the lifetime of the window
- Populating on every add/edit is wasteful
- The main program has the right scope (after OPEN WINDOW, before menu loop)

**Pattern:**
```4gl
MAIN
    CALL init_pgm()  -- Action defaults handled by form_initializer
    OPEN WINDOW mainWindow WITH FORM "products"
    
    CALL populate_supplier_combo()
    CALL populate_category_combo()
    -- ... start menu loop ...
END MAIN
```

**Static vs Dynamic Combos:**
- **Dynamic** (from database): `populate_supplier_combo()`, `populate_category_combo()`, `populate_region_combo()`
- **Static** (fixed values): `populate_courtesy_combo()` — uses hardcoded `cb.addItem()` calls

### 11. Form Initializer Eliminates Boilerplate

**Key Insight:** `ui.Form.setDefaultInitializer()` registers a callback that fires automatically every time any form opens.

**Before (repeated in every main program):**
```4gl
DEFINE f ui.Form
LET f = ui.Window.getCurrent().getForm()
CALL f.loadActionDefaults("generic.4ad")
```

**After (registered once in init_pgm):**
```4gl
-- In main_lib.4gl
CALL ui.Form.setDefaultInitializer("form_initializer")

FUNCTION form_initializer(frm ui.Form)
    CALL frm.loadActionDefaults("generic.4ad")
END FUNCTION
```

**Benefits:**
- Code removed from 9 main programs
- New modules get action defaults automatically
- Single point of change for global form initialization

### 12. TABLE Container Syntax

**Key Insight:** TABLE rows use pipe `|` separators between columns, and the row template must be repeated to match the SCREEN RECORD array size.

**Correct:**
```per
TABLE
{
  [emplid   |fullname            |terrid   ]
  [emplid   |fullname            |terrid   ]
  [emplid   |fullname            |terrid   ]
}
END

INSTRUCTIONS
  SCREEN RECORD sa_empl_terr[3](...);
END
```

**Wrong (causes -2029 error):**
```per
-- Adjacent brackets instead of pipes:
[emplid   ][fullname            ][terrid   ]

-- Mismatched row count vs SCREEN RECORD size:
TABLE (HEIGHT=10)
{  -- only 1 row template
  [emplid   |fullname            |terrid   ]
}
-- with SCREEN RECORD sa_empl_terr[10] → error!
```

### 11. Build System: fgl2p vs fglcomp

**Key Insight:** Individual `fglcomp -r module.4gl` fails when the module calls functions defined in other .4gl files (e.g., `confirm_delete()` from `main_lib.4gl`).

**Solution:** Use `fgl2p` to compile and link multiple modules together:
```bash
fgl2p -o main_products.42r main_products.4gl main_lib.4gl products.4gl
```

**Best Practice:** Always use the Makefile which has proper dependency rules. The root `hrm/Makefile` handles all cross-module linking automatically.

### 12. CHECKBOX Defaults Matter

**Key Insight:** When adding a new record, CHECKBOX fields may display inconsistently if not initialized.

**Solution:** Always set a default value before INPUT:
```4gl
LET curr_products.discontinued = 0
```

This ensures the checkbox appears unchecked for new records.

### 13. CONSTRUCT BY NAME Does Not Take FROM Clause

**Key Insight:** `CONSTRUCT BY NAME` maps form fields to columns automatically. Do NOT add `FROM s_criteria.*`.

**Wrong:**
```4gl
CONSTRUCT BY NAME where_clause FROM s_criteria.* ON customers.customerid
```

**Correct:**
```4gl
CONSTRUCT BY NAME where_clause ON customers.customerid, customers.companyname
```

### 14. SQL Aliases Break CONSTRUCT WHERE Clauses

**Key Insight:** CONSTRUCT generates WHERE clauses using the exact column names from the ON clause (e.g., `customers.customerid = 'ALFKI'`). If SQL uses aliases (`FROM customers c`), the WHERE clause won't match.

**Solution:** Use full table names in SQL — no aliases:
```4gl
-- WRONG (alias mismatch)
LET sql_stmt = "SELECT c.customerid FROM customers c WHERE ", where_clause

-- CORRECT (full table names match CONSTRUCT output)
LET sql_stmt = "SELECT customers.customerid FROM customers WHERE ", where_clause
```

**Note:** `STRING.replace()` does NOT exist in Genero BDL 6.00.02, so you cannot programmatically swap alias names.

### 15. FORMONLY TYPE STRING Is Invalid in .per Files

**Key Insight:** The `.per` form compiler does not accept `TYPE STRING` for FORMONLY attributes. Use SQL-compatible types instead.

**Wrong:**
```per
EDIT line_text = FORMONLY.line_text TYPE STRING;
```

**Correct:**
```per
EDIT line_text = FORMONLY.line_text TYPE VARCHAR, SCROLL;
```

Valid types: CHAR, VARCHAR, INTEGER, SMALLINT, DATE, DATETIME, DECIMAL, FLOAT, etc.

### 16. TABLES Section Must Come After LAYOUT

**Key Insight:** In .per forms, the `TABLES` section must appear AFTER the `LAYOUT` section, not before `TOOLBAR`.

### 17. util.Datetime.format() Is a Static Method

**Key Insight:** `util.Datetime.format(CURRENT, "%Y%m%d_%H%M%S")` is a static method call on the `util.Datetime` class. It does not require an instance.

Requires `IMPORT util` at the module level.

### 18. Custom Styles for Specialized Windows

**Key Insight:** Create named styles in generic.4st for specialized windows rather than using generic built-in styles like "dialog".

**Benefits:**
- Full control over window behavior (modal, toolbar visibility, action panels)
- Table-level styling (font family, row highlighting)
- Reusable across multiple forms
- Style name on LAYOUT maps to `Window.name`, style on TABLE maps to `Table.name`

### 19. Shared Files Belong in the Shared Library Node

**Key Insight:** In the .4pw project file, files used by multiple applications (like report_helper.4gl) should be placed in the Shared Library node, not duplicated in each Application node.

---

## Troubleshooting

### Problem: "Function X has not been defined"

**Cause:** Functions exist in separate .4gl files not compiled together

**Solution:**
```bash
# Compile both files together
fglcomp -r --make -M customers.4gl main_customers.4gl
```

**OR**

```bash
# Create a Makefile or build script
cd src && fglcomp -r --make -M *.4gl
```

### Problem: Toolbar buttons have no icons

**Cause:** Action not defined in generic.4ad

**Solution:**
1. Check generic.4ad has action definition
2. Add missing action:
```xml
<ActionDefault name="actionname"
  text="Display Text"
  image="fa-icon-name"
  comment="Description" />
```
3. Verify Font Awesome icon name is correct

3. Recompile

### Problem: Form file compilation fails

**Cause:** Extra content after INSTRUCTIONS END

**Solution:**
1. Read file to find last valid line of INSTRUCTIONS
2. Use head to truncate:
```bash
head -N formfile.per > formfile_clean.per
mv formfile_clean.per formfile.per
```
3. Verify with fglcomp formfile.per

### Problem: Multiple occurrences match in replace_string_in_file

**Cause:** Search pattern too generic (matches multiple locations)

**Solution:**
- Include more context lines (3-5 before and after)
- Make surrounding code unique
- Use specific function names or distinctive code patterns
- Or use targeted single replacements instead of multi-replace

### Problem: STYLE attribute not recognized

**Cause:** Style not loaded or incorrect style name reference

**Solution:**
1. Verify generic.4st exists and has style definition
2. Verify init_pgm() calls ui.Interface.loadStyles()
3. Check style name format: `STYLE="modulewindow"` (not `STYLE="Window.modulewindow"`)
4. Verify OPEN WINDOW uses correct form name

---

## Using the Genero AI Agent Effectively

### 1. Start with a Clear Request

**Good:**
> "Convert categories.4gl to use DYNAMIC ARRAY OF t_category instead of ARRAY[1000]"

**Vague:**
> "Modernize the code"

### 2. Provide Context When Needed

**Helpful:**
> "I noticed arr_size is used in 5 functions. Can you update all of them?"

**Less Helpful:**
> "Fix the array stuff"

### 3. Ask for Verification

**Good:**
> "Can you compile customers.4gl to check for syntax errors?"

**Assumes:**
> Just assumes it works without checking

### 4. Break Complex Tasks into Steps

**Better Approach:**
1. "Convert type definitions first"
2. "Update array declarations"
3. "Fix all arr_size references"
4. "Test compilation"

**Instead of:**
> "Modernize everything at once"

### 5. Use the Tools Effectively

**Parallel Operations:**
- Use multi_replace_string_in_file for independent changes
- Read multiple file sections in parallel
- Search and read together when possible

**Sequential Operations:**
- Use read_file to understand context before editing
- Use grep_search to find similar patterns
- Compile after major changes to verify

### 6. Document Your Patterns

As you work, the AI learns patterns:
- It notices what directory structure looks like
- It learns how your functions are organized
- It remembers what files depend on what
- Use descriptions to reference past work

**Example:**
> "Apply the same pattern you used in suppliers.4gl to customers.4gl"

---

## Files Reference

### Created Files

**generic.4ad** - Centralized action definitions
- Location: `/Users/mikefolcher/4js-github/fgl-darwin/hrm/src/`
- Purpose: Shared actions with icons and accelerators (auto-loaded via form initializer)
- **36 Actions:** first, previous, next, last, query, add, modify, delete, products, orders, supplier, category, region, employees, territories, customer, employee, shipper, details, reportsto, order, product, select, zoom_employee, zoom_territory, zoom_customer, zoom_product, zoom_order, zoom, run, accept, cancel, **launch**, exit

**generic.4st** - Centralized stylesheets
- Location: `/Users/mikefolcher/4js-github/fgl-darwin/hrm/src/`
- Purpose: Shared styles for consistent UI
- Includes: **Window** (base style — actionPanelPosition=none, ringMenuPosition=none for all windows), **Window.modulewindow** (modal, no action panel/ring menu/toolbar for secondary module windows), Window.reportviewer, Table.reportviewer, Table.MenuTree styles

**report_helper.4gl** - Report viewer utility library
- Location: `/Users/mikefolcher/4js-github/fgl-darwin/hrm/src/`
- Purpose: Read text files and display in DISPLAY ARRAY dialog
- Function: `display_report_file(rpt_file STRING)` — reads file via base.Channel, displays in modal viewer

**report_viewer.per** - Report viewer form
- Location: `/Users/mikefolcher/4js-github/fgl-darwin/hrm/src/`
- Purpose: Modal dialog form for viewing report text output
- Features: TABLE with monospace font, no row highlighting, STRETCHCOLUMNS, STYLE="reportviewer"

**rpt_orders_by_customer.per** / **rpt_orders_by_employee.per** / **rpt_orders_by_product.per** / **rpt_orders_by_daterange.per** - Report criteria forms
- Location: `/Users/mikefolcher/4js-github/fgl-darwin/hrm/src/`
- Purpose: CONSTRUCT criteria entry for each report
- Features: TOOLBAR with run/exit, database column fields for CONSTRUCT

### Modified Files

**main_lib.4gl**
- Added: `CALL ui.Interface.loadStyles()` in init_pgm()
- Added: `CALL ui.Form.setDefaultInitializer("form_initializer")` in init_pgm()
- Added: `form_initializer(frm ui.Form)` function — auto-loads generic.4ad for every form, sets window/app icons
- Added: `confirm_delete()` function (MENU with STYLE="dialog")
- Added: `build_program_icons()` — maps 17 programs to Font Awesome icons (including bdl_menu→fa-rocket, 4 reports→fa-file-text)
- Added: `get_program_icon()`, `add_program_icon()` — icon registry functions
- Added: `generate_temp_filename()` — creates unique filenames using `util.Datetime.format()`
- Purpose: Initialize global styles, register form initializer, program icon registry, and shared utility functions

**categories.4gl**
- Converted: All arr_size/arr_max → getLength()
- Added: TYPE t_category definition

**categories.per**
- Redesigned: Modern toolbar and form layout
- Cleaned: Removed duplicate sections

**main_categories.4gl**
- Updated: Load generic.4ad
- Updated: STYLE="noactions" in OPEN WINDOW

**suppliers.4gl**
- Converted: All arr_size/arr_max → getLength()
- Added: TYPE t_supplier definition
- Updated: refresh_suppliers() to use dynamic array methods

**suppliers.per**
- Redesigned: Modern layout for 12 fields
- Cleaned: Removed old form code

**main_suppliers.4gl**
- Updated: Load generic.4ad
- Updated: STYLE="noactions" in OPEN WINDOW

**customers.4gl**
- Converted: All arr_size/arr_max → getLength()
- Added: TYPE t_customer definition
- Updated: refresh_customers() to use dynamic array methods
- Updated: ON KEY → ON ACTION, PROMPT → confirm_delete()

**customers.per**
- Redesigned: Modern layout for 11 fields
- Cleaned: Removed old form code

**main_customers.4gl**
- Updated: Load generic.4ad
- Updated: STYLE="noactions" in OPEN WINDOW
- Added: ui.Form variable definition

**shippers.4gl**
- Converted: All arr_size/arr_max → getLength()
- Added: TYPE t_shipper definition
- Updated: ON ACTION, confirm_delete(), dynamic arrays

**shippers.per**
- Redesigned: Modern form with TOOLBAR, VBOX/GROUP/GRID

**main_shippers.4gl**
- Updated: Load generic.4ad, STYLE="noactions"

**usstates.4gl**
- Converted: All arr_size/arr_max → getLength()
- Added: TYPE t_usstate definition
- Updated: ON ACTION, confirm_delete(), dynamic arrays

**usstates.per**
- Redesigned: Modern form with TOOLBAR, VBOX/GROUP/GRID

**main_usstates.4gl**
- Updated: Load generic.4ad, STYLE="noactions"

**products.4gl**
- Converted: All arr_size/arr_max → getLength()
- Added: TYPE t_product definition (10 fields, no suppliername/categoryname)
- Added: populate_supplier_combo(), populate_category_combo() functions
- Removed: validate_supplier_field(), validate_category_field(), CTRL-T lookup logic
- Simplified: SQL with no JOINs to suppliers/categories
- Updated: ON ACTION, confirm_delete(), dynamic arrays, discontinued defaults to 0

**products.per**
- Redesigned: Modern form with TOOLBAR, VBOX/GROUP/GRID
- Added: COMBOBOX for supplierid and categoryid
- Added: CHECKBOX for discontinued (VALUECHECKED=1, VALUEUNCHECKED=0)

**main_products.4gl**
- Updated: Load generic.4ad, STYLE="noactions"
- Added: Calls populate_supplier_combo() and populate_category_combo() after form opens

**empl_terr.4gl**
- Rewritten: Complete modernization from DISPLAY ARRAY + INPUT to INPUT ARRAY with modification triggers
- Added: TYPE t_empl_terr, DYNAMIC ARRAY, manage_empl_terr(), append_new_row(), save_all_changes()
- Added: validate_territory() (4 return values), validate_empl_id() (parameterized)
- Added: BEFORE FIELD triggers to skip derived columns, AFTER FIELD validation
- Added: Transactional save with BEGIN WORK / COMMIT WORK / ROLLBACK WORK
- Removed: Static arrays, arr_size/arr_max, set_count, curr_empl_terr record, 8+ legacy functions

**main_empl_terr.4gl**
- Rewritten: Simplified from MENU with COMMAND blocks to single CALL submenu_empl_terr()

**bdl_menu.per**
- Added: TOOLBAR with ITEM launch, SEPARATOR, ITEM exit
- Removed: ACTION DEFAULTS section (now sourced from generic.4ad)

**bdl_menu.4gl**
- Added: Reports root category (id=6) with 4 children in build_menu()
- Removed: STYLE="noactions" from OPEN WINDOW (centralized in generic.4st)

**generic.4st**
- Changed: Renamed `Window.noactions` to base `Window` style (applies to all windows)
- Effect: All windows get actionPanelPosition=none, ringMenuPosition=none automatically
- Added: `Window.modulewindow` style (windowType=modal, actionPanelPosition=none, ringMenuPosition=none)
- Effect: All 32 secondary module windows use consistent modal style via `STYLE="modulewindow"`

**generic.4ad**
- Added: "launch" ActionDefault (fa-rocket, acceleratorName=Return)
- Total: 36 action defaults

---

## Conclusion

The Genero AI Agent effectively assisted with a complex modernization project by:

1. **Learning patterns from initial examples** - Once categories module was done, it applied the same pattern to all subsequent modules
2. **Understanding code structure** - It recognized function relationships and dependencies
3. **Handling systematic changes** - Dynamic array conversions, ON KEY → ON ACTION migration, PROMPT → confirm_delete() across all modules
4. **Fixing issues intelligently** - Form cleanup, toolbar syntax correction, style reference fixes, combobox timing, checkbox defaults
5. **Catching errors** - Compilation checks, verification of changes
6. **Adding new UI patterns** - COMBOBOX population from database, CHECKBOX with defaults, dialog-style confirmation
7. **Refactoring shared code** - confirm_delete() extracted to main_lib.4gl, applied everywhere

The result: **12 modules with modern forms**, **9 fully modernized** from legacy terminal-style code to modern web-ready applications, **4 report modules** with CONSTRUCT criteria and text file output, a **reusable report viewer** with modal dialog and monospace table, **centralized action definitions (36 actions) and stylesheets**, **centralized base Window style**, **dedicated module window style** (32 secondary windows across 17 modules), **form initializer hook with program icon registry**, **proper record types**, **dynamic arrays**, **ON ACTION events**, **INPUT ARRAY with modification triggers**, **COMBOBOX/CHECKBOX/BUTTONEDIT/DATEEDIT/TEXTEDIT controls**, **TABLE containers**, **base.Channel file I/O**, **REPORT engine**, **GUI tree menu** with 6 categories and 16 leaf programs, and **shared utility functions** throughout.

### Key Success Factors

✅ Clear initial direction with example module  
✅ Iterative feedback and refinement  
✅ Verification through compilation  
✅ Attention to systematic patterns  
✅ Learning from mistakes (toolbar syntax, style references, combobox timing, TABLE pipe syntax)  
✅ Testing and incremental progress tracking  
✅ Shared code extraction (confirm_delete, init_pgm, form_initializer)  
✅ Advanced controls (COMBOBOX, CHECKBOX, BUTTONEDIT, DATEEDIT, TEXTEDIT) for complex modules  
✅ Form initializer hook to eliminate boilerplate  
✅ Comprehensive action defaults audit with validated icon names  
✅ CONSTRUCT BY NAME for flexible report criteria  
✅ REPORT engine with text file output  
✅ Reusable report viewer (base.Channel + DISPLAY ARRAY in modal dialog)  
✅ Custom styles for specialized windows and tables  
✅ Genero project file (.4pw) management  
✅ Centralized base Window style (eliminates per-window STYLE attributes)  
✅ GUI tree menu with toolbar, reports category, and program icon registry  
✅ INPUT ARRAY with modification triggers for inline editing (empl_terr)  
✅ Transactional save pattern with BEGIN WORK / COMMIT WORK / ROLLBACK WORK  
✅ DEFINE placement discipline (all DEFINEs at function top, never inside IF/FOR)  
✅ Module window style for consistent secondary window behavior (32 windows, 17 modules)  
✅ Legacy attribute cleanup (removed AT row,col, BORDER, MESSAGE LINE LAST, ERROR LINE LAST)  

### Recommended Next Steps

1. Convert remaining .4gl modules to modern patterns: region.4gl, employees.4gl, orders.4gl, order_details.4gl
2. Convert remaining main programs: main_orders.4gl, main_order_details.4gl
3. Implement zoom/lookup window functions: employee_lookup(), territory_lookup(), customer_lookup(), product_lookup(), order_lookup()
4. Test the modernized application with real data
5. Add master-detail patterns for orders/order_details
6. Add report export options (CSV, PDF via Genero Report Engine)
7. Document application architecture for team reference

---

**Document Created:** February 9, 2026  
**Last Updated:** February 16, 2026  
**Genero Version:** 6.00.02-202512011639  
**Database:** Northwind  
**Project Location:** `/Users/mikefolcher/4js-github/fgl-darwin/`
