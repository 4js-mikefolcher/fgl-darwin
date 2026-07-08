# Genero Ghost Client (GGC) Reference

Version 6.00 — Compiled from official documentation.

---

## Overview

The Genero Ghost Client (GGC) is a **Java framework** for automated testing of Genero applications. It acts as a "ghost client" that does **not render a GUI** — it interacts with the application programmatically through the AUI (Abstract User Interface) tree.

**Key characteristics:**
- Tests business logic and UI behavior without a visible front-end
- Can test against GBC, GDC, GMA, or GMI front-end configurations
- Connects via **direct TCP** to the DVM or through the **Genero Application Server (GAS)**
- Does **not require modifying** the application under test
- Supports **unit, load, and performance testing**
- Tests are written in **Genero BDL** (recommended) or **Java** (for critical load testing only)

**Two ways to create test scenarios:**
1. **Write by hand** using the BDL or Java API
2. **Generate from a recorded log** — record a guilog during manual interaction, then use `ggcgen` to produce test code

**Limitations:**
- Parallel dialogs are not supported
- Drag and drop is not supported

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                   Test Scenario (.4gl)                │
│  IMPORT FGL ggc                                      │
│  ggc.registerScenario(FUNCTION play_0)               │
│  ggc.play()                                          │
└──────────┬───────────────────────────────┬───────────┘
           │                               │
    TCP (direct)                     UA (via GAS)
           │                               │
           ▼                               ▼
┌──────────────────┐           ┌───────────────────────┐
│  DVM (fglrun)    │           │  GAS (httpdispatch)   │
│  Application     │           │    ▼                   │
│  under test      │           │  DVM (fglrun)         │
└──────────────────┘           │  Application           │
                               └───────────────────────┘
```

**Main framework interfaces:**

| Interface | Role |
|---|---|
| **SessionManager** | Manages Scenario instances for incoming VM connections |
| **Scenario** | Handles the test — its `Play` method receives the Client instance |
| **ScenarioProvider** | Created when there are multiple scenarios |
| **Client** | Provides all methods to interact with the DVM: delays, events, introspection |

---

## Installation and Configuration

### Environment Setup

1. Source the GGC environment script:
   ```bash
   source $GGCDIR/envggc        # sets CLASSPATH, GGCDIR, FGLLDPATH
   ```

2. Source the Genero compiler environment:
   ```bash
   source $FGLDIR/envcomp        # sets FGLDIR, PATH for fglcomp/fglrun
   ```

3. Ensure JDK 17 or 21 is installed:
   ```bash
   export JAVA_HOME=/path/to/jdk
   export JDK_HOME=${JAVA_HOME}
   export PATH=${JAVA_HOME}/bin:${PATH}
   java --version
   ```

### GGC Directory Structure

| Directory | Contents |
|---|---|
| `bin/` | Wrapper scripts for `ggcadmin` and `ggcgen` |
| `doc/javadoc/` | Java API documentation |
| `jars/` | Java jar files (HTTP, logging, encoding) |
| `lib/` | `ggc.42m` — the compiled BDL API module |
| `src/quick-start/` | Tutorial source files, `ggc-quick-start.gar` |
| `src/samples/demo/` | Java test samples |
| `src/samples/ggclib/` | `ggc.4gl` — BDL API source |
| `template/bdl/` | BDL code generation templates |
| `template/java/` | Java code generation templates |

---

## Writing BDL Tests

### Test Structure

Every BDL test follows this skeleton:

```4gl
IMPORT FGL ggc

MAIN
    CALL ggc.setApplicationName("myapp")
    CALL ggc.parseOptions()
    CALL ggc.registerScenario(FUNCTION play_0)
    CALL ggc.play()
    EXIT PROGRAM 0
END MAIN

PRIVATE FUNCTION play_0()
    -- Test code here
    CALL ggc.end()
END FUNCTION
```

**MAIN block sequence:**
1. `ggc.setApplicationName()` — name of the application to test
2. `ggc.parseOptions()` — parses command line options, initializes config, connects to BDL scenario server
3. `ggc.registerScenario()` — registers one or more scenario functions (run in registration order)
4. `ggc.play()` — starts execution of all registered scenarios

### Generate a Skeleton

```bash
ggcgen bdl --skeleton myapp_tests
```
Creates `myapp_tests.4gl` with the MAIN/play_0 skeleton.

### Compile

```bash
fglcomp myapp_tests.4gl     # produces myapp_tests.42m
```

### Run

**Step 1 — Start the GGC BDL server:**
```bash
ggcadmin startbdlserver &
```

**Step 2a — Run via GAS (UA mode):**
```bash
fglrun myapp_tests.42m ua --url http://localhost:6394/ua/r/myapp
```

**Step 2b — Run via direct connection (TCP mode):**
```bash
fglrun myapp_tests.42m tcp --command-line "fglrun myapp"
```

**Step 3 — Stop the server:**
```bash
ggcadmin stopbdlserver
```

**Forward GUI to GDC** (watch the test execute visually):
```bash
fglrun myapp_tests.42m ua --url http://localhost:6394/ua/r/myapp -f localhost:0
```

---

## Recording Logs and Generating Scenarios

### Recording Methods

**Method 1 — Direct connection (DVM guilog):**
```bash
fglrun --start-guilog=myapp.guilog myapp
```
Interact with the app, then close it. Produces `myapp.guilog`.

**Method 2 — Via GAS (DVM guilog):**
Add to the application's `.xcf` config:
```xml
<DVM>fglrun --start-guilog=/tmp/myapp.log</DVM>
```
Then run the app through the GAS normally. Close to finish recording.

**Method 3 — GDC log:**
In GDC Monitor > Debug panel > set file path > click Record. Launch app, interact, close app, stop recording.

**Method 4 — GBC log (requires GBC 1.00.53+):**
```
http://localhost:6394/ua/r/myapp?recordGbcLog=1
```
A "Recording log..." label appears. Close the app and click "Get the GBC logs" to download.

**Snapshots:** Press ALT+F12 during recording to capture a snapshot of the AUI tree state.

### Generate Scenario from Log

```bash
ggcgen bdl myapp.guilog           # creates myapp.4gl
ggcgen java myapp.guilog          # creates scenario/myapp_provider.java
```

**With checks enabled:**
```bash
ggcgen bdl --check-all myapp.guilog
ggcgen bdl --check-window --check-form --check-value myapp.guilog
```

**With custom templates:**
```bash
ggcgen bdl --template-directory ${MY_TEMPLATES} --check-all myapp.guilog
```

**Without wait instructions:**
```bash
ggcgen bdl --no-wait myapp.guilog
```

**Snapshot-only checks:**
```bash
ggcgen bdl --check-on-snapshot=all myapp.guilog
```

---

## Scenario Failures vs Check Failures

### Scenario Failure
An **unrecoverable error** that **stops test execution**. Example: calling an action that doesn't exist.
```4gl
CALL ggc.action("accept")    -- fails if no active "accept" action
```

### Check Failure
An **unexpected value** that is **logged but does NOT stop** execution.
```4gl
CALL ggc.checkFieldValue("formonly.name", "Wall clock")  -- logs failure, continues
```

### Treat Checks as Failures
Use `--check-as-failure` to make check failures stop execution:
```bash
fglrun myscenario ua --check-as-failure --url http://localhost:6394/ua/r/myapp
```

### Debug with GUI Logs on Error
Use `--guilog-on-error` to generate guilog files when a scenario fails:
```bash
fglrun myapp_test.42m ua --url http://localhost:6394/ua/r/myapp --guilog-on-error
```
Produces two files:
- `.guilog` — full AUI exchange history
- `.guiend` — AUI state at time of failure

Replay for debugging:
```bash
fglrun --run-guilog ggc-ua-<id>.guilog
```

---

## Templates

Templates are code snippets in `$GGCDIR/template/bdl/` (or `/java/`) expanded by `ggcgen` when generating scenarios from logs.

**Two types:**
- **Event templates** (`event_*.4gl`) — generate code that triggers actions (key events, set focus, set value, sort table)
- **Check templates** (`check_*.4gl`) — generate code that verifies state (window name, field value, form title)

**Example — table sort template:**
```
# Template: event_table_sort.4gl
CALL ggc.sortTable("$(tableName)", "$(columnName)", ggc.$(sortTypeBdl))
```
Generated output:
```4gl
CALL ggc.sortTable("sr_prices", "name", ggc.SORT_ASCENDING)
```

**Customizing templates:**
1. Copy templates from `$GGCDIR/template/bdl/` to your own directory
2. Modify as needed
3. Use `--template-directory` to point to your custom directory
4. Alternate check templates available at `$GGCDIR/template/bdl/alternate-checks/`

---

## BDL API Reference

Import: `IMPORT FGL ggc`

### Types

#### FrontCallAnswer
```4gl
TYPE FrontCallAnswer RECORD
    type STRING,
    status STRING,
    errorMessage STRING,
    returnValues DYNAMIC ARRAY OF RECORD
        isNull BOOLEAN,
        value STRING,
        index INTEGER,
        dataType STRING
    END RECORD
END RECORD
```

**Methods:**
| Method | Description |
|---|---|
| `success()` | Mark as successful |
| `functionNotFound()` | Set "Function not found" error |
| `moduleNotFound()` | Set "Module not found" error |
| `notProcessed()` | Leave the front call unprocessed |
| `returnInteger(value INTEGER)` | Add an integer return value |
| `returnString(value STRING)` | Add a string return value |
| `stackError()` | Set "Stack error" |
| `userError(errorMessage STRING)` | Set a custom error message |

#### FrontCallRequest
```4gl
TYPE FrontCallRequest RECORD
    frontCall RECORD
        moduleName STRING,
        functionName STRING,
        paramCount INTEGER,
        returnCount INTEGER,
        parameters DYNAMIC ARRAY OF RECORD
            dataType STRING,
            isNull BOOLEAN,
            value STRING
        END RECORD
    END RECORD,
    errorMessage STRING
END RECORD
```

**Methods:**
| Method | Description |
|---|---|
| `getFunctionName() RETURNS STRING` | Get the front call function name |
| `getModuleName() RETURNS STRING` | Get the front call module name |
| `getParameterCount() RETURNS INTEGER` | Get parameter count |
| `getParameterValue(index INTEGER) RETURNS STRING` | Get parameter value at index |
| `getReturnCount() RETURNS INTEGER` | Get return values count |

#### ggc.Message
```4gl
TYPE ggc.Message RECORD
    isErrorMessage INTEGER,
    message STRING
END RECORD
```

#### ggc.Action
```4gl
TYPE ggc.Action RECORD
    name STRING,
    active BOOLEAN,
    text STRING
END RECORD
```

#### ggc.Statistics
```4gl
TYPE ggc.Statistics RECORD
    sessionId STRING,
    bytesSent STRING,
    bytesReceived INTEGER,
    scenarioCount INTEGER,
    scenarioFailed INTEGER,
    downloadCount INTEGER,
    downloadFailed INTEGER,
    downloadBytes INTEGER,
    sessionDuration RECORD
        startTime BIGINT,
        endTime BIGINT
    END RECORD,
    downloadFailures DYNAMIC ARRAY OF STRING,
    checkFailures DYNAMIC ARRAY OF RECORD
        fileName STRING,
        lnum INTEGER,
        message STRING
    END RECORD,
    failures DYNAMIC ARRAY OF RECORD
        fileName STRING,
        lnum INTEGER,
        message STRING
    END RECORD,
    vmErrors DYNAMIC ARRAY OF STRING
END RECORD
```

### Scenario Management

| Function | Description |
|---|---|
| `ggc.setApplicationName(name STRING)` | Set the application name to start |
| `ggc.parseOptions()` | Parse command line options, initialize config |
| `ggc.registerScenario(FUNCTION fn)` | Register a scenario function |
| `ggc.play()` | Execute all registered scenarios |
| `ggc.end()` | End current scenario |
| `ggc.stop()` | Stop the GGC |
| `ggc.stopBDLServer()` | Stop BDL server if started by scenario |
| `ggc.cleanup()` | Finalize scenario and perform cleanup |
| `ggc.getScenarioId() RETURNS STRING` | Get current scenario ID |

### Actions and Keys

| Function | Description |
|---|---|
| `ggc.action(name STRING)` | Execute an action by name |
| `ggc.key(keyName STRING)` | Send a key by name |
| `ggc.idle()` | Execute an ON IDLE action |
| `ggc.timer()` | Execute an ON TIMER action |

**Examples:**
```4gl
CALL ggc.action("accept")
CALL ggc.action("cancel")
CALL ggc.action("zoom_customer")
CALL ggc.key("tab")
CALL ggc.key("return")
```

### Timing

| Function | Description |
|---|---|
| `ggc.wait(mseconds INTEGER)` | Delay between instructions (use instead of BDL SLEEP) |
| `ggc.setSpeedRatio(ratio FLOAT) RETURNS FLOAT` | Adjust pace of wait commands (0=no delay, 1=normal, 2=double) |

### Form Field Interaction

| Function | Description |
|---|---|
| `ggc.setFieldValue(fieldName STRING, value STRING)` | Set value in a named field |
| `ggc.setFocus(fieldName STRING)` | Set focus on a field |
| `ggc.setValue(value STRING)` | Set value in the currently focused field |

**Examples:**
```4gl
CALL ggc.setFocus("customerid")
CALL ggc.setFieldValue("customerid", "ALFKI")
CALL ggc.setValue("Hello World!")
```

### Table Interaction

| Function | Description |
|---|---|
| `ggc.setCellFocus(tableName STRING, columnName STRING, row INTEGER)` | Select a cell |
| `ggc.setRowFocus(tableName STRING, row INTEGER)` | Select a row |
| `ggc.setRowSelection(tableName STRING, mode STRING, startIdx INTEGER, endIdx INTEGER)` | Multi-row selection |
| `ggc.setTableOffset(tableName STRING, pageSize INTEGER)` | Set page offset |
| `ggc.setTableSize(tableName STRING, size INTEGER)` | Set table size |
| `ggc.hideTableColumn(tableName STRING, columnName STRING)` | Hide a column |
| `ggc.showTableColumn(tableName STRING, columnName STRING)` | Show a hidden column |
| `ggc.sortTable(tableName STRING, columnName STRING, sortType STRING)` | Sort a table |
| `ggc.clickTableColumn(tableName STRING, columnName STRING)` | Click column header to sort |
| `ggc.altClickTableColumn(tableName STRING, columnName STRING)` | Alt-click for multi-column sort |

**Row selection modes:** `ggc.MRS_SET` (clear+set), `ggc.MRS_UNSET` (unset), `ggc.MRS_EXSET` (extend)

**Examples:**
```4gl
CALL ggc.setRowFocus("s_table", 3)
CALL ggc.setCellFocus("s_details", "productid", 1)
CALL ggc.setRowSelection("s_table", ggc.MRS_SET, 1, 5)
```

### Tree Views

| Function | Description |
|---|---|
| `ggc.collapseTree(treeName STRING, row INTEGER)` | Collapse a tree node |
| `ggc.expandTree(treeName STRING, row INTEGER)` | Expand a tree node |

### Retrieving Information

| Function | Returns | Description |
|---|---|---|
| `ggc.getFieldValue(fieldName STRING)` | STRING | Value of a named field (not for DISPLAY ARRAY) |
| `ggc.getFieldValues(name STRING)` | DYNAMIC ARRAY OF STRING | Values from table/tree/screen record |
| `ggc.getValue()` | STRING | Value of the focused field |
| `ggc.getValues()` | DYNAMIC ARRAY OF STRING | Values of current row in current table |
| `ggc.getFocus()` | STRING | Name of the focused element |
| `ggc.getFormName()` | STRING | Current form name |
| `ggc.getFormTitle()` | STRING | Current form title |
| `ggc.getWindowName()` | STRING | Current window name |
| `ggc.getWindowTitle()` | STRING | Current window title |
| `ggc.getActions()` | DYNAMIC ARRAY OF ggc.Action | List of available actions |
| `ggc.isActionActive(name STRING)` | BOOLEAN | Whether an action is active |
| `ggc.getMessage()` | ggc.Message | Current message |
| `ggc.getError()` | ggc.Message | Current error message |
| `ggc.getButtonText(buttonName STRING)` | STRING | Text of a button |
| `ggc.getDialogComment()` | STRING | Comment from a dialog |
| `ggc.getUserData(keyName STRING)` | STRING | User data value (set via --user-data) |
| `ggc.getWidgetType(fieldName STRING)` | STRING | Widget type of a field |
| `ggc.getFieldTTYAttributes(name STRING)` | DYNAMIC ARRAY OF STRING | TTY attributes of a field |

### Table Information

| Function | Returns | Description |
|---|---|---|
| `ggc.getColumnCount(tableName STRING)` | INTEGER | Number of columns |
| `ggc.getColumnName(tableName STRING, idx INTEGER)` | STRING | Column name at index |
| `ggc.getColumnValue(tableName STRING, colName STRING, row INTEGER)` | STRING | Cell value |
| `ggc.getColumnValues(tableName STRING, colName STRING)` | DYNAMIC ARRAY OF STRING | All values in column |
| `ggc.getCurrentColumn(tableName STRING)` | INTEGER | Current column index |
| `ggc.getCurrentRow(tableName STRING)` | INTEGER | Current row index |
| `ggc.getTableOffset(tableName STRING)` | INTEGER | Current offset |
| `ggc.getTableSize(tableName STRING)` | INTEGER | Table size |
| `ggc.getTablePageSize(name STRING)` | INTEGER | Number of visible rows |
| `ggc.getTTYAttributes(tableName STRING, colName STRING, row INTEGER)` | DYNAMIC ARRAY OF STRING | TTY attributes of a cell |

### Session Information

| Function | Returns | Description |
|---|---|---|
| `ggc.getApplicationName()` | STRING | Application name |
| `ggc.getChildCount()` | INTEGER | Number of running child apps |
| `ggc.getSessionId()` | STRING | Current session ID |
| `ggc.getState()` | STRING | Application state |
| `ggc.getStatistics()` | ggc.Statistics | Test session statistics |
| `ggc.showStatistics()` | ggc.Statistics | Display and return statistics |

### AUI Tree Inspection

| Function | Returns | Description |
|---|---|---|
| `ggc.getAuiTree()` | xml.DomDocument | Full AUI tree |
| `ggc.getAuiTreePart(selector STRING)` | xml.DomDocument | Part of AUI tree matching selector |
| `ggc.DialogSelector(name STRING)` | STRING | Selector for a dialog (use `ggc.AUI_DIALOG_SELECTOR` for current) |
| `ggc.FormSelector(name STRING)` | STRING | Selector for a form (use `ggc.AUI_CURRENT_SELECTOR` for current) |
| `ggc.WindowSelector(name STRING)` | STRING | Selector for a window (use `ggc.AUI_CURRENT_SELECTOR` for current) |

**Example — inspect current dialog:**
```4gl
DEFINE doc xml.DomDocument
LET doc = ggc.getAuiTreePart(ggc.DialogSelector(ggc.AUI_DIALOG_SELECTOR))
```

### Assertion Helpers

| Function | Description |
|---|---|
| `ggc.assert(expr BOOLEAN, msg STRING)` | Assert expression is TRUE; report failure if FALSE |
| `ggc.assertEquals(valueA STRING, valueB STRING, msg STRING)` | Assert two values are equal |

**Examples:**
```4gl
CALL ggc.assert(ggc.getFormName() == "price",
    SFMT("Expected form 'price', got '%1'", ggc.getFormName()))

CALL ggc.assertEquals(ggc.getFieldValue("formonly.name"), "Wall clock",
    SFMT("Expected 'Wall clock', got '%1'", ggc.getFieldValue("formonly.name")))
```

### Check Functions

Check functions verify conditions and log failures **without stopping** execution (unless `--check-as-failure` is set). Only failed checks appear in the report.

| Function | Description |
|---|---|
| `ggc.checkActionActive(actionName STRING)` | Check action is active |
| `ggc.checkActionInactive(actionName STRING)` | Check action is inactive |
| `ggc.checkError(errorText STRING)` | Check error message matches |
| `ggc.checkFieldValue(fieldName STRING, value STRING)` | Check field has expected value |
| `ggc.checkFocus(fieldName STRING)` | Check field has focus |
| `ggc.checkFormName(formName STRING)` | Check form name |
| `ggc.checkFormTitle(formTitle STRING)` | Check form title |
| `ggc.checkMessage(messageText STRING)` | Check message matches |
| `ggc.checkNoError()` | Check no error message exists |
| `ggc.checkNoMessage()` | Check no message exists |
| `ggc.checkValue(value STRING)` | Check focused field has expected value |
| `ggc.checkWindowName(windowName STRING)` | Check window name |
| `ggc.checkWindowTitle(windowTitle STRING)` | Check window title |

**Examples:**
```4gl
CALL ggc.checkFormName("mstr_order_list")
CALL ggc.checkWindowTitle("Order Search/List")
CALL ggc.checkFieldValue("orders.orderid", "10248")
CALL ggc.checkActionActive("accept")
CALL ggc.checkNoError()
```

### Failure Notification

| Function | Description |
|---|---|
| `ggc.notifyCheckFailure(message STRING)` | Report a check failure (non-fatal) |
| `ggc.notifyCheckFailureEx(fileName STRING, lineNo INTEGER, message STRING)` | Check failure with source location |
| `ggc.notifyFailure(message STRING)` | Report a scenario failure (fatal) |
| `ggc.notifyFailureEx(fileName STRING, lineNo INTEGER, message STRING)` | Scenario failure with source location |
| `ggc.throwExceptions(te BOOLEAN)` | Configure GGC to stop if an action fails |

### Front Call Handling

Register a custom handler to respond to front calls during testing:

```4gl
MAIN
    CALL ggc.setApplicationName("myapp")
    CALL ggc.parseOptions()
    CALL ggc.registerFrontCallHandler(FUNCTION myFrontCallHandler)
    CALL ggc.registerScenario(FUNCTION play_0)
    CALL ggc.play()
    EXIT PROGRAM 0
END MAIN

FUNCTION myFrontCallHandler(request ggc.FrontCallRequest INOUT)
    RETURNS ggc.FrontCallAnswer
    DEFINE answer ggc.FrontCallAnswer

    IF request.getModuleName() == "standard"
       AND request.getFunctionName() == "feInfo" THEN
        CALL answer.success()
        CALL answer.returnString("GGC")
    ELSE
        CALL answer.notProcessed()
    END IF

    RETURN answer
END FUNCTION
```

**Default front calls** (handled automatically):

| Front Call | Return Value |
|---|---|
| `standard.feInfo("feName")` | "GBC" (ua) or "GDC" (tcp), overridable with `--fename` |
| `standard.feInfo("isActivex")` | 0 |
| `standard.feInfo("osType")` | "Windows" or "Unix" |
| `standard.feInfo("numScreens")` | 1 |
| `standard.getEnv("NAME")` | Environment variable value |

---

## Command Reference

### ggcgen

Generates test scenarios from recorded log files.

```
ggcgen bdl [options] logfile.guilog     # BDL scenario
ggcgen java [options] logfile.guilog    # Java scenario
ggcgen bdl --skeleton mytest            # Empty skeleton
```

**Key options:**

| Option | Description |
|---|---|
| `--check-all` | Enable all checks |
| `--check-window` | Check window name/title |
| `--check-form` | Check form name/title |
| `--check-focus` | Check focused field |
| `--check-value` | Check focused field value |
| `--check-actions` | Check action states |
| `--check-messages` | Check MESSAGE/ERROR values |
| `--check-on-snapshot=all` | Generate checks only at snapshot points |
| `--template-directory dir` | Custom template directory (multiple allowed) |
| `--output-directory dir` | Output directory (default: cwd) |
| `--no-wait` | Omit ggc.wait() calls |
| `--dump-all` | Include AUI tree/log as comments |
| `--skeleton` | Generate empty skeleton (no log needed) |
| `-v` / `--verbose` | Verbose output |

### ggcadmin

Runs Java scenarios and manages the BDL scenario server.

```
ggcadmin tcp [options]              # Direct connection
ggcadmin ua [options]               # Through GAS
ggcadmin startbdlserver [options]   # Start BDL server
ggcadmin stopbdlserver [options]    # Stop BDL server
```

**TCP options:**

| Option | Description |
|---|---|
| `-c "fglrun myapp"` | Command to start the application |
| `-w directory` | Working directory |
| `-e envfile` | Environment variables file |
| `--dvm-available seconds` | DVM startup delay (default: 10) |
| `--instance-count N` | Parallel instances (default: 1) |
| `--instance-delay ms` | Delay between instance starts (default: 100) |

**UA options:**

| Option | Description |
|---|---|
| `-u url` | Application URL |
| `--check-certificates` | Enable SSL certificate checks |
| `-H handler` | HTTP handler (e.g., `GIPSSOHandler` for SSO) |

**Common options (tcp and ua):**

| Option | Description |
|---|---|
| `--scenario class` | Test scenario class |
| `--scenario-provider class` | ScenarioProvider class |
| `-f host:port` | Forward GUI to GDC |
| `-s ratio` | Speed ratio (0=fastest, 1=normal, 2=slow) |
| `--check-as-failure` | Treat check failures as scenario failures |
| `--guilog-on-error` | Dump guilog on failure |
| `--guilog-directory dir` | Guilog output directory |
| `--guilog-prefix prefix` | Guilog filename prefix |
| `--fename name` | Client name (default: "GBC" for ua, "GDC" for tcp) |
| `-F handler` | Front call handler |
| `--user-data key=value` | Set user data |
| `--user-data-file file` | User data from file |

**BDL server options:**

| Option | Description |
|---|---|
| `-p port` | Server port (default: 6500) |
| `-i seconds` | Idle delay before auto-exit (default: 300, 0=infinite) |

### fglrun (BDL scenario options)

```
fglrun scenario.42m ua [options]
fglrun scenario.42m tcp [options]
```

Same options as `ggcadmin` for the respective mode, plus:
| Option | Description |
|---|---|
| `-p port` | BDL server port (default: 6500) |

---

## Logging

### Configuration

File: `$HOME/.ggc/log.properties`

```properties
console.enabled=true
console.columns=relative-time contexts event-type event-params
console.categories=ERROR WARNING INFO VM HTTP ALL DEBUG
console.maxlength=4096
console.format=TEXT
file.maxlength=-1
file.path=/tmp/ggc
file.enabled=true
file.columns=date time relative-time contexts event-type event-params
file.format=TEXT
file.categories=ERROR WARNING INFO VM HTTP DEBUG
```

**Categories:** ERROR, WARNING, INFO, VM (DVM data exchange), HTTP, DEBUG (very verbose), ALL

**Output columns:** date, time, relative-time, contexts, event-type, event-params

### Log Files

| File | Description |
|---|---|
| `tcp-<session-id>.log` | Direct connection test log |
| `ua-<session-id>.log` | UA mode test log |
| `System.log` | Non-session messages |
| `SessionManager.log` | Session manager log |

Default location: `$HOME/.ggc/<current_date>/`

### Default Argument Files

GGC tools auto-load options from files named `[.]tool.command`:

| Command | Filename |
|---|---|
| `ggcadmin startbdlserver` | `.ggcadmin.startbdlserver` or `ggcadmin.startbdlserver` |
| `fglrun scenario ua` | `.bdl.ua` or `bdl.ua` |
| `fglrun scenario tcp` | `.bdl.tcp` or `bdl.tcp` |
| `ggcgen bdl` | `.ggcgen.bdl` or `ggcgen.bdl` |

Lookup: `$HOME/.ggc/` first, then current directory.

Verify with `--dump-command`.

---

## Testing Patterns

### Checking a Dialog Window (MENU STYLE="dialog")

```4gl
IMPORT xml

DEFINE doc xml.DomDocument
DEFINE root xml.DomNode

LET doc = ggc.getAuiTreePart(ggc.CurrentDialogSelector())
LET root = doc.getDocumentElement()

IF root.getNodeName() != "Menu" THEN
    CALL ggc.notifyFailure("Expected Menu dialog")
END IF
IF root.getAttribute("style") != "dialog" THEN
    CALL ggc.notifyFailure("Expected dialog style")
END IF
```

### Working with Snapshots

1. Record a log with ALT+F12 snapshots
2. Generate with `--check-on-snapshot=all` — produces `guisnapshot-N.xml` files
3. Load snapshot in test and compare against live AUI tree:

```4gl
DEFINE snapDoc xml.DomDocument
DEFINE liveDoc xml.DomDocument

LET snapDoc = xml.DomDocument.Create()
CALL snapDoc.load("guisnapshot-0.xml")

LET liveDoc = ggc.getAuiTree()
-- Compare nodes using xml.DomNodeList methods
```

### Environment File (TCP mode)

File format with OS-independent references:
```
FGLGUIDEBUG=1
FGLIMAGEPATH=${MYAPPROOT}$(file.separator)images$(path.separator)${FGLDIR}/lib/image2font.txt
```
- `$(path.separator)` — `:` (Unix) or `;` (Windows)
- `$(file.separator)` — `/` (Unix) or `\` (Windows)

### SSO Authentication

```bash
fglrun mytest ua --url https://myserver:6394/ua/r/myapp \
    -H com.fourjs.ggc.httphandler.GIPSSOHandler
```

---

## Unit Testing Best Practices

1. Each `.4gl` application should have its own test scenario
2. Make a complete list of features, from smallest to largest
3. Write a single test for each feature — one test, one feature
4. If feature A depends on feature B, test B first in the sequence
5. Test both correct and incorrect input
6. Use `ggc.wait()` instead of BDL `SLEEP`
7. Use Genero BDL for most tests; reserve Java for critical load testing only

---

## Quick Reference: Test Lifecycle

```bash
# 1. Environment
source $GGCDIR/envggc
source $FGLDIR/envcomp

# 2. Record (optional — or write tests by hand)
fglrun --start-guilog=myapp.guilog myapp

# 3. Generate scenario from log (optional)
ggcgen bdl --check-all myapp.guilog

# 4. Compile
fglcomp myapp_test.4gl

# 5. Start BDL server
ggcadmin startbdlserver &

# 6. Run test
fglrun myapp_test.42m tcp --command-line "fglrun myapp"
# or
fglrun myapp_test.42m ua --url http://localhost:6394/ua/r/myapp

# 7. Stop BDL server
ggcadmin stopbdlserver
```
