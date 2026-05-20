## Master/Detail Order Entry — Feature Guide and Test Script

This document describes the master/detail order entry feature implemented by `mstr_dtl_order.4gl` and its supporting modules. It also serves as a repeatable demo and regression test script.

### 1. Environment Setup

- **Build the master/detail program**:

```bash
cd hrm
make mstr_dtl_order
```

- **Run the program** (ensure the database and `FGLPROFILE` are configured, and the POI API package is in `FGLLDPATH`):

```bash
cd ../bin
export FGLLDPATH=/opt/fourjs/packages/v6/poiapi:$FGLLDPATH
FGL_LENGTH_SEMANTICS=CHAR FGLPROFILE=<path>/fglprofile.pgs fglrun mstr_dtl_order.42r
```

### 2. Basic Search & List Behavior

1. Start `mstr_dtl_order`. The main window (`mstr_order_list.per`) appears.
2. **Initial state**:
   - Search criteria fields (Order ID / Order Date) are blank.
   - Search results table is empty.
   - `query_label` will show a message only after a search.
3. **Search all orders**:
   - Leave criteria blank.
   - Click **Search** on the toolbar.
   - Verify:
     - The table populates with orders.
     - Aggregates at the bottom show non-zero count and totals.
     - `query_label` shows “Showing all orders”.
4. **Filter by simple criteria**:
   - Enter a specific `Order ID` (known existing ID).
   - Click **Search**.
   - Verify:
     - Exactly one row (or the expected subset) is shown.
     - `query_label` shows a `Filter: ...` message reflecting the WHERE clause.

### 3. Advanced Search Behavior

1. Click **Advanced Search** (toolbar button or the `Advance Search` button on the form).
2. In the `advsearch_orders` dialog:
   - Fill a meaningful combination, for example:
     - Customer name contains part of a company name.
     - Optional: order date range, freight > 0, or specific employee.
   - Click **Search**.
3. Back in the main list:
   - Verify the rows match the advanced criteria.
   - Confirm `query_label` shows the constructed filter.

### 4. Add New Order with Details

1. In the list view, click **Add**.
2. In the `md_order_details` window:
   - **Header section**:
     - Use zoom on **Customer** to pick an existing customer.
     - Use zoom on **Employee** to pick an existing employee.
     - Set `Order Date` to today.
     - Optionally adjust `Required Date`, `Shipped Date`, and `Ship Via` combobox.
   - **Order items (details)**:
     - In the items table, add 2–3 lines:
       - Use zoom on **Product** to choose products.
       - Enter quantity and discount; verify total price auto-calculates.
   - **Validation checks**:
     - Leave a product blank on one row and try to finish; the detail validation should block completion and highlight the problematic row.
     - Use the same product on two different lines; you should see an error about duplicate products and be asked to consolidate.
3. Accept the dialog:
   - No validation errors should remain.
   - You return to the list screen.
   - The new order appears in the table with correct totals.
   - The new `OrderID` should match the row in the `orders` table (optional cross-check with SQL).

### 5. Edit Existing Order

1. In the list, pick an existing order row.
2. Click **Modify**.
3. In `md_order_details`:
   - Change header fields (e.g., freight, ship city, ship name).
   - Edit details:
     - Update quantity on one line.
     - Add an additional detail line.
     - Remove a detail line if appropriate.
   - Ensure:
     - Per-line validation is enforced.
     - Duplicate product checks still prevent two lines with the same product.
4. Accept:
   - Back in the list:
     - Verify the row shows updated freight and totals.
     - Optionally rerun the same search criteria to confirm the order still appears and displays updated values.

### 6. View-Only Navigation

1. In the list view, select an order and click **View** (toolbar or row “eye” icon).
2. In `md_order_details` view mode:
   - Header and detail lines are displayed.
   - The toolbar is focused on navigation and closing; editing actions are disabled here.
3. Use **First / Previous / Next / Last**:
   - `status_label` should show:
     - `Order X of Y — ID <id>, Customer <name>, Total Qty <n>, Total Amount <amt>`
   - Header and detail sections should update in sync for each order.
4. Exit view mode and return to the list without making changes.

### 7. Delete Order

1. From the list, select a test order that was created in this session.
2. Click **Delete**.
3. In the confirmation dialog:
   - First choose **No**; verify that no data changes.
   - Then click **Delete** again and choose **Yes**.
4. Verify:
   - The order disappears from the list.
   - Navigation remains valid if multiple rows exist (no out-of-range index issues).
   - Optionally check the database:
     - The header row is removed from `orders`.
     - All corresponding rows are removed from `order_details`.

### 8. Excel Export via POI API

1. In the list view, perform a search:
   - Either all orders, or a filtered subset using basic or advanced criteria.
2. Click **Export to Excel**.
3. Verify:
   - A message is displayed similar to:  
     `Exported N orders to <excel-file-path>`.
4. Open the exported Excel file:
   - Columns should include: OrderID, CustomerID, CustomerName, EmployeeID, EmployeeName, OrderDate, Freight, ShipName, ShipCity, ShipCountry, TotalQty, TotalAmt.
   - Row count matches the rows displayed in the list.
   - Numeric values (freight, totals) match what is shown in the application.

### 9. Edge and Regression Checks

- **Empty result export**:
  - Use criteria that produce no matching orders.
  - Click **Export to Excel**.
  - Confirm the behavior is clear:
    - Either a friendly error message, or a valid but empty Excel sheet.

- **Repeated searches**:
  - Alternate between simple and advanced searches several times.
  - Confirm:
    - No stale data appears (each search rebuilds the list and dictionaries).
    - Aggregates and `status_label` are always consistent with current results.

This script can be used both as a live demo of Genero’s master/detail UI/UX capabilities and as a regression checklist when refactoring this module or related infrastructure.

