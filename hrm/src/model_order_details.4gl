IMPORT FGL model_helper
IMPORT FGL model_orders
SCHEMA northwind

PUBLIC TYPE t_order_detail RECORD
   orderid LIKE order_details.orderid,
   productid LIKE order_details.productid,
   productname LIKE products.productname,
   unitprice LIKE order_details.unitprice,
   quantity LIKE order_details.quantity,
   discount LIKE order_details.discount,
   totalprice DECIMAL(10,2)
END RECORD

PRIVATE CONSTANT cMessagePrefix = "Order Detail Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current order detail record
-- =====================================================================
PUBLIC FUNCTION (self t_order_detail) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE detailExists SMALLINT = 0
   DEFINE product_name LIKE products.productname
   DEFINE valid_rec t_valid_rec

   # Check composite key exists for change or doesn't exist for add
   SELECT 1 INTO detailExists FROM order_details
    WHERE order_details.orderid = self.orderid
      AND order_details.productid = self.productid
   IF sqlca.sqlcode == NOTFOUND AND mode == "C" THEN
      CALL valid_rec.failed("Order detail record is not found")
      RETURN valid_rec
   END IF
   IF detailExists == 1 AND mode == "A" THEN
      CALL valid_rec.failed("Order detail record already exists for this order/product")
      RETURN valid_rec
   END IF

   # Validate required fields
   IF self.orderid IS NULL THEN
      CALL valid_rec.failed("Order ID is required")
      RETURN valid_rec
   END IF
   IF self.productid IS NULL THEN
      CALL valid_rec.failed("Product ID is required")
      RETURN valid_rec
   END IF
   IF self.unitprice IS NULL THEN
      CALL valid_rec.failed("Unit Price is required")
      RETURN valid_rec
   END IF
   IF self.quantity IS NULL THEN
      CALL valid_rec.failed("Quantity is required")
      RETURN valid_rec
   END IF
   IF self.discount IS NULL THEN
      CALL valid_rec.failed("Discount is required")
      RETURN valid_rec
   END IF

   # Validate foreign keys
   IF mode == "A" AND self.orderid > 0 THEN
      LET valid_rec = model_orders.validate_orderid(self.orderid)
      IF NOT valid_rec.valid_status THEN
         RETURN valid_rec
      END IF
   END IF

   SELECT productname INTO product_name FROM products WHERE products.productid = self.productid
   IF sqlca.sqlcode == NOTFOUND THEN
      CALL valid_rec.failed("Product ID does not exist in products table")
      RETURN valid_rec
   END IF
   LET self.productname = product_name

   # Validate data ranges
   IF self.unitprice < 0 THEN
      CALL valid_rec.failed("Unit Price cannot be negative")
      RETURN valid_rec
   END IF
   IF self.quantity < 1 THEN
      CALL valid_rec.failed("Quantity must be at least 1")
      RETURN valid_rec
   END IF
   LET valid_rec = validateDiscount(self.discount)
   IF NOT valid_rec.valid_status THEN
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the order detail record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_order_detail) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO order_details (orderid, productid, unitprice, quantity, discount)
      VALUES (self.orderid, self.productid,
              self.unitprice, self.quantity, self.discount)

   CALL ins_status.init()
   IF sqlca.sqlcode == 0 THEN
      CALL ins_status.success(SFMT(cMessagePrefix, "inserted"))
   ELSE
      CALL ins_status.failed(SFMT(cMessagePrefix, "insert failed"))
   END IF
   RETURN ins_status

END FUNCTION #insertRec

-- =====================================================================
-- Function: updateRec
-- Purpose : Update the order detail record in the database
-- =====================================================================
PUBLIC FUNCTION (self t_order_detail) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE order_details
      SET unitprice = self.unitprice,
          quantity = self.quantity,
          discount = self.discount
    WHERE orderid = self.orderid
      AND productid = self.productid

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
-- Purpose : Delete the order detail record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_order_detail) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM order_details
    WHERE orderid = self.orderid
      AND productid = self.productid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec

-- =====================================================================
-- Function: validateList (PUBLIC)
-- Purpose : List-level validation for an array of order_detail rows.
--          Currently enforces: no two rows may share the same productid
--          (a single order can't list the same product twice — callers
--          should consolidate them).
-- Returns : t_valid_rec carrying the rule's message, plus the 1-based
--          index of the offending row (the second occurrence of a
--          duplicate). Returns 0 when no list-level rule was violated.
--          Per-row rules belong in validateRec; this function is for
--          rules that only make sense across an array.
-- =====================================================================
PUBLIC FUNCTION validateList(arr DYNAMIC ARRAY OF t_order_detail)
                  RETURNS (t_valid_rec, INTEGER)
   DEFINE valid_status t_valid_rec
   DEFINE i, j INTEGER

   FOR i = 1 TO arr.getLength()
      IF arr[i].productid IS NULL THEN
         CONTINUE FOR
      END IF
      FOR j = i + 1 TO arr.getLength()
         IF arr[j].productid IS NOT NULL
            AND arr[i].productid == arr[j].productid THEN
            CALL valid_status.failed(
               "Cannot have 2 or more detail items with the same product, please consolidate")
            RETURN valid_status, j
         END IF
      END FOR
   END FOR

   CALL valid_status.success("Okay")
   RETURN valid_status, 0

END FUNCTION #validateList

-- =====================================================================
-- Function: validateDiscount (PUBLIC)
-- Purpose : Range check on the discount factor. Canonical rule is
--          0 <= discount < 1. NULL is treated as "not entered yet" and
--          short-circuits to success — callers that require a value
--          (validateRec) check NULL separately before invoking this.
-- =====================================================================
PUBLIC FUNCTION validateDiscount(discount LIKE order_details.discount)
                  RETURNS (t_valid_rec)
   DEFINE valid_status t_valid_rec

   IF discount IS NULL THEN
      CALL valid_status.success("")
      RETURN valid_status
   END IF
   IF discount < 0 OR discount >= 1 THEN
      CALL valid_status.failed("Discount Factor must be between 0 and 1")
   ELSE
      CALL valid_status.success("Okay")
   END IF
   RETURN valid_status

END FUNCTION #validateDiscount

-- =====================================================================
-- Function: calcLineTotal (PUBLIC)
-- Purpose : Canonical line-total formula for an order_details row.
--          NVL-tolerant on every input: NULL discount, quantity, or
--          unitprice contributes zero rather than NULL-poisoning the
--          result. This is the single source of truth for the formula
--          previously duplicated across md_order_details, ui_order_details,
--          and rest_order_details.
-- =====================================================================
PUBLIC FUNCTION calcLineTotal(unitprice LIKE order_details.unitprice,
                              quantity  LIKE order_details.quantity,
                              discount  LIKE order_details.discount)
                  RETURNS DECIMAL(12,2)

   RETURN NVL(unitprice, 0) * NVL(quantity, 0) * (1 - NVL(discount, 0))

END FUNCTION #calcLineTotal

-- =====================================================================
-- Function: validate_product (PUBLIC)
-- =====================================================================
PUBLIC FUNCTION (self t_order_detail) validate_product() RETURNS (t_valid_rec)
   DEFINE val_status t_valid_rec

   CALL val_status.success("Okay")
   IF self.productid IS NOT NULL THEN
      SELECT productname INTO self.productname FROM products WHERE products.productid = self.productid
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL val_status.failed("Product ID does not exist in products table")
      END IF
      LET val_status.valid_msg = self.productname
   END IF
   RETURN val_status

END FUNCTION #validate_product
