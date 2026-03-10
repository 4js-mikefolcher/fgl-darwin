PUBLIC FUNCTION delete_prompt() RETURNS (BOOLEAN)

   VAR do_delete = FALSE
   MENU "Delete Confirmation"
      ATTRIBUTES(COMMENT="Are you sure you want to delete this record?", STYLE="dialog")
      COMMAND "Yes"
         LET do_delete = TRUE
         EXIT MENU
      COMMAND "No"
         EXIT MENU
   END MENU

   RETURN do_delete

END FUNCTION #delete_prompt