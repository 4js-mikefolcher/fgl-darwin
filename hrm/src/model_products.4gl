IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_product RECORD
   productid SMALLINT,
   productname VARCHAR(40),
   supplierid SMALLINT,
   categoryid SMALLINT,
   quantityperunit VARCHAR(20),
   unitprice FLOAT,
   unitsinstock SMALLINT,
   unitsonorder SMALLINT,
   reorderlevel SMALLINT,
   discontinued INTEGER
END RECORD

PRIVATE CONSTANT cMessagePrefix = "Product Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current product record
-- =====================================================================
PUBLIC FUNCTION (self t_product) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE productExists SMALLINT
   DEFINE valid_rec t_valid_rec

   IF mode == "C" THEN
      SELECT 1 INTO productExists FROM products WHERE products.productid = self.productid
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL valid_rec.failed("Product ID is not found")
         RETURN valid_rec
      END IF
   END IF
   IF self.productname IS NULL OR LENGTH(self.productname) == 0 THEN
      CALL valid_rec.failed("Product Name is required")
      RETURN valid_rec
   END IF
   IF self.discontinued IS NULL THEN
      CALL valid_rec.failed("Discontinued flag is required")
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the product record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_product) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO products (productid, productname, supplierid, categoryid,
                         quantityperunit, unitprice, unitsinstock, unitsonorder,
                         reorderlevel, discontinued)
      VALUES (DEFAULT, self.productname, self.supplierid,
              self.categoryid, self.quantityperunit, self.unitprice,
              self.unitsinstock, self.unitsonorder, self.reorderlevel,
              self.discontinued)

   CALL ins_status.init()
   IF sqlca.sqlcode == 0 THEN
      CALL ins_status.success(SFMT(cMessagePrefix, "inserted"))
      LET self.productid = sqlca.sqlerrd[2]
   ELSE
      CALL ins_status.failed(SFMT(cMessagePrefix, "insert failed"))
   END IF
   RETURN ins_status

END FUNCTION #insertRec

-- =====================================================================
-- Function: updateRec
-- Purpose : Update the product record in the database
-- =====================================================================
PUBLIC FUNCTION (self t_product) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE products
      SET productname = self.productname,
          supplierid = self.supplierid,
          categoryid = self.categoryid,
          quantityperunit = self.quantityperunit,
          unitprice = self.unitprice,
          unitsinstock = self.unitsinstock,
          unitsonorder = self.unitsonorder,
          reorderlevel = self.reorderlevel,
          discontinued = self.discontinued
    WHERE productid = self.productid

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
-- Purpose : Delete the product record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_product) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM products
    WHERE productid = self.productid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec
