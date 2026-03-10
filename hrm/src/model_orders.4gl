IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_order RECORD
   orderid LIKE orders.orderid,
   customerid LIKE orders.customerid,
   customername LIKE customers.companyname,
   employeeid LIKE orders.employeeid,
   employeename VARCHAR(30),
   orderdate LIKE orders.orderdate,
   requireddate LIKE orders.requireddate,
   shippeddate LIKE orders.shippeddate,
   shipvia LIKE orders.shipvia,
   freight LIKE orders.freight,
   shipname LIKE orders.shipname,
   shipaddress LIKE orders.shipaddress,
   shipcity LIKE orders.shipcity,
   shipregion LIKE orders.shipregion,
   shippostalcode LIKE orders.shippostalcode,
   shipcountry LIKE orders.shipcountry
END RECORD

PRIVATE CONSTANT cMessagePrefix = "Order Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current order record
-- =====================================================================
PUBLIC FUNCTION (self t_order) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE ordersExists SMALLINT
   DEFINE customer_name LIKE customers.companyname
   DEFINE employee_name CHAR(32)
   DEFINE valid_rec t_valid_rec

   IF mode == "C" THEN
      SELECT 1 INTO ordersExists FROM orders WHERE orders.orderid = self.orderid
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL valid_rec.failed("Order ID is not found")
         RETURN valid_rec
      END IF
   END IF

   IF self.orderdate IS NULL THEN
      CALL valid_rec.failed("Order Date is required")
      RETURN valid_rec
   END IF

   IF self.customerid IS NOT NULL AND LENGTH(self.customerid) > 0 THEN
      SELECT companyname INTO customer_name FROM customers WHERE customers.customerid = self.customerid
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL valid_rec.failed("Customer ID does not exist in customers table")
         RETURN valid_rec
      END IF
      LET self.customername = customer_name
   ELSE
      CALL valid_rec.failed("Customer ID is missing")
      RETURN valid_rec
   END IF

   IF self.employeeid IS NOT NULL THEN
      SELECT firstname || " " || lastname INTO employee_name
         FROM employees WHERE employees.employeeid = self.employeeid
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL valid_rec.failed("Employee ID does not exist in employees table")
         RETURN valid_rec
      END IF
      LET self.employeename = employee_name
   ELSE
      CALL valid_rec.failed("Employee ID is missing")
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the order record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_order) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO orders (orderid, customerid, employeeid, orderdate, requireddate, shippeddate,
                       shipvia, freight, shipname, shipaddress, shipcity, shipregion,
                       shippostalcode, shipcountry)
      VALUES (DEFAULT, self.customerid, self.employeeid,
              self.orderdate, self.requireddate, self.shippeddate,
              self.shipvia, self.freight, self.shipname,
              self.shipaddress, self.shipcity, self.shipregion,
              self.shippostalcode, self.shipcountry)

   CALL ins_status.init()
   IF sqlca.sqlcode == 0 THEN
      CALL ins_status.success(SFMT(cMessagePrefix, "inserted"))
      LET self.orderid = sqlca.sqlerrd[2]
   ELSE
      CALL ins_status.failed(SFMT(cMessagePrefix, "insert failed"))
   END IF
   RETURN ins_status

END FUNCTION #insertRec

-- =====================================================================
-- Function: updateRec
-- Purpose : Update the order record in the database
-- =====================================================================
PUBLIC FUNCTION (self t_order) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE orders
      SET customerid = self.customerid,
          employeeid = self.employeeid,
          orderdate = self.orderdate,
          requireddate = self.requireddate,
          shippeddate = self.shippeddate,
          shipvia = self.shipvia,
          freight = self.freight,
          shipname = self.shipname,
          shipaddress = self.shipaddress,
          shipcity = self.shipcity,
          shipregion = self.shipregion,
          shippostalcode = self.shippostalcode,
          shipcountry = self.shipcountry
    WHERE orderid = self.orderid

   CALL upd_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL upd_status.success(SFMT(cMessagePrefix, "updated"))
   ELSE
      CALL upd_status.failed(SFMT(cMessagePrefix, "update failed"))
   END IF
   RETURN upd_status

END FUNCTION #updateRec

-- =====================================================================
-- Function: deleteRec
-- Purpose : Delete the order record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_order) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM orders
    WHERE orderid = self.orderid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec

-- =====================================================================
-- Function: default_shipping_from_customer (PUBLIC)
-- Purpose : Populate shipping fields from selected customer address info
-- =====================================================================
PUBLIC FUNCTION (self t_order) default_shipping_from_customer()
   DEFINE contact_name LIKE customers.contactname
   DEFINE address LIKE customers.address
   DEFINE city LIKE customers.city
   DEFINE region LIKE customers.region
   DEFINE postalcode LIKE customers.postalcode
   DEFINE country LIKE customers.country

   SELECT c.contactname, c.address, c.city, c.region, c.postalcode, c.country
      INTO contact_name, address, city, region, postalcode, country
      FROM customers c
      WHERE customerid = self.customerid

   IF sqlca.sqlcode == 0 THEN
      LET self.shipname = contact_name
      LET self.shipaddress = address
      LET self.shipcity = city
      LET self.shipregion = region
      LET self.shippostalcode = postalcode
      LET self.shipcountry = country
   END IF

END FUNCTION #default_shipping_from_customer
