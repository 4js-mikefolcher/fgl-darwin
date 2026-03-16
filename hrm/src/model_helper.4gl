PUBLIC TYPE t_valid_rec RECORD
   valid_status BOOLEAN,
   valid_msg STRING
END RECORD

PUBLIC FUNCTION (self t_valid_rec) init() RETURNS ()

   LET self.valid_status = FALSE
   LET self.valid_msg = ""

END FUNCTION #failed

PUBLIC FUNCTION (self t_valid_rec) success(msg STRING) RETURNS ()

   LET self.valid_status = TRUE
   LET self.valid_msg = msg

END FUNCTION #success

PUBLIC FUNCTION (self t_valid_rec) failed(msg STRING) RETURNS ()

   LET self.valid_status = FALSE
   LET self.valid_msg = msg

END FUNCTION #failed
