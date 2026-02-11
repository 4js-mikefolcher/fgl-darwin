DATABASE northwind
DEFINE arr_max INTEGER

FUNCTION init_pgm()

    OPTIONS MESSAGE LINE LAST - 2
    OPTIONS PROMPT LINE FIRST + 4
    OPTIONS ERROR LINE LAST - 1

    LET arr_max = 1000

    -- Load generic stylesheet for all windows
    CALL ui.Interface.loadStyles("generic.4st")

END FUNCTION

FUNCTION get_arr_max()

   IF arr_max == 0 THEN
      LET arr_max = 1000
   END IF
   RETURN arr_max

END FUNCTION

FUNCTION confirm_delete()

   MENU "Confirm Deletion"
      ATTRIBUTES(COMMENT="Are you sure you want to delete this record?", STYLE="dialog")
      COMMAND "Yes"
         RETURN TRUE
      COMMAND "No"
         EXIT MENU
   END MENU
   RETURN FALSE

END FUNCTION #confirm_delete
