# Dialog-Driven Architecture (DDA)

A design pattern for Genero BDL applications. This document defines DDA,
contrasts it with MVC/MVVM, lists the layers and their rules, and walks
through how the rules apply in practice — including the CONSTRUCT/SQL
split that is the most common source of confusion.

> **Tagline:** *Dialog-Driven, Schema-Bound.*

---

## 1. What DDA is

DDA describes the architecture native to Genero BDL applications that
use forms, dialogs, and a relational database. It is built on two ideas
the language itself promotes:

1. **The dialog statement is the controller.** `DIALOG`, `INPUT`,
   `INPUT ARRAY`, `DISPLAY ARRAY`, `CONSTRUCT`, and `MENU` are
   first-class language constructs that own user-event handling, screen
   state, and the lifecycle of a screen interaction. There is no
   separate "controller" object — the dialog statement *is* the
   controller, expressed as language syntax.

2. **The schema is the canonical shape.** A column in the database is
   the source of truth for the type and width of every variable, record
   field, and form field that holds that column's value. Types are
   bound to the schema with `LIKE table.column`. Forms bind to tables
   and columns by name. CONSTRUCT generates SQL fragments from form
   metadata. The same logical "shape" travels unchanged from disk to
   screen.

DDA is **not** MVC. There is no observer chain — the UI mutates a
record directly and calls model functions imperatively. It is **not**
MVVM. There is no view-model with bindable observable properties —
form fields bind to record fields by name via the AUI protocol. The
closest classical relative is **MVP (Model-View-Presenter)**, where the
dialog statement plays the role of the presenter.

---

## 2. Layers

DDA has five layers. Names below match the file-prefix convention used
in this project.

| Prefix      | Role                          | Responsibility                                                                 |
|-------------|-------------------------------|--------------------------------------------------------------------------------|
| `main_*`    | **Entry point**               | Wires init + the top-level dialog + cleanup. One per use case.                 |
| `ui_*`      | **Presenter / View driver**   | Owns the `DIALOG` statement, handles user events, calls models.                |
| `md_*`      | **Master-detail orchestrator**| Coordinates a master record with its child arrays; thin layer above `ui_*`.    |
| `model_*`   | **Persistence + domain rules**| Owns SQL, transactions, validation rules, record types (`t_<table>`).          |
| `rest_*`    | **Transport adapter**         | Translates HTTP ↔ model calls. No domain rules of its own.                     |
| `*_helper`  | **Cross-cutting utilities**   | Pure functions reused by multiple layers (formatting, generic CRUD wrappers).  |

The `.per` forms and `.4ad`/`.4st`/`.4tb` resource files are not a
layer — they are declarative assets owned by the `ui_*` modules that
load them.

---

## 3. The cardinal rules

These are the rules that distinguish DDA from "code that happens to be
written in BDL." Violations are not language errors; they are
architectural drift, and the cost shows up at refactor time.

### R1. The dialog statement lives in `ui_*` (or `md_*`).

`DIALOG`, `INPUT`, `INPUT ARRAY`, `DISPLAY ARRAY`, `CONSTRUCT`, and
`MENU` belong in the presenter layer. They do not appear in models,
REST adapters, or main programs (which only wire things up).

### R2. The model owns the schema.

Schema knowledge — table names, column names, joins, projections,
ordering, DML, transactions — lives in `model_*`. Any layer above the
model treats the schema as opaque: it passes records to the model and
receives records back.

A practical test: **could you rename a column with edits in one file?**
If yes, the schema is properly encapsulated. If no, schema knowledge
has leaked.

### R3. Domain rules live in the model.

A *domain rule* is a constraint on the data that holds regardless of
how the data is being entered or displayed. Examples:

- `discount` must be `>= 0 AND < 1`
- `hiredate` must be later than `birthdate`
- `customerid` must exist in `customers`
- `lineTotal = unitprice * quantity * (1 - discount)`

These belong in `model_*.validateRec` or as dedicated functions like
`calcLineTotal`. They never live in `ui_*` event handlers, in
`rest_*` adapters, or duplicated across both.

The contrast — a *presentation rule* — is something like "disable the
Save button while the form is invalid." That lives in the UI; it is
about the dialog, not the data.

### R4. Records cross layer boundaries; raw rows do not.

A function that returns data returns `t_<table>` or a dynamic array of
them — never a tuple of loose variables, never a `string,string,int`
return list. The record type is the contract between layers.

### R5. Validation returns `t_valid_rec`; it does not raise or display.

A model validation function returns a `t_valid_rec` with `valid_status`
and `valid_msg`. It does not `ERROR`, `DISPLAY`, `CALL fgl_winmessage`,
or otherwise produce output. The UI decides how to surface the result.

### R6. Transactions are model-owned.

`BEGIN WORK` / `COMMIT WORK` / `ROLLBACK WORK` live inside model
functions, not in UI event handlers and not in REST adapters. A single
logical user action that spans multiple rows wraps the rows inside one
model function that owns the transaction.

### R7. The model returns data; the UI binds it.

The model does not know `ui.ComboBox`, `ui.Window`, `ui.Form`, or any
other UI type. It returns dynamic arrays of records; the UI walks them
and populates widgets.

*(Project-specific exception: the existing `load_*_combo(cbx ui.ComboBox)`
helpers are grandfathered in for ergonomic reasons. New code should
prefer `getList()` returning a dynamic array.)*

### R8. REST adapters are thin.

A REST handler does HTTP plumbing (parse path, decode body, format
response) and calls the model. It does not contain joins, validation
rules, or computed expressions. If a JOIN is needed for a list endpoint,
it belongs in a model fetch function — see R2 and §5.

---

## 4. Naming convention

The file-prefix convention is part of the architecture, not a stylistic
choice. Following it lets readers grep for the right layer in one step.

| Pattern              | Layer                | Example                          |
|----------------------|----------------------|----------------------------------|
| `main_<usecase>.4gl` | Entry point          | `main_orders.4gl`                |
| `ui_<table>.4gl`     | Presenter            | `ui_orders.4gl`                  |
| `md_<usecase>.4gl`   | Master-detail        | `md_order_details.4gl`           |
| `model_<table>.4gl`  | Persistence + rules  | `model_orders.4gl`               |
| `rest_<table>.4gl`   | REST adapter         | `rest_orders.4gl`                |
| `<area>_helper.4gl`  | Cross-cutting helper | `list_view_helper.4gl`           |
| `t_<table>`          | Record type          | `t_order`                        |
| `validateRec(mode)`  | Model validation     | `t_order.validateRec("A")`       |
| `insertRec`/`updateRec`/`deleteRec` | CRUD method | `t_order.insertRec()`        |

Record types match table names. CRUD methods follow the four verbs.
Validation always takes a `mode CHAR(1)` argument (`"A"` add, `"C"`
change).

---

## 5. The CONSTRUCT / SQL split

CONSTRUCT is where DDA's two ideas — dialog as controller, schema as
canonical shape — collide most visibly. The statement is **a dialog**
(it lives in the UI) but its arguments are **schema column names** (it
looks like persistence code). The temptation to either move CONSTRUCT
into the model (wrong: CONSTRUCT is a dialog) or to write the entire
search query inline next to it (wrong: leaks schema upward) leads to
most of the violations in the audit.

The rule:

> **CONSTRUCT produces a WHERE fragment. The WHERE fragment crosses
> the layer boundary as a string. The model owns SELECT, FROM, JOIN,
> projection, and ORDER BY.**

In practice:

```4gl
-- ui_orders.4gl owns the user interaction
DEFINE where_clause STRING
DEFINE orders DYNAMIC ARRAY OF t_order_list

CONSTRUCT BY NAME where_clause ON
    sr_orders.orderid, sr_orders.orderdate,
    sr_orders.customerid, sr_orders.employeeid
-- where_clause is now e.g. "orderdate >= '2024-01-01' AND customerid = 'ALFKI'"

LET orders = model_orders.searchByFilter(where_clause)

-- model_orders.4gl owns the schema-coupled completion
PUBLIC FUNCTION searchByFilter(where_clause STRING) RETURNS DYNAMIC ARRAY OF t_order_list
    DEFINE result DYNAMIC ARRAY OF t_order_list
    DEFINE sql_text STRING
    DEFINE row t_order_list

    LET sql_text = "SELECT o.orderid, o.orderdate, c.companyname, "
                || "       e.firstname || ' ' || e.lastname AS employeename "
                || "  FROM orders o "
                || "  JOIN customers c ON o.customerid = c.customerid "
                || "  JOIN employees e ON o.employeeid = e.employeeid "
                || " WHERE " || NVL(where_clause, "1=1")
                || " ORDER BY o.orderdate DESC"

    PREPARE p_search FROM sql_text
    DECLARE c_search CURSOR FOR p_search
    FOREACH c_search INTO row.*
        LET result[result.getLength()+1] = row
    END FOREACH
    RETURN result
END FUNCTION
```

Two practical refinements:

**Address screen-record fields, not table columns.** Above, CONSTRUCT
names `sr_orders.orderid` rather than `orders.orderid`. The form file
maps the screen field to the column; CONSTRUCT resolves through the
form metadata. The UI module no longer mentions any column name —
the column leak is confined to the `.per` file, which the UI already
owns.

**Always wrap the fragment in `NVL(..., "1=1")`.** CONSTRUCT can return
NULL or empty if the user enters no criteria; the wrapper makes the
query work in that case without an `IF` cascade.

This split has a real payoff beyond cleanliness: a second view of the
same data — a report, a REST endpoint, an export — calls
`searchByFilter` with its own WHERE fragment (or `NULL` for all rows),
and the projection/join logic does not duplicate.

---

## 6. Quick decision guide: where does *X* go?

| You're writing…                                  | Goes in…           |
|--------------------------------------------------|--------------------|
| `INSERT` / `UPDATE` / `DELETE` statement         | `model_*`          |
| `BEGIN WORK` / `COMMIT` / `ROLLBACK`             | `model_*`          |
| `SELECT` for one row (lookup)                    | `model_*`          |
| `SELECT` for a combo/grid (list)                 | `model_*` (`getList`)|
| `SELECT` joining multiple tables                 | `model_*` (`fetchListWithX`) |
| Range check on a numeric field                   | `model_*.validateRec` |
| FK existence check                               | `model_*.validateRec` |
| Computed field (e.g. lineTotal)                  | `model_*.calc<Name>`  |
| `CONSTRUCT BY NAME ...`                          | `ui_*`             |
| `INPUT`, `DISPLAY ARRAY`, `MENU`                 | `ui_*` (or `md_*`) |
| WHERE-clause string built from CONSTRUCT output  | UI builds, model consumes |
| HTTP request parsing / response formatting      | `rest_*`           |
| Loading a `.42ad` / `.4st` resource              | UI or `main_*` init|
| `ERROR` / `MESSAGE` / `fgl_winmessage`           | `ui_*` only        |
| Application-wide setup (styles, action defaults) | `main_lib`         |

When uncertain, ask the schema-rename test:

> **If I renamed `customers.companyname` to `customers.company`, how
> many files would I edit?**

If the answer is "one — `model_customers`", the design is correct. If
the answer is more, schema knowledge has escaped its layer.

---

## 7. What DDA is not

For people coming from other ecosystems, the negative space is useful.

- **Not MVC.** No observer pattern; no separate Controller class; no
  Views observing Model state. The UI mutates records directly and
  calls models imperatively.
- **Not MVVM.** No ViewModel object wrapping the model with bindable
  observables. Form fields bind to record fields by name through the
  AUI protocol; the runtime handles propagation.
- **Not classic three-tier with anemic DTOs.** Records are not DTOs.
  They are the canonical shape, shared between layers without
  translation. There is no parallel hierarchy of Entity / DTO /
  ViewModel / RequestModel — there is one record.
- **Not "transaction script" alone.** Each `main_*` program is a
  top-level use case (categorically a transaction script), but the
  per-table model encapsulates persistence and rules, which a pure
  transaction-script style would not.

DDA borrows from all of the above; it is none of them.

---

## 8. Glossary

- **Dialog statement** — Any of `DIALOG`, `INPUT`, `INPUT ARRAY`,
  `DISPLAY ARRAY`, `CONSTRUCT`, `MENU`. The BDL language constructs
  that own a user interaction.
- **Presenter** — A `ui_*` module. The presenter owns one or more
  dialog statements and the screen state they manage.
- **Model** — A `model_*` module. Owns the SQL, the record type, the
  validation rules, and the transactions for one logical table or
  aggregate.
- **Record type (`t_<table>`)** — The shape that crosses layers. Fields
  are bound to the schema via `LIKE`.
- **`t_valid_rec`** — The standard return type for validation:
  `(valid_status BOOLEAN, valid_msg STRING)`. Defined in `model_helper`.
- **WHERE fragment** — A SQL `WHERE` clause body (without the `WHERE`
  keyword), as a string. The output of `CONSTRUCT` and the input to
  model search functions.
- **Schema-rename test** — Mental check for layer leakage: how many
  files would change if a column were renamed?
