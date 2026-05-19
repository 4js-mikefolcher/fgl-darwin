# Genero BDL Master/Detail Pattern Reference

This document distills the master/detail implementation from `mstr_dtl_order.4gl` and `md_order_details.4gl` into a repeatable pattern. It identifies which behaviors are entity-specific and which can be extracted into shared code.

---

## Architecture Overview

```
┌─────────────────────┐     ┌──────────────────────────┐
│  Entry Point Module  │────▶│   Master/Detail Module    │
│  (mstr_dtl_*.4gl)   │     │   (md_*.4gl)              │
│                      │     │                           │
│  - DATABASE stmt     │     │  - Module-level state     │
│  - MAIN              │     │  - Search/list DIALOG     │
│  - init_pgm()        │     │  - Input DIALOG           │
│  - call md module    │     │  - View DISPLAY ARRAY     │
└─────────────────────┘     │  - CRUD orchestration     │
                             └────────┬─────────────────┘
                                      │
          ┌───────────────────────────┼───────────────────────┐
          ▼                           ▼                       ▼
┌─────────────────┐     ┌──────────────────┐    ┌──────────────────┐
│  model_header   │     │  model_detail    │    │  shared libs     │
│  (model_*.4gl)  │     │  (model_*.4gl)   │    │                  │
│                 │     │                  │    │  - md_helper     │
│  t_header TYPE  │     │  t_detail TYPE   │    │  - model_helper  │
│  validateRec()  │     │  validateRec()   │    │  - dialog_prompt │
│  insertRec()    │     │  insertRec()     │    │  - main_lib      │
│  updateRec()    │     │  updateRec()     │    └──────────────────┘
│  deleteRec()    │     │  deleteRec()     │
└─────────────────┘     └──────────────────┘
```

---

## Module-by-Module Breakdown

### 1. Entry Point: `mstr_dtl_order.4gl`

Minimal bootstrapper. Every master/detail program follows this exact shape:

```
IMPORT FGL main_lib
IMPORT FGL md_<entity>
DATABASE <dbname>
MAIN
    CALL init_pgm()
    CALL mstr_detail_<entity>()
END MAIN
```

**Shared code potential**: This module is already a one-liner template. No extraction needed.

---

### 2. Master/Detail Controller: `md_order_details.4gl`

This is the main module containing all UI orchestration. It breaks down into these functional areas:

#### 2a. Module-Level State

```
PRIVATE TYPE t_<entity>_result_rec RECORD     -- Flattened list row (display columns + action images)
PRIVATE TYPE t_detail_input_rec RECORD         -- Detail row with UI extras (rowedit, rowdelete)

PRIVATE DEFINE <entity>_result_list  DYNAMIC ARRAY OF t_<entity>_result_rec   -- Search results
PRIVATE DEFINE curr_result_rec       t_<entity>_result_rec                     -- Current list row

PRIVATE DEFINE <entity>_header_dict  DICTIONARY OF model_<header>.t_<header>  -- Full header cache
PRIVATE DEFINE curr_<header>_rec     model_<header>.t_<header>                -- Current header

PRIVATE DEFINE <entity>_detail_dict  DICTIONARY OF DYNAMIC ARRAY OF model_<detail>.t_<detail>
PRIVATE DEFINE curr_detail_list      t_detail_input_list                       -- Current details

PRIVATE DEFINE listIdx   INTEGER    -- Current position in result list
PRIVATE DEFINE detailIdx INTEGER    -- Current position in detail list
```

**Key design decisions**:
- **Dictionary caching** (`order_header_dict`, `order_detail_dict`) keyed by primary key allows navigating between records without re-querying the database
- **Result list type** is a flattened projection of header + aggregates + row action images, separate from the full header type
- **Detail input type** extends the model detail type with `rowedit`/`rowdelete` image columns and a computed `totalprice`
- **`util.JSONObject`** bridges between the display type and model type via `toOrderDetail()` / `fromOrderDetail()` methods

**Shared code potential**: The dictionary caching pattern, result list + action images, and JSON bridging methods are fully generic. A base module could provide dictionary management functions parameterized by key type.

---

#### 2b. Search/List DIALOG (`mstr_detail_<entity>`)

This is the main entry point function. Structure:

```
PUBLIC FUNCTION mstr_detail_<entity>()
    DEFINE where_clause STRING
    DEFINE selected_option SMALLINT

    OPEN WINDOW mainWindow WITH FORM "<list_form>"
        ATTRIBUTES(STYLE="noaction")

    LET selected_option = NULL
    DIALOG ATTRIBUTES(UNBUFFERED)

        CONSTRUCT where_clause ON <search_columns> FROM <search_fields>
            -- BUTTONEDIT zoom actions for search fields
        END CONSTRUCT

        DISPLAY ARRAY <result_list> TO s_table.*
        END DISPLAY

        -- Action dispatchers (set selected_option, ACCEPT DIALOG)
        ON ACTION ACCEPT    -- context-sensitive: search vs view
        ON ACTION EXIT / CLOSE
        ON ACTION search / adv_search / excel_export
        ON ACTION ADD / MODIFY / DELETE / VIEW

        AFTER DIALOG
            -- Capture listIdx from DIALOG.getCurrentRow("s_table")
            -- CASE on selected_option to dispatch operations
            -- After search: reset listIdx, setCurrentRow
            -- After CRUD: set_current_recs, setCurrentRow
            CONTINUE DIALOG
    END DIALOG

    CLOSE WINDOW mainWindow
END FUNCTION
```

**Pattern rules**:
1. `selected_option` is always set BEFORE `ACCEPT DIALOG` or `EXIT DIALOG`
2. `AFTER DIALOG` does all the work (routing, calling functions, refreshing)
3. `CONTINUE DIALOG` at the end of `AFTER DIALOG` keeps the dialog alive
4. `listIdx` is captured from `DIALOG.getCurrentRow("s_table")` before dispatching
5. Row action images (`rowview`, `rowedit`, `rowdelete`) in the DISPLAY ARRAY trigger `ON ACTION view/modify/delete`
6. The ACCEPT action is context-sensitive: if cursor is in search fields, it searches; if in the table, it views

**Shared code potential**: The DIALOG shell and action routing are highly repetitive. A callback-based pattern or code generation template could standardize this.

---

#### 2c. Search Execution (`execute_search`)

```
PRIVATE FUNCTION execute_search(where_clause STRING) RETURNS ()
    -- Build SQL joining header + detail + lookup tables
    -- Clear all caches (result_list, header_dict, detail_dict)
    -- FOREACH through cursor:
    --   If same header ID: accumulate totals, append detail
    --   If new header ID: create result row, populate header dict, append first detail
    -- Display filter label
END FUNCTION
```

**Key behaviors**:
- Single query joins header + details + all lookup tables
- Groups by header ID using cursor-break logic (compare current ID to previous)
- Populates three caches simultaneously: result_list, header_dict, detail_dict
- Aggregates (totalqty, totalamt) are computed during load, not by SQL
- Detail dict entries are keyed by header primary key as STRING

**Shared code potential**: The cursor-break accumulation loop is entity-specific due to column mappings, but the cache management pattern (clear three caches, populate on cursor break) could be formalized.

---

#### 2d. Cache Synchronization Functions

These functions keep the three caches and the current record state consistent:

| Function | Purpose | When Called |
|---|---|---|
| `set_current_recs()` | Loads `curr_*` variables from dicts using `listIdx` | After navigation, after search, after sync |
| `sync_current_recs(is_new)` | Writes `curr_*` back to result_list + header_dict, calls `update_detail_recs` + `set_current_recs` | After save (add or edit) |
| `update_detail_recs()` | Rebuilds detail_dict from `curr_detail_list`, recomputes aggregates in result_list, sets row action images | After detail changes |
| `delete_current_recs()` | Removes entry from all three caches, adjusts `listIdx` | After header delete |
| `delete_current_recs_detail(rowIdx)` | Removes one detail row, calls `update_detail_recs` + `set_current_recs` | After detail delete |
| `init_new_order()` | Initializes `curr_order_rec` with defaults, clears detail list | Before add mode |

**Data flow**:
```
Database ──▶ execute_search ──▶ [result_list, header_dict, detail_dict]
                                         │
                                    set_current_recs
                                         │
                                         ▼
                                [curr_result_rec, curr_order_rec, curr_detail_list]
                                         │
                                   (user edits)
                                         │
                                  sync_current_recs
                                         │
                                         ▼
                                [result_list, header_dict, detail_dict] ──▶ (back to display)
```

**Shared code potential**: HIGH. These functions follow a completely generic pattern. A shared module could provide:
- `md_cache_set_current(listIdx, result_list, header_dict, detail_dict)` 
- `md_cache_sync(is_new, listIdx, curr_rec, result_list, header_dict)`
- `md_cache_delete(listIdx, result_list, header_dict, detail_dict)`

The challenge is Genero's lack of generics — the types are entity-specific. However, using `util.JSONObject` as an intermediary (already proven with `toOrderDetail`/`fromOrderDetail`) could make this work.

---

#### 2e. Header + Detail Input DIALOG (`input_md_order`)

```
PRIVATE FUNCTION input_md_order(input_mode CHAR(1)) RETURNS (BOOLEAN)
    DIALOG ATTRIBUTES(UNBUFFERED)
        SUBDIALOG header_input(input_mode)
        SUBDIALOG details_input(input_mode)

        ON ACTION ACCEPT
            ACCEPT DIALOG

        ON ACTION EXIT
            LET int_flag = TRUE
            EXIT DIALOG

        AFTER DIALOG
            -- Validate header via model.validateRec(input_mode)
            -- If valid: call save_order(input_mode)
    END DIALOG

    IF int_flag THEN
        LET int_flag = FALSE
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
```

**Pattern rules**:
1. Only the outer DIALOG defines ON ACTION ACCEPT/CANCEL — subdialogs must NOT
2. `AFTER DIALOG` runs validation then persistence
3. `int_flag` is used as the cancel signal (set in EXIT action, cleared after check)
4. The function is wrapped by `main_input_md()` which handles OPEN/CLOSE WINDOW

**Shared code potential**: The DIALOG shell with SUBDIALOG + accept/exit/validate/save is fully generic. A template could parameterize just the subdialog names and validation call.

---

#### 2f. Header SUBDIALOG (`header_input`)

```
PRIVATE DIALOG header_input(input_mode CHAR(1))
    INPUT curr_<header>_rec.* FROM s_<header>.*
        ATTRIBUTES(WITHOUT DEFAULTS = TRUE)

        -- BUTTONEDIT zoom actions (ON ACTION zoom_*)
        -- AFTER FIELD validation for foreign keys
        -- AFTER INPUT: full record validation

    END INPUT
END DIALOG
```

**Pattern rules**:
1. `ATTRIBUTES(WITHOUT DEFAULTS = TRUE)` — always, since we pre-populate
2. NO `UNBUFFERED` in subdialog attributes (causes issues with parent DIALOG)
3. NO `ON ACTION ACCEPT/CANCEL` — parent DIALOG owns these
4. Zoom actions: call lookup function, set ID + display name, optionally cascade defaults
5. `AFTER FIELD` on foreign key fields: validate via model function, set display name
6. `AFTER INPUT`: validate full record via `model.validateRec(input_mode)`

**Shared code potential**: LOW for the body (entity-specific fields/validations), but the structural pattern (INPUT with zoom actions + AFTER FIELD validation + AFTER INPUT validation) is always the same.

---

#### 2g. Detail SUBDIALOG (`details_input`)

```
PRIVATE DIALOG details_input(input_mode CHAR(1))
    INPUT ARRAY curr_detail_list FROM s_details.*
        ATTRIBUTES(WITHOUT DEFAULTS = TRUE, INSERT ROW = FALSE, AUTO APPEND = TRUE)

        BEFORE ROW
            -- Get currentIdx, auto-extend array, set parent FK

        -- BUTTONEDIT zoom actions
        -- ON CHANGE / AFTER FIELD for foreign key validation
        -- AFTER FIELD for calculated fields

        AFTER ROW
            -- Validate row if has data

        AFTER INPUT
            -- Clean up empty rows (array_cleanup)
            -- Cross-row validation (e.g., duplicate check)

    END INPUT
END DIALOG
```

**Pattern rules**:
1. `INSERT ROW = FALSE, AUTO APPEND = TRUE` — user adds via auto-append or toolbar
2. `BEFORE ROW`: extend array if needed, set parent FK on new rows
3. `AFTER ROW`: validate populated rows
4. `AFTER INPUT`: clean empty rows, then cross-row business rules
5. Row calculations happen on `AFTER FIELD` for numeric fields

**Shared code potential**: `array_cleanup()` is fully generic — takes a `ui.Dialog` and cleans rows where the primary identifier is NULL. Could be in `md_helper`.

---

#### 2h. View Mode with Navigation (`view_md_order`)

```
PRIVATE FUNCTION view_md_order() RETURNS (BOOLEAN)
    OPEN WINDOW detailWindow WITH FORM "<detail_form>"

    LET has_changes = FALSE

    WHILE int_flag == FALSE

        DISPLAY curr_<header>_rec.* TO s_<header>.*

        DISPLAY ARRAY curr_detail_list TO s_details.*
            ATTRIBUTES(CANCEL=FALSE, ACCEPT=FALSE)

            BEFORE DISPLAY
                -- Update status, reset selected_option

            -- CRUD actions: set selected_option, EXIT DISPLAY
            ON ACTION ADD / APPEND / MODIFY / DELETE
            ON ACTION deleterow / updaterow   -- row-level actions

            -- Navigation actions: adjust listIdx, ACCEPT DISPLAY
            ON ACTION FIRST / PREVIOUS / NEXT / LAST

            ON ACTION EXIT / CLOSE

            AFTER DISPLAY
                -- set_current_recs, re-display header, set row, update status
                CONTINUE DISPLAY

        END DISPLAY

        -- CASE on selected_option to handle operation
        -- Operations return to WHILE loop, DISPLAY ARRAY re-enters

    END WHILE

    CLOSE WINDOW detailWindow
    RETURN has_changes
END FUNCTION
```

**Pattern rules**:
1. `WHILE` loop wraps `DISPLAY ARRAY` — EXIT DISPLAY breaks out for operations, ACCEPT DISPLAY refreshes for navigation
2. `CANCEL=FALSE, ACCEPT=FALSE` — view mode disables default accept/cancel
3. `AFTER DISPLAY` + `CONTINUE DISPLAY` keeps the display alive during navigation
4. Navigation: adjust `listIdx`, call `ACCEPT DISPLAY` to trigger `AFTER DISPLAY` refresh
5. CRUD operations: `EXIT DISPLAY`, handle in CASE block, loop back
6. `has_changes` tracks if any modifications were made (returned to caller)
7. Detail row actions: `updaterow` uses `detail_single_input("C")` then `update_md_detail()`; `deleterow` calls `delete_md_detail()` inline
8. `APPEND` action: extends array, calls `DIALOG.appendRow("s_details")` to sync UI array, then EXIT DISPLAY for input

**Shared code potential**: The WHILE + DISPLAY ARRAY + navigation + dispatch pattern is highly repetitive. Navigation actions (FIRST/PREVIOUS/NEXT/LAST) are identical across all entities.

---

#### 2i. Detail Single Input (`detail_single_input`)

Used in view mode for editing/adding individual detail rows outside the parent DIALOG:

```
PRIVATE FUNCTION detail_single_input(input_mode CHAR(1)) RETURNS ()
    VAR arrIdx = detailIdx

    IF input_mode == "A" THEN
        -- Initialize new row with defaults
    ELSE
        -- Save original for cancel recovery
        LET orig_detail_rec = curr_detail_list[arrIdx]
    END IF

    INPUT curr_detail_list[arrIdx].* WITHOUT DEFAULTS FROM s_details[arrIdx].*
        ATTRIBUTE(UNBUFFERED)

        ON ACTION accept / cancel
        -- Zoom actions, field validation, calculations (same as details_input)

    END INPUT

    IF int_flag THEN
        -- Cancel: delete new row or restore original
    END IF
END FUNCTION
```

**Pattern rules**:
1. Uses `INPUT ... FROM s_details[arrIdx].*` (specific array index) — runs AFTER EXIT DISPLAY
2. `ATTRIBUTE(UNBUFFERED)` is correct here since this is standalone INPUT, not subdialog
3. Must define own `ON ACTION accept/cancel` since no parent DIALOG
4. On cancel: delete new row (`deleteElement`) or restore from backup (`orig_detail_rec`)
5. Caller is responsible for persisting via `update_md_detail()` / `delete_md_detail()`

---

#### 2j. Persistence Functions

| Function | Behavior |
|---|---|
| `save_order(input_mode)` | BEGIN WORK, insert/update header, delete+reinsert all details, COMMIT/ROLLBACK, sync caches |
| `delete_md_order()` | Confirm, BEGIN WORK, delete details then header, COMMIT, delete from caches |
| `update_md_detail(rowIdx, input_mode)` | Insert or update single detail row, update caches |
| `delete_md_detail(rowIdx)` | Confirm, BEGIN WORK, delete single detail, COMMIT, delete from caches |

**Pattern rules**:
1. Header save uses delete+reinsert for all details (simpler than tracking individual changes)
2. Detail-level operations persist individually (used from view mode)
3. All use TRY/CATCH with explicit BEGIN WORK/COMMIT/ROLLBACK
4. On failure, set `int_flag = TRUE` to signal cancel to the calling DIALOG
5. On success, call cache sync functions

**Shared code potential**: The TRY/BEGIN WORK/COMMIT/ROLLBACK/CATCH wrapper is generic. Could be a helper function that takes a callback, but Genero doesn't have first-class functions. The pattern is best documented as a template.

---

#### 2k. Utility Functions

| Function | Purpose | Shared? |
|---|---|---|
| `calcPrice()` | Compute `totalprice` from unit fields | Entity-specific |
| `toOrderDetail()` | Convert display rec to model rec via `util.JSONObject` | Pattern is generic |
| `fromOrderDetail(src)` | Convert model rec to display rec via `util.JSONObject`, set action images | Pattern is generic |
| `default_unitprice_from_product()` | Cascade default from FK lookup | Entity-specific |
| `load_shipvia_combo(cbx)` | Populate combobox from table | Entity-specific |
| `array_cleanup(dlg)` | Remove rows with NULL primary identifier | **Fully generic** |
| `export_orders_to_excel()` | Export result list to Excel via poiapi | Pattern is generic |
| `update_view_status()` | Format and display status bar message | Pattern is generic |
| `append_search_detail(...)` | Add detail to dict during search | Entity-specific |
| `calc_line_total(...)` | Calculate line total from fields | Entity-specific |

---

## Supporting Modules

### `md_helper.4gl` — Action Constants

```
PUBLIC CONSTANT cQuit = 0
PUBLIC CONSTANT cSearch = 1
PUBLIC CONSTANT cAdd = 2
PUBLIC CONSTANT cEdit = 3
PUBLIC CONSTANT cDelete = 4
PUBLIC CONSTANT cView = 5
PUBLIC CONSTANT cAdvSearch = 6
PUBLIC CONSTANT cExport = 7
PUBLIC CONSTANT cAppend = 8

PUBLIC CONSTANT cViewImage = "fa-eye"
PUBLIC CONSTANT cEditImage = "fa-pencil"
PUBLIC CONSTANT cDeleteImage = "fa-trash"
```

**Already shared.** No changes needed.

### `model_helper.4gl` — Validation Return Type

```
PUBLIC TYPE t_valid_rec RECORD
    valid_status BOOLEAN,
    valid_msg STRING
END RECORD

PUBLIC FUNCTION (self t_valid_rec) init() RETURNS ()
PUBLIC FUNCTION (self t_valid_rec) success(msg STRING) RETURNS ()
PUBLIC FUNCTION (self t_valid_rec) failed(msg STRING) RETURNS ()
```

**Already shared.** No changes needed.

### `dialog_prompt.4gl` — Delete Confirmation

```
PUBLIC FUNCTION delete_prompt() RETURNS (BOOLEAN)
```

**Already shared.** No changes needed.

### `main_lib.4gl` — Application Bootstrap

```
FUNCTION init_pgm()          -- OPTIONS, styles, form initializer
FUNCTION form_initializer()   -- Load action defaults, toolbars, icons
FUNCTION confirm_delete()     -- Legacy delete prompt (use dialog_prompt instead)
FUNCTION generate_temp_filename()
FUNCTION build_program_icons()
```

**Already shared.** `confirm_delete()` is duplicated by `dialog_prompt.delete_prompt()` — could be removed.

---

## Model Module Contract

Every header and detail model module must implement this interface:

```
PUBLIC TYPE t_<entity> RECORD
    <primary_key>  LIKE <table>.<pk>,
    -- ... other fields ...
END RECORD

PUBLIC FUNCTION (self t_<entity>) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
    -- mode "A" = add, "C" = change
    -- Returns t_valid_rec with valid_status and valid_msg

PUBLIC FUNCTION (self t_<entity>) insertRec() RETURNS (t_valid_rec)
    -- INSERT INTO, sets self.<pk> = sqlca.sqlerrd[2] on success

PUBLIC FUNCTION (self t_<entity>) updateRec() RETURNS (t_valid_rec)
    -- UPDATE WHERE <pk>, checks sqlerrd[3] == 1

PUBLIC FUNCTION (self t_<entity>) deleteRec() RETURNS (t_valid_rec)
    -- DELETE WHERE <pk>, checks sqlerrd[3] == 1
```

---

## Form Requirements

### List Form (`mstr_*_list.per`)

- `LAYOUT TAG` must reference toolbar file (e.g., `"search_list.4tb"`)
- `SCREEN RECORD s_search(...)` — search fields bound to CONSTRUCT
- `SCREEN RECORD s_table(...)` — result list bound to DISPLAY ARRAY
- Row action images: `IMAGE formonly.rowview ACTION=view`, `IMAGE formonly.rowedit ACTION=modify`, `IMAGE formonly.rowdelete ACTION=delete`
- Search field BUTTONEDIT with `ACTION=zoom_<entity>`
- AGGREGATE rows for counts/totals

### Detail Form (`md_*_details.per`)

- `LAYOUT STYLE="noaction" TAG` must reference toolbar file (e.g., `"master_detail.4tb"`)
- `SCREEN RECORD s_<header>(...)` — header fields bound to INPUT/DISPLAY
- `SCREEN RECORD s_details(...)` — detail table bound to INPUT ARRAY/DISPLAY ARRAY
- BUTTONEDIT fields with `ACTION=zoom_<lookup>` for foreign keys
- COMBOBOX with `INITIALIZER=load_<combo>` for dropdown fields
- Row action images: `IMAGE formonly.rowedit ACTION=updaterow`, `IMAGE formonly.rowdelete ACTION=deleterow`
- AGGREGATE rows for detail counts/totals
- Status label: `LABEL formonly.status_label, SIZEPOLICY=DYNAMIC, STYLE="info"`

---

## Candidates for Shared Code Extraction

### High Priority — Direct Extraction

| Function/Pattern | Current Location | Proposed Shared Location | Notes |
|---|---|---|---|
| `array_cleanup(dlg)` | md_order_details.4gl | md_helper.4gl | Pass screen record name + primary field check as params |
| Action constants | md_helper.4gl | Already shared | - |
| `t_valid_rec` + methods | model_helper.4gl | Already shared | - |
| `delete_prompt()` | dialog_prompt.4gl | Already shared | - |
| `update_view_status()` pattern | md_order_details.4gl | md_helper.4gl | Generic version: takes listIdx, list length, key value, label values |
| `export_to_excel()` pattern | md_order_details.4gl | md_helper.4gl | Generic version: takes screen record name + JSONArray |

### Medium Priority — Template Patterns

These can't be directly extracted as shared functions (Genero lacks generics/callbacks) but should be copied-and-adapted from a template:

| Pattern | Template |
|---|---|
| Entry point module | `IMPORT FGL main_lib` / `IMPORT FGL md_<entity>` / `DATABASE` / `MAIN` |
| Search/list DIALOG shell | CONSTRUCT + DISPLAY ARRAY + action routing + AFTER DIALOG dispatch |
| Input DIALOG shell | DIALOG + SUBDIALOG header + SUBDIALOG detail + validate + save |
| View WHILE/DISPLAY ARRAY | Navigation (FIRST/PREV/NEXT/LAST) + CRUD dispatch + has_changes tracking |
| Header SUBDIALOG | INPUT with zoom actions + AFTER FIELD FK validation |
| Detail SUBDIALOG | INPUT ARRAY with BEFORE ROW init + zoom + AFTER ROW validate + AFTER INPUT cleanup |
| Detail single INPUT | Standalone INPUT with cancel recovery (backup/restore or deleteElement) |
| Save function | TRY/BEGIN WORK/insert-or-update header/delete+reinsert details/COMMIT/CATCH ROLLBACK |
| Delete function | Confirm/TRY/BEGIN WORK/delete children then parent/COMMIT/CATCH ROLLBACK |

### Lower Priority — Structural Patterns

| Pattern | How to Generalize |
|---|---|
| Dictionary caching (header_dict, detail_dict) | Document as convention; type-specific but structure is identical |
| `toModelRec()` / `fromModelRec()` via `util.JSONObject` | Every detail input type needs these; document the 3-line pattern |
| Result list type with action images | Convention: always end with `rowview STRING, rowedit STRING, rowdelete STRING` |
| Cache sync functions (set/sync/update/delete) | Template with comments marking entity-specific lines |

---

## Checklist for Creating a New Master/Detail Module

1. **Create model modules**: `model_<header>.4gl`, `model_<detail>.4gl`
   - Define `t_<entity>` TYPE matching database columns + display fields
   - Implement `validateRec()`, `insertRec()`, `updateRec()`, `deleteRec()`
   
2. **Create forms**: `mstr_<entity>_list.per`, `md_<entity>_details.per`
   - Define SCREEN RECORDs: `s_search`, `s_table`, `s_<header>`, `s_details`
   - Add row action images, BUTTONEDIT zoom actions, AGGREGATEs
   
3. **Create entry point**: `mstr_dtl_<entity>.4gl`
   - IMPORT main_lib + md module, DATABASE, MAIN with init_pgm + entry function
   
4. **Create controller**: `md_<entity>.4gl`
   - Define module state: result list type, detail input type, dictionaries, current recs
   - Implement `fromModelRec()` / `toModelRec()` JSON bridge methods
   - Implement `execute_search()` with cursor-break grouping
   - Implement cache functions: `set_current_recs`, `sync_current_recs`, `update_detail_recs`, `delete_current_recs`, `delete_current_recs_detail`, `init_new_<entity>`
   - Implement `mstr_detail_<entity>()` — search/list DIALOG
   - Implement `main_input_md()` — window wrapper
   - Implement `input_md_<entity>()` — input DIALOG with subdialogs
   - Implement `header_input()` SUBDIALOG
   - Implement `details_input()` SUBDIALOG
   - Implement `detail_single_input()` — standalone detail INPUT
   - Implement `view_md_<entity>()` — view with navigation
   - Implement `save_<entity>()`, `delete_md_<entity>()`, `update_md_detail()`, `delete_md_detail()`
   
5. **Create lookup modules** (if not existing): `ui_<lookup>.4gl`
   - Lookup functions called from zoom actions

6. **Create advanced search** (optional): `advsearch_<entity>.4gl`

7. **Register in main_lib**: Add program icon mapping in `build_program_icons()`

8. **Add to build**: Include in Makefile/project file
