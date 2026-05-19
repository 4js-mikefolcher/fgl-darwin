# md_order_details.4gl — Refactoring Plan

Identified areas of duplication and streamlining opportunities.

---

## 1. Extract Detail Field Handlers (HIGH)

**Problem**: `detail_single_input` (lines 816-842) duplicates nearly all field-level handlers from `details_input` (lines 716-748) — zoom, validation, change detection, and calculation logic.

**Fix**: Extract shared helper functions:

```4gl
PRIVATE FUNCTION apply_product_lookup(idx INTEGER,
   prod_id LIKE products.productid, prod_name LIKE products.productname) RETURNS ()
   LET curr_detail_list[idx].productid = prod_id
   LET curr_detail_list[idx].productname = prod_name
   CALL curr_detail_list[idx].default_unitprice_from_product()
   CALL curr_detail_list[idx].calcPrice()
END FUNCTION

PRIVATE FUNCTION validate_product_field(idx INTEGER) RETURNS (BOOLEAN)
   VAR val_status = curr_detail_list[idx].toOrderDetail().validate_product()
   IF val_status.valid_status THEN
      CALL curr_detail_list[idx].calcPrice()
      LET curr_detail_list[idx].productname = val_status.valid_msg
   ELSE
      ERROR val_status.valid_msg
      RETURN FALSE
   END IF
   LET curr_detail_list[idx].discount = NVL(curr_detail_list[idx].discount, 0)
   LET curr_detail_list[idx].quantity = NVL(curr_detail_list[idx].quantity, 1)
   RETURN TRUE
END FUNCTION
```

Both `details_input` and `detail_single_input` call these instead of inlining the logic.

**Lines saved**: ~30  
**Risk**: Low

---

## 2. Consolidate calcPrice and calc_line_total (HIGH)

**Problem**: Two functions compute the same formula:
- `calcPrice()` (line 1020) — method on `t_detail_input_rec`
- `calc_line_total()` (line 320) — standalone function used during search

**Fix**: Have `calcPrice()` delegate to `calc_line_total()`:

```4gl
PRIVATE FUNCTION (self t_detail_input_rec) calcPrice() RETURNS ()
   LET self.totalprice = calc_line_total(self.unitprice, self.quantity, self.discount)
END FUNCTION
```

**Lines saved**: ~3  
**Risk**: None

---

## 3. Extract populate_result_from_header Helper (MEDIUM)

**Problem**: Manual field-by-field copying from `curr_order_rec` to `order_result_list[idx]` appears in:
- `sync_current_recs` (lines 379-388) — 10 field assignments
- `execute_search` (lines 252-269) — same mappings from `r_orders.*` plus lookup names

**Fix**: Extract a function that populates a result record from the current header:

```4gl
PRIVATE FUNCTION populate_result_from_header(idx INTEGER) RETURNS ()
   LET order_result_list[idx].orderid = curr_order_rec.orderid
   LET order_result_list[idx].customerid = curr_order_rec.customerid
   LET order_result_list[idx].companyname = curr_order_rec.customername
   LET order_result_list[idx].employeeid = curr_order_rec.employeeid
   LET order_result_list[idx].employeename = curr_order_rec.employeename
   LET order_result_list[idx].freight = curr_order_rec.freight
   LET order_result_list[idx].orderdate = curr_order_rec.orderdate
   LET order_result_list[idx].shipcity = curr_order_rec.shipcity
   LET order_result_list[idx].shipcountry = curr_order_rec.shipcountry
   LET order_result_list[idx].shipname = curr_order_rec.shipname
   LET order_result_list[idx].rowedit = cEditImage
   LET order_result_list[idx].rowdelete = cDeleteImage
   LET order_result_list[idx].rowview = cViewImage
END FUNCTION
```

`sync_current_recs` and `execute_search` both call this. In `execute_search`, populate `curr_order_rec` from the query results first, then call the helper.

**Lines saved**: ~15  
**Risk**: Low — `execute_search` would need to populate `curr_order_rec` as an intermediary, which changes data flow slightly.

---

## 4. Extract populate_header_dict Helper (MEDIUM)

**Problem**: In `execute_search` (lines 272-287), 16 fields are manually copied from `r_orders.*` into `order_header_dict[order_id]`. This is the only place this mapping occurs, but it's verbose and error-prone.

**Fix**: Use `util.JSONObject` to copy the base record, then set display-only fields:

```4gl
PRIVATE FUNCTION populate_header_dict(order_id STRING,
   r_orders RECORD LIKE orders.*,
   customer_name STRING, employee_name STRING) RETURNS ()

   VAR jsonObj = util.JSONObject.fromFGL(r_orders)
   CALL jsonObj.toFGL(order_header_dict[order_id])
   LET order_header_dict[order_id].customername = customer_name
   LET order_header_dict[order_id].employeename = employee_name
END FUNCTION
```

**Lines saved**: ~15  
**Risk**: Low — depends on `r_orders.*` fields being a subset of `t_order` fields (they are, except for the two display names which are set explicitly).

---

## 5. Fold set_current_recs into update_detail_recs (LOW)

**Problem**: `update_detail_recs()` and `set_current_recs()` are always called as a pair in three places:
- `sync_current_recs` (lines 392-393)
- `update_md_detail` (lines 591-592)
- `delete_current_recs_detail` (lines 417-418)

**Fix**: Have `update_detail_recs()` call `set_current_recs()` at the end internally. Callers only need to call `update_detail_recs()`.

**Lines saved**: ~3  
**Risk**: Verify no caller needs `update_detail_recs()` without the subsequent `set_current_recs()`. Currently none do.

---

## Implementation Order

1. **#2** (calcPrice delegates to calc_line_total) — smallest, zero risk, do first
2. **#1** (extract detail field handlers) — biggest payoff, reduces the most duplication
3. **#5** (fold set_current_recs) — quick, low risk
4. **#3** (populate_result_from_header) — medium effort, clean win
5. **#4** (populate_header_dict with JSON) — medium effort, depends on JSON field compatibility
