IMPORT util
IMPORT os

IMPORT FGL md_helper
IMPORT FGL model_helper
IMPORT FGL model_orders
IMPORT FGL model_order_details
IMPORT FGL advsearch_orders
IMPORT FGL ui_customers
IMPORT FGL ui_employees
IMPORT FGL ui_orders
IMPORT FGL model_employees
IMPORT FGL model_customers
IMPORT FGL model_shippers
IMPORT FGL ui_products
IMPORT FGL dialog_prompt
IMPORT FGL com.fourjs.poiapi.fgl_table_export

SCHEMA northwind

PRIVATE TYPE t_order_result_rec RECORD
   orderid LIKE orders.orderid,
   customerid LIKE customers.customerid,
   companyname LIKE customers.companyname,
   employeeid LIKE employees.employeeid,
   employeename STRING,
   orderdate LIKE orders.orderdate,
   freight LIKE orders.freight,
   shipname LIKE orders.shipname,
   shipcity LIKE  orders.shipcity,
   shipcountry LIKE orders.shipcountry,
   totalqty INTEGER,
   totalamt DECIMAL(12,2),
   rowview STRING,
   rowedit STRING,
   rowdelete STRING
END RECORD

PRIVATE TYPE t_detail_input_rec RECORD
   orderid LIKE order_details.orderid,
   productid LIKE order_details.productid,
   productname LIKE products.productname,
   unitprice LIKE order_details.unitprice,
   quantity LIKE order_details.quantity,
   discount LIKE order_details.discount,
   totalprice DECIMAL(10,2),
   rowedit STRING,
   rowdelete STRING
END RECORD

PRIVATE TYPE t_detail_input_list DYNAMIC ARRAY OF t_detail_input_rec

PRIVATE TYPE t_order_result_list DYNAMIC ARRAY OF t_order_result_rec

PRIVATE DEFINE order_result_list t_order_result_list
PRIVATE DEFINE curr_result_rec t_order_result_rec

PRIVATE DEFINE order_header_dict DICTIONARY OF model_orders.t_order
PRIVATE DEFINE curr_order_rec model_orders.t_order

PRIVATE DEFINE order_detail_dict DICTIONARY OF DYNAMIC ARRAY OF model_order_details.t_order_detail
PRIVATE DEFINE curr_detail_list t_detail_input_list

PRIVATE DEFINE listIdx INTEGER
PRIVATE DEFINE detailIdx INTEGER

PUBLIC FUNCTION mstr_detail_orders()
   DEFINE where_clause STRING
   DEFINE selected_option SMALLINT

   OPEN WINDOW mainWindow WITH FORM "mstr_order_list"
      ATTRIBUTES(STYLE="noaction")

   LET selected_option = NULL
   DIALOG ATTRIBUTES(UNBUFFERED)

      CONSTRUCT where_clause
         ON orders.orderid, orders.orderdate,
            customers.customerid, employees.employeeid
         FROM s_search.orderid, s_search.orderdate,
            s_search.customerid, s_search.employeeid

         ON ACTION zoom_order
            VAR order_id LIKE orders.orderid = ui_orders.order_lookup_menu()
            IF NVL(order_id, 0) > 0 THEN
               DISPLAY order_id TO s_search.orderid
               LET selected_option = cSearch
               ACCEPT DIALOG
            END IF

      END CONSTRUCT

      DISPLAY ARRAY order_result_list TO s_table.*
      END DISPLAY

      ON ACTION ACCEPT
         IF INFIELD(orderid) OR INFIELD(orderdate) OR order_result_list.getLength() == 0 THEN
            LET selected_option = cSearch
         ELSE
            LET selected_option = cView
         END IF
         ACCEPT DIALOG

      ON ACTION EXIT
         EXIT DIALOG

      ON ACTION CLOSE
         EXIT DIALOG

      ON ACTION search
         LET selected_option = cSearch
         ACCEPT DIALOG

      ON ACTION adv_search
         LET selected_option = cAdvSearch
         ACCEPT DIALOG

      ON ACTION excel_export
         LET selected_option = cExport
         ACCEPT DIALOG

      ON ACTION ADD
         LET selected_option = cAdd
         ACCEPT DIALOG

      ON ACTION MODIFY
         IF order_result_list.getLength() > 0 THEN
            LET selected_option = cEdit
            ACCEPT DIALOG
         END IF

      ON ACTION delete
         IF order_result_list.getLength() > 0 THEN
            LET selected_option = cDelete
            ACCEPT DIALOG
         END IF

      ON ACTION VIEW
         IF order_result_list.getLength() > 0 THEN
            LET selected_option = cView
            ACCEPT DIALOG
         END IF

      AFTER DIALOG
         LET listIdx = 0
         IF order_result_list.getLength() > 0 THEN
            LET listIdx = DIALOG.getCurrentRow("s_table")
            CALL set_current_recs()
         END IF
         VAR update_results = FALSE
         CASE selected_option
            WHEN cQuit
               EXIT DIALOG
            WHEN cSearch
               CALL execute_search(where_clause)
            WHEN cAdvSearch
               LET where_clause = advsearch_orders()
               IF where_clause.getLength() > 0 THEN
                  CALL execute_search(where_clause)
               END IF
            WHEN cExport
               CALL export_orders_to_excel()
            WHEN cAdd
               CALL init_new_order()
               IF main_input_md("A") THEN
                  LET update_results = TRUE
               END IF
            WHEN cEdit
               IF main_input_md("C") THEN
                  LET update_results = TRUE
               END IF
            WHEN cDelete
               IF delete_md_order() THEN
                  LET update_results = TRUE
               END IF
            WHEN cView
               IF view_md_order() THEN
                  LET update_results = TRUE
               END IF
         END CASE
         IF selected_option == cSearch OR selected_option == cAdvSearch THEN
            IF order_result_list.getLength() > 0 THEN
               LET listIdx = 1
               CALL set_current_recs()
               CALL DIALOG.setCurrentRow("s_table", listIdx)
            ELSE
               NEXT FIELD orderid
            END IF
         END IF
         IF update_results THEN
            CALL set_current_recs()
            CALL DIALOG.setCurrentRow("s_table", listIdx)
         END IF
         LET selected_option = NULL
         CONTINUE DIALOG

   END DIALOG

   CLOSE WINDOW mainWindow

END FUNCTION #mstr_detail_orders

PRIVATE FUNCTION execute_search(where_clause STRING) RETURNS ()
   DEFINE r_orders RECORD LIKE orders.*
   DEFINE r_order_details RECORD LIKE order_details.*
   DEFINE r_employee RECORD
      employeeid LIKE employees.employeeid,
      firstname LIKE employees.firstname,
      lastname LIKE employees.lastname
   END RECORD
   DEFINE r_customer RECORD LIKE customers.*
   DEFINE r_product RECORD LIKE products.*
   DEFINE r_shipper RECORD LIKE shippers.*

   DEFINE order_id LIKE orders.orderid = 0

   VAR sqlText = SFMT(
      "%1 %2 %3 %4 %5 %6 %7 %8 %9 %10",
      "SELECT orders.*, order_details.*, employees.employeeid, employees.firstname, ",
      "  employees.lastname, customers.*, products.*, shippers.*",
      "  FROM orders ",
      "  INNER JOIN employees ON employees.employeeid = orders.employeeid ",
      "  INNER JOIN customers ON customers.customerid = orders.customerid ",
      "  LEFT OUTER JOIN order_details ON order_details.orderid = orders.orderid ",
      "  LEFT OUTER JOIN products ON products.productid = order_details.productid ",
      "  LEFT OUTER JOIN shippers ON shippers.shipperid = orders.shipvia ",
      SFMT(" WHERE %1 ", where_clause),
      " ORDER BY orders.orderid "
   )

   CALL order_result_list.clear()
   CALL order_header_dict.clear()
   CALL order_detail_dict.clear()

   VAR header_idx = 0

   DECLARE cursSearchQuery CURSOR FROM sqlText
   FOREACH cursSearchQuery INTO r_orders.*, r_order_details.*, r_employee.*,
      r_customer.*, r_product.*, r_shipper.*

      IF order_id == r_orders.orderid THEN

         #Update totals and append detail for existing order
         CALL append_search_detail(order_id, r_order_details.*, r_product.productname)
         LET order_result_list[header_idx].totalqty += NVL(r_order_details.quantity,0)
         LET order_result_list[header_idx].totalamt += calc_line_total(r_order_details.unitprice, r_order_details.quantity, r_order_details.discount)

      ELSE
         LET header_idx += 1

         LET order_id = r_orders.orderid

         #Load the order_header_list record for each new order id
         LET order_result_list[header_idx].orderid = r_orders.orderid
         LET order_result_list[header_idx].orderdate = r_orders.orderdate
         LET order_result_list[header_idx].customerid = r_orders.customerid
         LET order_result_list[header_idx].employeeid = r_orders.employeeid
         LET order_result_list[header_idx].freight = r_orders.freight
         LET order_result_list[header_idx].shipcity = r_orders.shipcity
         LET order_result_list[header_idx].shipname = r_orders.shipname
         LET order_result_list[header_idx].shipcountry = r_orders.shipcountry

         LET order_result_list[header_idx].totalqty = NVL(r_order_details.quantity,0)
         LET order_result_list[header_idx].totalamt = calc_line_total(r_order_details.unitprice, r_order_details.quantity, r_order_details.discount)

         LET order_result_list[header_idx].employeename = SFMT("%1 %2", r_employee.firstname, r_employee.lastname)
         LET order_result_list[header_idx].companyname = r_customer.companyname

         LET order_result_list[header_idx].rowedit = cEditImage
         LET order_result_list[header_idx].rowdelete = cDeleteImage
         LET order_result_list[header_idx].rowview = cViewImage

         #Load the orders record
         LET order_header_dict[order_id].orderid = r_orders.orderid
         LET order_header_dict[order_id].orderdate = r_orders.orderdate
         LET order_header_dict[order_id].customerid = r_orders.customerid
         LET order_header_dict[order_id].employeeid = r_orders.employeeid
         LET order_header_dict[order_id].freight = r_orders.freight
         LET order_header_dict[order_id].requireddate = r_orders.requireddate
         LET order_header_dict[order_id].shipaddress = r_orders.shipaddress
         LET order_header_dict[order_id].shipcity = r_orders.shipcity
         LET order_header_dict[order_id].shipcountry = r_orders.shipcountry
         LET order_header_dict[order_id].shipname = r_orders.shipname
         LET order_header_dict[order_id].shippeddate = r_orders.shippeddate
         LET order_header_dict[order_id].shippostalcode = r_orders.shippostalcode
         LET order_header_dict[order_id].shipregion = r_orders.shipregion
         LET order_header_dict[order_id].shipvia = r_orders.shipvia
         LET order_header_dict[order_id].customername = r_customer.companyname
         LET order_header_dict[order_id].employeename = SFMT("%1 %2", r_employee.firstname, r_employee.lastname)

         #Append first detail record if present
         IF NVL(r_order_details.orderid, 0) > 0 THEN
            CALL append_search_detail(order_id, r_order_details.*, r_product.productname)
         END IF

      END IF

   END FOREACH

   IF where_clause IS NULL OR where_clause.getLength() = 0 THEN
      DISPLAY "Showing all orders" TO formonly.query_label
   ELSE
      DISPLAY SFMT("Filter: %1", where_clause) TO formonly.query_label
   END IF

END FUNCTION #execute_search

PRIVATE FUNCTION append_search_detail(order_id LIKE orders.orderid,
   r_dtl RECORD LIKE order_details.*, product_name LIKE products.productname) RETURNS ()

   VAR idx = order_detail_dict[order_id].getLength() + 1
   LET order_detail_dict[order_id][idx].orderid = r_dtl.orderid
   LET order_detail_dict[order_id][idx].productid = r_dtl.productid
   LET order_detail_dict[order_id][idx].productname = product_name
   LET order_detail_dict[order_id][idx].quantity = r_dtl.quantity
   LET order_detail_dict[order_id][idx].unitprice = r_dtl.unitprice
   LET order_detail_dict[order_id][idx].discount = r_dtl.discount
   LET order_detail_dict[order_id][idx].totalprice = calc_line_total(r_dtl.unitprice, r_dtl.quantity, r_dtl.discount)

END FUNCTION #append_search_detail

PRIVATE FUNCTION calc_line_total(
   unitprice LIKE order_details.unitprice,
   quantity LIKE order_details.quantity,
   discount LIKE order_details.discount) RETURNS (DECIMAL(12,2))

   RETURN NVL(unitprice * quantity * (1 - NVL(discount, 0)), 0)

END FUNCTION #calc_line_total

PRIVATE FUNCTION set_current_recs() RETURNS ()

   LET curr_result_rec = order_result_list[listIdx]
   LET curr_order_rec = order_header_dict[curr_result_rec.orderid]

   CALL curr_detail_list.clear()
   LET detailIdx = 0
   IF order_detail_dict.contains(curr_result_rec.orderid) THEN
      IF order_detail_dict[curr_result_rec.orderid].getLength() > 0 THEN
         VAR idx = 0
         FOR idx = 1 TO order_detail_dict[curr_result_rec.orderid].getLength()
            CALL curr_detail_list[idx].fromOrderDetail(order_detail_dict[curr_result_rec.orderid][idx])
         END FOR
         LET detailIdx = 1
      END IF
   END IF

END FUNCTION #set_current_recs

PRIVATE FUNCTION update_view_status() RETURNS ()

   DEFINE msg STRING

   LET msg = SFMT("Order %1 of %2 — ID %3, Customer %4, Total Qty %5, Total Amount %6",
                  listIdx,
                  order_result_list.getLength(),
                  curr_result_rec.orderid,
                  curr_result_rec.companyname,
                  curr_result_rec.totalqty,
                  curr_result_rec.totalamt)

   DISPLAY msg TO formonly.status_label

END FUNCTION #update_view_status

PRIVATE FUNCTION init_new_order() RETURNS ()
   INITIALIZE curr_order_rec TO NULL
   LET curr_order_rec.orderid = 0
   LET curr_order_rec.freight = 0
   LET curr_order_rec.orderdate = TODAY
   CALL curr_detail_list.clear()
   LET detailIdx = 0
END FUNCTION #init_new_order

PRIVATE FUNCTION sync_current_recs(is_new BOOLEAN) RETURNS ()

   IF is_new THEN
      LET listIdx = order_result_list.getLength() + 1
   END IF

   LET order_result_list[listIdx].orderid = curr_order_rec.orderid
   LET order_result_list[listIdx].customerid = curr_order_rec.customerid
   LET order_result_list[listIdx].companyname = curr_order_rec.customername
   LET order_result_list[listIdx].employeeid = curr_order_rec.employeeid
   LET order_result_list[listIdx].employeename = curr_order_rec.employeename
   LET order_result_list[listIdx].freight = curr_order_rec.freight
   LET order_result_list[listIdx].orderdate = curr_order_rec.orderdate
   LET order_result_list[listIdx].shipcity = curr_order_rec.shipcity
   LET order_result_list[listIdx].shipcountry = curr_order_rec.shipcountry
   LET order_result_list[listIdx].shipname = curr_order_rec.shipname

   LET order_header_dict[curr_order_rec.orderid] = curr_order_rec

   CALL update_detail_recs()
   CALL set_current_recs()

END FUNCTION #sync_current_recs

PRIVATE FUNCTION delete_current_recs() RETURNS ()

   VAR orderid = order_result_list[listIdx].orderid
   CALL order_result_list.deleteElement(listIdx)
   IF listIdx > order_result_list.getLength() THEN
      LET listIdx = order_result_list.getLength()
   END IF

   CALL order_header_dict.remove(orderid)
   CALL order_detail_dict.remove(orderid)

   IF listIdx > 0 THEN
      CALL set_current_recs()
   END IF

END FUNCTION #delete_current_recs

PRIVATE FUNCTION delete_current_recs_detail(rowIdx INTEGER) RETURNS ()

   CALL curr_detail_list.deleteElement(rowIdx)
   CALL update_detail_recs()
   CALL set_current_recs()

END FUNCTION #delete_current_recs_detail

PRIVATE FUNCTION update_detail_recs() RETURNS ()

   IF listIdx > 0 AND listIdx <= order_result_list.getLength() THEN

      LET curr_result_rec = order_result_list[listIdx]
      LET curr_result_rec.totalqty = 0
      LET curr_result_rec.totalamt = 0

      VAR orderid = curr_result_rec.orderid
      CALL order_detail_dict[orderid].clear()
      VAR idx = 0
      FOR idx = 1 TO curr_detail_list.getLength()
         LET order_detail_dict[orderid][idx] = curr_detail_list[idx].toOrderDetail()
         LET curr_result_rec.totalqty += curr_detail_list[idx].quantity
         LET curr_result_rec.totalamt += curr_detail_list[idx].totalprice

         LET curr_detail_list[idx].rowedit = cEditImage
         LET curr_detail_list[idx].rowdelete = cDeleteImage
      END FOR
      LET order_result_list[listIdx] = curr_result_rec
   END IF

END FUNCTION #update_detail_recs

PRIVATE FUNCTION main_input_md(input_mode CHAR(1)) RETURNS (BOOLEAN)

   OPEN WINDOW detailWindow WITH FORM "md_order_details"

   VAR result = input_md_order(input_mode)

   CLOSE WINDOW detailWindow

   RETURN result

END FUNCTION #main_input_md

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
         #Validate header
         VAR hdr_valid = curr_order_rec.validateRec(input_mode)
         IF NOT hdr_valid.valid_status THEN
            ERROR hdr_valid.valid_msg
            CONTINUE DIALOG
         END IF

         #Persist based on mode
         CALL save_order(input_mode)
         IF int_flag THEN
            ERROR "An error occurred while saving, please try again"
            CONTINUE DIALOG
         END IF
         MESSAGE "Your changes have been saved"

   END DIALOG

   IF int_flag THEN
      LET int_flag = FALSE
      RETURN FALSE
   END IF
   RETURN TRUE

END FUNCTION #input_md_order

PRIVATE FUNCTION save_order(input_mode CHAR(1)) RETURNS ()
   DEFINE hdr_status model_helper.t_valid_rec
   VAR is_new = (input_mode == "A")
   VAR success = FALSE

   TRY
      BEGIN WORK

      IF is_new THEN
         LET hdr_status = curr_order_rec.insertRec()
      ELSE
         LET hdr_status = curr_order_rec.updateRec()
         IF hdr_status.valid_status THEN
            DELETE FROM order_details WHERE orderid = curr_order_rec.orderid
         END IF
      END IF

      IF hdr_status.valid_status THEN
         LET success = TRUE
         VAR idx = 0
         FOR idx = 1 TO curr_detail_list.getLength()
            LET curr_detail_list[idx].orderid = curr_order_rec.orderid
            VAR dtl_status = curr_detail_list[idx].toOrderDetail().insertRec()
            IF NOT dtl_status.valid_status THEN
               LET success = FALSE
               ERROR dtl_status.valid_msg
               EXIT FOR
            END IF
         END FOR
         IF success THEN
            COMMIT WORK
            CALL sync_current_recs(is_new)
            MESSAGE SFMT("Order %1 successfully", IIF(is_new, "inserted", "updated"))
         ELSE
            ROLLBACK WORK
         END IF
      ELSE
         ROLLBACK WORK
         ERROR hdr_status.valid_msg
      END IF
   CATCH
      ROLLBACK WORK
      ERROR SFMT("Error saving order: %1", SQLCA.SQLERRM)
   END TRY
   IF NOT success THEN
      LET int_flag = TRUE
   END IF
END FUNCTION #save_order

PRIVATE FUNCTION delete_md_order() RETURNS (BOOLEAN)

   IF NOT dialog_prompt.delete_prompt() THEN
      RETURN FALSE
   END IF

   VAR success = FALSE
   TRY
      BEGIN WORK
      #Delete all detail records first (child rows)
      DELETE FROM order_details WHERE orderid = curr_order_rec.orderid
      #Delete the order header
      VAR del_status = curr_order_rec.deleteRec()
      IF del_status.valid_status THEN
         COMMIT WORK
         CALL delete_current_recs()
         MESSAGE "Order deleted successfully"
         LET success = TRUE
      ELSE
         ROLLBACK WORK
         ERROR del_status.valid_msg
      END IF
   CATCH
      ROLLBACK WORK
      ERROR "Error deleting order: ", SQLCA.SQLERRM
   END TRY
   RETURN success

END FUNCTION #delete_md_order

PRIVATE FUNCTION update_md_detail(rowIdx INTEGER, input_mode CHAR(1)) RETURNS (BOOLEAN)

   VAR order_dt_rec = curr_detail_list[rowIdx].toOrderDetail()

   IF input_mode == "A" THEN
      VAR status_rec = order_dt_rec.insertRec()
      IF NOT status_rec.valid_status THEN
         ERROR status_rec.valid_msg
         RETURN FALSE
      END IF
   ELSE
      VAR status_rec = order_dt_rec.updateRec()
      IF NOT status_rec.valid_status THEN
         ERROR status_rec.valid_msg
         RETURN FALSE
      END IF
   END IF

   CALL update_detail_recs()
   CALL set_current_recs()
   RETURN TRUE

END FUNCTION #update_md_detail

PRIVATE FUNCTION delete_md_detail(rowIdx INTEGER) RETURNS (BOOLEAN)

   IF NOT dialog_prompt.delete_prompt() THEN
      RETURN FALSE
   END IF

   VAR success = FALSE
   TRY
      BEGIN WORK
      #Delete the item with product id
      VAR product_id = curr_detail_list[rowIdx].productid
      DELETE FROM order_details 
         WHERE orderid = curr_order_rec.orderid
         AND productid = product_id

      COMMIT WORK
      CALL delete_current_recs_detail(rowIdx)
      MESSAGE "Order item deleted successfully"
      LET success = TRUE
   CATCH
      ROLLBACK WORK
      ERROR SFMT("Error deleting order detail record: %1", sqlca.sqlerrm)
   END TRY
   RETURN success

END FUNCTION #delete_md_detail

PRIVATE DIALOG header_input(input_mode CHAR(1))
   DEFINE selected_customer_id LIKE customers.customerid
   DEFINE selected_customer_name LIKE customers.companyname
   DEFINE selected_employee_id LIKE employees.employeeid
   DEFINE selected_employee_name STRING

   INPUT curr_order_rec.* FROM s_orders.*
      ATTRIBUTES(WITHOUT DEFAULTS = TRUE)

      ON ACTION zoom_customer
         CALL customer_lookup()
            RETURNING selected_customer_id, selected_customer_name
         IF selected_customer_id IS NOT NULL AND LENGTH(selected_customer_id) > 0 THEN
            LET curr_order_rec.customerid = selected_customer_id
            LET curr_order_rec.customername = selected_customer_name
            CALL curr_order_rec.default_shipping_from_customer()
         END IF

      ON ACTION zoom_employee
         CALL employee_lookup()
            RETURNING selected_employee_id, selected_employee_name
         IF selected_employee_id > 0 THEN
            LET curr_order_rec.employeeid = selected_employee_id
            LET curr_order_rec.employeename = selected_employee_name
         END IF

      AFTER FIELD customerid
         IF LENGTH(curr_order_rec.customerid) > 0 THEN
            VAR valid_status = model_customers.validate_customer(curr_order_rec.customerid)
            IF NOT valid_status.valid_status THEN
               ERROR valid_status.valid_msg
               NEXT FIELD customerid
            ELSE
               LET curr_order_rec.customername = valid_status.valid_msg
               CALL curr_order_rec.default_shipping_from_customer()
            END IF
         ELSE
            LET curr_order_rec.customername = ""
         END IF

      AFTER FIELD employeeid
         IF NVL(curr_order_rec.employeeid, 0) > 0 THEN
            VAR valid_status = model_employees.validate_employee(curr_order_rec.employeeid)
            IF NOT valid_status.valid_status THEN
               ERROR valid_status.valid_msg
               NEXT FIELD employeeid
            ELSE
               LET curr_order_rec.employeename = valid_status.valid_msg
            END IF
         ELSE
            LET curr_order_rec.employeename = ""
         END IF

      AFTER FIELD shipvia
         IF NVL(curr_order_rec.shipvia, 0) > 0 THEN
            VAR valid_status = model_shippers.validate_shipvia(curr_order_rec.shipvia)
            IF NOT valid_status.valid_status THEN
               ERROR valid_status.valid_msg
               NEXT FIELD shipvia
            END IF
         END IF

      AFTER INPUT
         VAR valid_status = curr_order_rec.validateRec(input_mode)
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE DIALOG
         END IF

   END INPUT

END DIALOG

PRIVATE DIALOG details_input(input_mode CHAR(1))
   DEFINE currentIdx INTEGER = 0
   DEFINE selected_product_id LIKE products.productid
   DEFINE selected_product_name LIKE products.productname

   INPUT ARRAY curr_detail_list FROM s_details.*
      ATTRIBUTES(WITHOUT DEFAULTS = TRUE, INSERT ROW = FALSE, AUTO APPEND=TRUE)

      BEFORE ROW
         LET currentIdx = DIALOG.getCurrentRow("s_details")
         IF currentIdx > 0 THEN
            IF currentIdx > curr_detail_list.getLength() THEN
               CALL curr_detail_list.appendElement()
            END IF
            IF NVL(curr_detail_list[currentIdx].orderid, 0) == 0 THEN
               LET curr_detail_list[currentIdx].orderid = curr_order_rec.orderid
            END IF
         END IF

      ON ACTION zoom_product
         LET currentIdx = DIALOG.getCurrentRow("s_details")
         CALL product_lookup()
            RETURNING selected_product_id, selected_product_name
         IF selected_product_id > 0 THEN
            LET curr_detail_list[currentIdx].productid = selected_product_id
            LET curr_detail_list[currentIdx].productname = selected_product_name
            CALL curr_detail_list[currentIdx].default_unitprice_from_product()
            CALL curr_detail_list[currentIdx].calcPrice()
         END IF

      ON CHANGE productid
         LET currentIdx = DIALOG.getCurrentRow("s_details")
         CALL curr_detail_list[currentIdx].default_unitprice_from_product()

      AFTER FIELD productid
         LET currentIdx = DIALOG.getCurrentRow("s_details")
         VAR val_status = curr_detail_list[currentIdx].toOrderDetail().validate_product()
         IF val_status.valid_status THEN
            CALL curr_detail_list[currentIdx].calcPrice()
            LET curr_detail_list[currentIdx].productname = val_status.valid_msg
         ELSE
            ERROR val_status.valid_msg
            NEXT FIELD productid
         END IF
         LET curr_detail_list[currentIdx].discount = NVL(curr_detail_list[currentIdx].discount, 0)
         LET curr_detail_list[currentIdx].quantity = NVL(curr_detail_list[currentIdx].quantity, 1)

      AFTER FIELD unitprice, quantity, discount
         LET currentIdx = DIALOG.getCurrentRow("s_details")
         #Do calculation
         CALL curr_detail_list[currentIdx].calcPrice()

      AFTER ROW
         LET currentIdx = DIALOG.getCurrentRow("s_details")
         IF NVL(curr_detail_list[currentIdx].orderid, 0) == 0 THEN
            LET curr_detail_list[currentIdx].orderid = curr_order_rec.orderid
         END IF
         #Do validation and calculation
         IF LENGTH(curr_detail_list[currentIdx].productid) > 0 THEN
            VAR rec_valid = curr_detail_list[currentIdx].toOrderDetail().validateRec(input_mode)
            IF NOT rec_valid.valid_status THEN
               ERROR rec_valid.valid_msg
               CALL DIALOG.setCurrentRow("s_details", currentIdx)
               CONTINUE DIALOG
            END IF
            #Do calculation
            CALL curr_detail_list[currentIdx].calcPrice()
         END IF

      AFTER INPUT
         #Do all input validation
         CALL array_cleanup(DIALOG)
         VAR outerIdx = 0
         FOR outerIdx = 1 TO curr_detail_list.getLength()
            VAR innerIdx = 0
            FOR innerIdx = outerIdx + 1 TO curr_detail_list.getLength()
               IF curr_detail_list[innerIdx].productid == curr_detail_list[outerIdx].productid THEN
                  ERROR "Cannot have 2 or more detail items with the same product, please consolidate"
                  CALL DIALOG.setCurrentRow("s_details", innerIdx)
                  CONTINUE DIALOG
               END IF
            END FOR
         END FOR

   END INPUT

END DIALOG

PRIVATE FUNCTION detail_single_input(input_mode CHAR(1)) RETURNS ()
   DEFINE selected_product_id LIKE products.productid
   DEFINE selected_product_name LIKE products.productname
   DEFINE orig_detail_rec t_detail_input_rec

   VAR arrIdx = detailIdx

   IF input_mode == "A" THEN
      LET curr_detail_list[arrIdx].orderid = curr_order_rec.orderid
      LET curr_detail_list[arrIdx].productid = NULL
      LET curr_detail_list[arrIdx].discount = 0
      LET curr_detail_list[arrIdx].quantity = 1
      LET curr_detail_list[arrIdx].totalprice = 0
      LET curr_detail_list[arrIdx].unitprice = 0
      LET detailIdx = arrIdx
   ELSE
      LET orig_detail_rec = curr_detail_list[arrIdx]
   END IF

   INPUT curr_detail_list[arrIdx].* WITHOUT DEFAULTS FROM s_details[arrIdx].*
      ATTRIBUTE(UNBUFFERED)
      BEFORE INPUT
         IF input_mode == "C" THEN
            CALL DIALOG.setFieldActive("s_details.productid", FALSE)
         END IF
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT

      ON ACTION zoom_product
         CALL product_lookup()
            RETURNING selected_product_id, selected_product_name
         IF selected_product_id > 0 THEN
            LET curr_detail_list[arrIdx].productid = selected_product_id
            LET curr_detail_list[arrIdx].productname = selected_product_name
            CALL curr_detail_list[arrIdx].default_unitprice_from_product()
            CALL curr_detail_list[arrIdx].calcPrice()
         END IF

      ON CHANGE productid
         CALL curr_detail_list[arrIdx].default_unitprice_from_product()

      AFTER FIELD productid
         VAR val_status = curr_detail_list[arrIdx].toOrderDetail().validate_product()
         IF val_status.valid_status THEN
            CALL curr_detail_list[arrIdx].calcPrice()
            LET curr_detail_list[arrIdx].productname = val_status.valid_msg
         ELSE
            ERROR val_status.valid_msg
            NEXT FIELD productid
         END IF
                  LET curr_detail_list[arrIdx].discount = NVL(curr_detail_list[arrIdx].discount, 0)
         LET curr_detail_list[arrIdx].quantity = NVL(curr_detail_list[arrIdx].quantity, 1)

      AFTER FIELD unitprice, quantity, discount
         CALL curr_detail_list[arrIdx].calcPrice()

      AFTER INPUT
         VAR valid_status = curr_detail_list[arrIdx].toOrderDetail().validateRec(input_mode)
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      IF input_mode == "A" THEN
         CALL curr_detail_list.deleteElement(arrIdx)
      ELSE
         LET curr_detail_list[arrIdx] = orig_detail_rec
      END IF
      RETURN
   END IF

END FUNCTION #detail_single_input

PRIVATE FUNCTION view_md_order() RETURNS (BOOLEAN)
   DEFINE selected_option SMALLINT
   DEFINE has_changes BOOLEAN

   OPEN WINDOW detailWindow WITH FORM "md_order_details"

   LET int_flag = FALSE
   LET has_changes = FALSE

   WHILE int_flag == FALSE

      DISPLAY curr_order_rec.* TO s_orders.*

      VAR row_action = FALSE
      DISPLAY ARRAY curr_detail_list TO s_details.*
         ATTRIBUTES(CANCEL=FALSE, ACCEPT=FALSE)

         BEFORE DISPLAY
            CALL update_view_status()
            LET selected_option = cQuit
            LET row_action = FALSE

         ON ACTION ADD
            LET selected_option = cAdd
            EXIT DISPLAY

         ON ACTION APPEND
            LET detailIdx = curr_detail_list.getLength() + 1
            CALL DIALOG.appendRow("s_details")
            LET selected_option = cAppend
            EXIT DISPLAY

         ON ACTION MODIFY
            LET selected_option = cEdit
            EXIT DISPLAY

         ON ACTION DELETE
            LET selected_option = cDelete
            EXIT DISPLAY

         ON ACTION deleterow
            VAR idx = DIALOG.getCurrentRow("s_details")
            VAR result = delete_md_detail(idx)
            IF NOT result THEN
               ERROR "Error deleting the selected order item"
               CONTINUE DISPLAY
            END IF
            LET has_changes = TRUE
            ACCEPT DISPLAY

         ON ACTION updaterow
            LET detailIdx = DIALOG.getCurrentRow("s_details")
            LET selected_option = cEdit
            LET row_action = TRUE
            EXIT DISPLAY

         ON ACTION EXIT
            LET selected_option = cQuit
            EXIT DISPLAY

         ON ACTION CLOSE
            LET selected_option = cQuit
            EXIT DISPLAY

         ON ACTION FIRST
            LET listIdx = 1
            ACCEPT DISPLAY

         ON ACTION PREVIOUS
            IF listIdx > 1 THEN
               LET listIdx -= 1
               ACCEPT DISPLAY
            END IF

         ON ACTION NEXT
            IF listIdx < order_result_list.getLength() THEN
               LET listIdx += 1
               ACCEPT DISPLAY
            END IF

         ON ACTION LAST
            LET listIdx = order_result_list.getLength()
            ACCEPT DISPLAY

         AFTER DISPLAY
            CALL set_current_recs()
            DISPLAY curr_order_rec.* TO s_orders.*
            IF curr_detail_list.getLength() > 0 THEN
               CALL DIALOG.setCurrentRow("s_details", 1)
            END IF
            CALL update_view_status()
            CONTINUE DISPLAY

      END DISPLAY #detail_list

      IF selected_option == cQuit THEN
         EXIT WHILE
      END IF

      VAR update_results = FALSE
      CASE selected_option
         WHEN cAdd
            CALL init_new_order()
            IF input_md_order("A") THEN
               LET listIdx = order_result_list.getLength()
               LET update_results = TRUE
               LET has_changes = TRUE
            END IF
         WHEN cEdit
            IF row_action THEN
               CALL detail_single_input("C")
               IF NOT int_flag THEN
                  IF update_md_detail(detailIdx, "C") THEN
                     LET update_results = TRUE
                     LET has_changes = TRUE
                  END IF
               END IF
            ELSE
               IF input_md_order("C") THEN
                  LET update_results = TRUE
                  LET has_changes = TRUE
               END IF
            END IF
         WHEN cAppend
            CALL detail_single_input("A")
            IF NOT int_flag THEN
               IF update_md_detail(detailIdx, "A") THEN
                  LET update_results = TRUE
                  LET has_changes = TRUE
               END IF
            END IF
         WHEN cDelete
            IF delete_md_order() THEN
               IF listIdx > order_result_list.getLength() THEN
                  LET listIdx = order_result_list.getLength()
               END IF
               LET update_results = TRUE
               LET has_changes = TRUE
            END IF
      END CASE
      LET int_flag = FALSE
      IF update_results THEN
         CALL set_current_recs()
      END IF

   END WHILE

   CLOSE WINDOW detailWindow

   RETURN has_changes

END FUNCTION #view_md_order

-- =====================================================================
-- Function: calcPrice (PRIVATE)
-- Purpose : Calculate total sell price = unitprice * quantity * (1 - discount)
-- =====================================================================
PRIVATE FUNCTION (self t_detail_input_rec) calcPrice() RETURNS ()

   LET self.totalprice = NVL(self.unitprice,0) * NVL(self.quantity,0) * (1 - NVL(self.discount,0))

END FUNCTION #calcPrice

PRIVATE FUNCTION (self t_detail_input_rec) toOrderDetail() RETURNS (t_order_detail)
   DEFINE rec_order_detail t_order_detail

   VAR jsonObj = util.JSONObject.fromFGL(self)
   CALL jsonObj.toFGL(rec_order_detail)

   RETURN rec_order_detail

END FUNCTION #toOrderDetail

PRIVATE FUNCTION (self t_detail_input_rec) fromOrderDetail(src t_order_detail) RETURNS ()

   VAR jsonObj = util.JSONObject.fromFGL(src)
   CALL jsonObj.toFGL(self)
   LET self.rowedit = cEditImage
   LET self.rowdelete = cDeleteImage

END FUNCTION #fromOrderDetail

-- =====================================================================
-- Function: default_unitprice_from_product (PRIVATE)
-- Purpose : Default unit price from the product record
-- =====================================================================
PRIVATE FUNCTION (self t_detail_input_rec) default_unitprice_from_product()
   DEFINE unit_price LIKE products.unitprice

   SELECT unitprice INTO unit_price FROM products WHERE productid = self.productid
   IF sqlca.sqlcode == 0 THEN
      LET self.unitprice = unit_price
   END IF

END FUNCTION #default_unitprice_from_product

-- =====================================================================
-- Function: load_shipvia_combo
-- Purpose : Populate the shipvia combobox from the shippers table
-- =====================================================================
PUBLIC FUNCTION load_shipvia_combo(cbx ui.ComboBox)
   DEFINE ship_id LIKE shippers.shipperid
   DEFINE ship_name LIKE shippers.companyname

   CALL cbx.clear()
   DECLARE c_shipvia CURSOR FOR
      SELECT shipperid, companyname FROM shippers ORDER BY companyname
   FOREACH c_shipvia INTO ship_id, ship_name
      CALL cbx.addItem(ship_id, ship_name)
   END FOREACH

END FUNCTION #load_shipvia_combo

PRIVATE FUNCTION array_cleanup(dlg ui.Dialog) RETURNS ()

   VAR idx INTEGER = 1
   WHILE idx <= curr_detail_list.getLength()
      IF NVL(curr_detail_list[idx].productid, 0) == 0 THEN
         CALL dlg.deleteRow("s_details", idx)
         CALL curr_detail_list.deleteElement(idx)
      ELSE
         LET idx = idx + 1
      END IF
   END WHILE

END FUNCTION #array_cleanup

PRIVATE FUNCTION export_orders_to_excel() RETURNS ()
   DEFINE jsonData util.JSONArray
   DEFINE excelFile STRING

   LET jsonData = util.JSONArray.fromFGL(order_result_list)
   LET excelFile = tableExcelExport("s_table", jsonData)

   IF excelFile IS NOT NULL AND excelFile.getLength() > 0 THEN
      CALL fgl_putfile(excelFile, os.Path.baseName(excelFile))
   ELSE
      ERROR "Excel export failed."
   END IF

END FUNCTION #export_orders_to_excel
