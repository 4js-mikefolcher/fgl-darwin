# List View Feature — Suppliers Module

This document describes how the list view feature is implemented in the suppliers module. It can be used as a reference for implementing the same pattern in other modules.

## Overview

The list view provides an alternative way to browse supplier records. Instead of navigating one record at a time using First/Previous/Next/Last, the user can switch to a scrollable table that displays all search results at once. From the list view, the user can add, modify, or delete records using the same functions as the single-record view.

## Files Involved

| File | Purpose |
|------|---------|
| `hrm/src/suppliers.4gl` | Contains `list_suppliers_view()` function and the "List" menu command in `submenu_suppliers()` |
| `hrm/src/suppliers_list.per` | Form definition for the list view (TABLE layout) |
| `hrm/src/suppliers.per` | Single-record form — updated to include the `list` toolbar item |
| `hrm/src/generic.4ad` | Action defaults — defines the `list` action with `fa-table` icon |
| `hrm/src/generic.4st` | Style file — defines the `Window.modulewindow` style used by the list window |
| `hrm/src/Makefile` | Build system — includes `suppliers_list.per` compilation targets |
| `fgl-darwin.4pw` | Project file — includes `suppliers_list.per` in the `main_suppliers` application |

## Implementation Details

### 1. Form Definition (`suppliers_list.per`)

The list view form uses a `TABLE` container inside a `VBOX` layout. Key aspects:

- **TOOLBAR**: Provides `add`, `modify`, `delete`, and `exit` action buttons.
- **TABLE**: Displays 10 visible rows with `DOUBLECLICK=modify` so double-clicking a row triggers the modify action.
- **Columns**: All 12 fields from the suppliers table are displayed (c1–c12), separated by pipe `|` characters in the grid definition.
- **ATTRIBUTES**: Each VARCHAR column uses `NOENTRY` (read-only in the display array) and `SCROLL` (allows horizontal scrolling to see full content).
- **SCREEN RECORD**: Named `suppliers_list[10]` mapping to all supplier fields.

```per
TOOLBAR
  ITEM add
  SEPARATOR
  ITEM modify
  ITEM delete
  SEPARATOR
  ITEM exit
END

LAYOUT (TEXT="Suppliers List View")
  VBOX
    TABLE (DOUBLECLICK=modify)
    {
     ID  Company        Contact        Title    ...
    [c1 |c2            |c3            |c4      |...]
    }
    END
  END
END

ATTRIBUTES
  c1 = formonly.supplierid TYPE INTEGER, NOENTRY;
  c2 = formonly.companyname TYPE VARCHAR, NOENTRY, SCROLL;
  -- ... remaining fields ...
END

INSTRUCTIONS
  SCREEN RECORD suppliers_list[10](supplierid, companyname, contactname,
    contacttitle, address, city, region, postalcode, country,
    phone, fax, homepage);
END
```

### 2. List View Function (`list_suppliers_view()`)

Located in `suppliers.4gl`, this function:

1. **Opens a modal window** using the `suppliers_list` form with `STYLE="modulewindow"`.
2. **Displays a status message** showing the count of records.
3. **Runs a `DISPLAY ARRAY`** binding `suppliers_arr` to `suppliers_list.*`.
4. **Handles actions** for add, modify, and delete — reusing the same functions as the single-record view (`add_suppliers()`, `edit_suppliers()`, `delete_suppliers()`).
5. **Refreshes the array** after each successful operation via `refresh_suppliers()`.
6. **Closes the window** when the user exits.

```4gl
FUNCTION list_suppliers_view()
   DEFINE selectedIdx INTEGER

   OPEN WINDOW listSuppliersWindow WITH FORM "suppliers_list"
      ATTRIBUTES(STYLE="modulewindow")

   MESSAGE "Displayed ", suppliers_arr.getLength() USING "<<<<<", " suppliers"

   DISPLAY ARRAY suppliers_arr TO suppliers_list.*
       ON ACTION add
           CALL add_suppliers()
           IF int_flag == FALSE THEN
              CALL refresh_suppliers(suppliers_arr.getLength(), "A")
           END IF
       ON ACTION modify
           LET selectedIdx = ARR_CURR()
           IF selectedIdx >= 1 AND selectedIdx <= suppliers_arr.getLength() THEN
               CALL load_curr_suppliers(selectedIdx)
               CALL edit_suppliers()
               IF int_flag == FALSE THEN
                   CALL refresh_suppliers(selectedIdx, "C")
               END IF
           ELSE
               ERROR "Please select a supplier"
           END IF
       ON ACTION delete
           LET selectedIdx = ARR_CURR()
           IF selectedIdx >= 1 AND selectedIdx <= suppliers_arr.getLength() THEN
               CALL load_curr_suppliers(selectedIdx)
               CALL delete_suppliers()
               IF int_flag == FALSE THEN
                   CALL refresh_suppliers(selectedIdx, "D")
               END IF
           ELSE
               ERROR "Please select a supplier"
           END IF
       ON ACTION exit
           EXIT DISPLAY
       ON KEY (ESCAPE)
           EXIT DISPLAY
   END DISPLAY

   CLOSE WINDOW listSuppliersWindow

END FUNCTION
```

**Key design decisions:**

- **`ARR_CURR()`** retrieves the currently selected row index in the DISPLAY ARRAY.
- **`load_curr_suppliers(selectedIdx)`** is called before modify/delete to populate the `curr_suppliers` module variable with the selected record. This is necessary because `edit_suppliers()` and `delete_suppliers()` operate on `curr_suppliers`.
- **`refresh_suppliers(idx, operation)`** synchronizes the array after a database change. The operation codes are: `"A"` (add), `"C"` (change), `"D"` (delete).
- The add action does not need `load_curr_suppliers()` because `add_suppliers()` initializes a blank record internally.

### 3. Menu Integration (`submenu_suppliers()`)

A "List" command was added to the `MENU "Suppliers Management"` block in `submenu_suppliers()`:

```4gl
COMMAND "List" "Switch to list view"
    CALL list_suppliers_view()
    EXIT MENU
```

This is placed after the "Delete" command and before the "Products" command. When selected, it opens the list view as a modal window. After the list view closes, control returns to the single-record navigation loop.

### 4. Toolbar Button (`suppliers.per`)

The `list` action item was added to the single-record form's toolbar:

```per
TOOLBAR
  ...
  ITEM list
  SEPARATOR
  ITEM exit
END
```

### 5. Action Default (`generic.4ad`)

The `list` action is defined in the action defaults file so that all modules using this action get consistent text and icon:

```xml
<ActionDefault name="list"
  text="List"
  image="fa-table"
  comment="Switch to list view" />
```

### 6. Window Style (`generic.4st`)

The list view window uses `STYLE="modulewindow"`, defined in the presentation styles file:

```xml
<Style name="Window.modulewindow">
  <StyleAttribute name="windowType" value="modal" />
  <StyleAttribute name="actionPanelPosition" value="none" />
  <StyleAttribute name="ringMenuPosition" value="none" />
</Style>
```

This makes the window modal (blocks interaction with the parent window), hides the action panel, and hides the ring menu — the toolbar provides all user actions.

## Build System

### Makefile (`hrm/src/Makefile`)

Three additions were made:

1. **FORMS list**: Added `suppliers_list.per`.
2. **FORM_TARGETS**: Added `$(BINDIR)/suppliers_list.42f`.
3. **Build rule**:
   ```makefile
   $(BINDIR)/suppliers_list.42f: suppliers_list.per
   	$(FORMCOMP) $<
   	mv suppliers_list.42f $(BINDIR)/
   ```
4. **Convenience target**: Added `$(BINDIR)/suppliers_list.42f` to the `suppliers:` target so `make suppliers` builds the list form too.

### Project File (`fgl-darwin.4pw`)

Added `suppliers_list.per` to the `main_suppliers` application node:

```xml
<Application binaryName="main_suppliers" ...>
  ...
  <File filePath="hrm/src/suppliers.per"/>
  <File filePath="hrm/src/suppliers_list.per"/>
</Application>
```

## Replicating for Other Modules

To add a list view to another module (e.g., `shippers`):

1. **Create `<module>_list.per`** — Define a TABLE form with the appropriate columns for that module's record type.
2. **Add `list_<module>_view()` function** — Follow the same DISPLAY ARRAY pattern, using the module's existing add/edit/delete/refresh functions.
3. **Add "List" command to the submenu** — Insert `COMMAND "List"` calling the new function.
4. **Add `ITEM list` to the single-record form's toolbar**.
5. **Update the Makefile** — Add the new `.per` to FORMS, FORM_TARGETS, build rules, and the module convenience target.
6. **Update `fgl-darwin.4pw`** — Add the new `.per` file to the module's application node.
7. **Build and deploy** — Run `make` and copy the `.42f` to the runtime `bin/` directory if needed.
