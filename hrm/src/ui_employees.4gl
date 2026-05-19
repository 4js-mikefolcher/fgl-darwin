IMPORT FGL main_lib
IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_employees
IMPORT FGL ui_empl_terr
IMPORT FGL ui_orders
IMPORT FGL model_helper
DATABASE northwind

TYPE t_employee_list RECORD
   employeeid LIKE employees.employeeid,
   lastname LIKE employees.lastname,
   firstname LIKE employees.firstname,
   title LIKE employees.title,
   city LIKE employees.city,
   country LIKE employees.country
END RECORD

DEFINE employeeList DYNAMIC ARRAY OF t_employee
DEFINE currentRec t_employee

-- =====================================================================
-- Function: get_config (PRIVATE)
-- Purpose : Return controller configuration for employees module
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS (t_controller_config)
   DEFINE cfg t_controller_config

   LET cfg.moduleName = "employees"
   LET cfg.formName = "employees"
   LET cfg.listFormName = "employees_list"
   LET cfg.windowTitle = "Employee Management"
   LET cfg.hasModify = TRUE
   LET cfg.hasQuery = TRUE
   LET cfg.hasLookup = TRUE
   LET cfg.entityName = "Employee"
   -- View commands available for this module
   LET cfg.availableCommands = init_view_commands()

   RETURN cfg

END FUNCTION #get_config

-- =====================================================================
-- Function: init_view_commands (PRIVATE)
-- Purpose : Define which view commands are available for employees
-- =====================================================================
PRIVATE FUNCTION init_view_commands() RETURNS DYNAMIC ARRAY OF t_view_command
   DEFINE cmds DYNAMIC ARRAY OF t_view_command
   LET cmds[1].commandName  = "territories"
   LET cmds[1].commandLabel = "Territories"
   LET cmds[1].commandComment = "View Employee Territories"
   LET cmds[2].commandName  = "orders"
   LET cmds[2].commandLabel = "Orders"
   LET cmds[2].commandComment = "View Orders for this Employee"
   RETURN cmds
END FUNCTION #init_view_commands

-- =====================================================================
-- Function: submenu_employee
-- Purpose : Main entry point for employee management
-- =====================================================================
FUNCTION submenu_employee()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_employee

-- =====================================================================
-- Function: root_add_employee
-- Purpose : Entry point for employee add from root menu
-- =====================================================================
FUNCTION root_add_employee()

   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_employee

-- =====================================================================
-- Dispatch interface: employees_get_count
-- =====================================================================
FUNCTION employees_get_count()

   RETURN employeeList.getLength()

END FUNCTION #employees_get_count

-- =====================================================================
-- Dispatch interface: employees_load_at
-- =====================================================================
FUNCTION employees_load_at(idx)
   DEFINE idx INTEGER

   INITIALIZE currentRec.* TO NULL
   IF idx >= 1 AND idx <= employeeList.getLength() THEN
      LET currentRec = employeeList[idx]
   END IF

END FUNCTION #employees_load_at

-- =====================================================================
-- Dispatch interface: employees_display_curr
-- =====================================================================
FUNCTION employees_display_curr()

   DISPLAY BY NAME currentRec.*

END FUNCTION #employees_display_curr

-- =====================================================================
-- Dispatch interface: employees_clear_curr
-- =====================================================================
FUNCTION employees_clear_curr()

   INITIALIZE currentRec.* TO NULL

END FUNCTION #employees_clear_curr

-- =====================================================================
-- Dispatch interface: employees_do_query
-- =====================================================================
FUNCTION employees_do_query()
   DEFINE sqlText CHAR(2000)

   CLEAR FORM
   CALL employees_clear_curr()
   CALL populate_courtesy_combo()
   LET int_flag = FALSE
   CONSTRUCT BY NAME sqlText
      ON employees.employeeid, employees.lastname, employees.firstname,
      employees.title, employees.titleofcourtesy,
      employees.birthdate, employees.hiredate, employees.address,
      employees.city, employees.region, employees.postalcode, employees.country,
      employees.homephone, employees.extension, employees.reportsto,
      employees.photopath, employees.notes

      ON ACTION accept
         ACCEPT CONSTRUCT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT CONSTRUCT
   END CONSTRUCT

   IF int_flag THEN
      CALL employeeList.clear()
      RETURN
   END IF

   LET sqlText = "SELECT ",
      "employees.employeeid, employees.lastname, employees.firstname, ",
      "employees.title, employees.titleofcourtesy, ",
      "employees.birthdate, employees.hiredate, employees.address, ",
      "employees.city, employees.region, employees.postalcode, employees.country, ",
      "employees.homephone, employees.extension, employees.reportsto, ",
      "RTRIM(e2.firstname) || ' ' || RTRIM(e2.lastname) as fullname, ",
      "employees.photopath, employees.notes ",
      "FROM employees ",
      "LEFT OUTER JOIN employees e2 ON e2.employeeid = employees.reportsto ",
      "WHERE ", sqlText CLIPPED
   CALL employees_do_load_sql(sqlText)

   IF employeeList.getLength() == 0 THEN
      ERROR "No employees found"
      RETURN
   END IF

END FUNCTION #employees_do_query

-- =====================================================================
-- Function: employees_do_load_sql (PRIVATE)
-- Purpose : Load employees into dynamic array based on full SQL text
-- =====================================================================
PRIVATE FUNCTION employees_do_load_sql(sqlText)
   DEFINE sqlText CHAR(2000)

   CALL employeeList.clear()

   PREPARE prepResultSQL FROM sqlText
   DECLARE cursResultSQL CURSOR FOR prepResultSQL
   FOREACH cursResultSQL INTO currentRec.*
      CALL employeeList.appendElement()
      LET employeeList[employeeList.getLength()] = currentRec
   END FOREACH
   CALL employees_clear_curr()

END FUNCTION #employees_do_load_sql

-- =====================================================================
-- Dispatch interface: employees_do_add_edit
-- =====================================================================
FUNCTION employees_do_add_edit(mode CHAR(1))

   CLEAR FORM
   LET int_flag = FALSE
   IF mode == "A" THEN
      CALL employees_clear_curr()
   END IF
   CALL populate_courtesy_combo()

   INPUT BY NAME currentRec.*
      ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS=TRUE)
      BEFORE INPUT
         CALL DIALOG.setFieldActive("employeeid", FALSE)
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      AFTER INPUT
         VAR valid_status = currentRec.validateRec(mode)
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      IF mode = "A" THEN
         ERROR "Employee add canceled"
      ELSE
         ERROR "Employee update canceled"
      END IF
      RETURN
   END IF

   VAR rec_status t_valid_rec
   IF mode = "A" THEN
      LET rec_status = currentRec.insertRec()
   ELSE
      LET rec_status = currentRec.updateRec()
   END IF

   IF rec_status.valid_status THEN
      CALL employees_display_curr()
      MESSAGE rec_status.valid_msg
   ELSE
      ERROR rec_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #employees_do_add_edit

-- =====================================================================
-- Dispatch interface: employees_do_delete
-- =====================================================================
FUNCTION employees_do_delete()

   LET int_flag = FALSE
   IF NOT confirm_delete() THEN
      MESSAGE "Employee delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   VAR del_status = currentRec.deleteRec()
   IF del_status.valid_status THEN
      MESSAGE del_status.valid_msg
   ELSE
      ERROR del_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #employees_do_delete

-- =====================================================================
-- Dispatch interface: employees_do_refresh
-- =====================================================================
FUNCTION employees_do_refresh(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL employeeList.appendElement()
         LET employeeList[employeeList.getLength()] = currentRec
      WHEN "C"
         LET employeeList[currIdx] = currentRec
      WHEN "D"
         FOR idx = 1 TO employeeList.getLength()
            IF employeeList[idx].employeeid = currentRec.employeeid THEN
               CALL employeeList.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #employees_do_refresh

-- =====================================================================
-- Dispatch interface: employees_list_display
-- =====================================================================
FUNCTION employees_list_display()
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER
   DEFINE list_arr DYNAMIC ARRAY OF t_employee_list
   DEFINE idx INTEGER

   FOR idx = 1 TO employeeList.getLength()
      CALL list_arr.appendElement()
      LET list_arr[idx].employeeid = employeeList[idx].employeeid
      LET list_arr[idx].lastname = employeeList[idx].lastname
      LET list_arr[idx].firstname = employeeList[idx].firstname
      LET list_arr[idx].title = employeeList[idx].title
      LET list_arr[idx].city = employeeList[idx].city
      LET list_arr[idx].country = employeeList[idx].country
   END FOR

   MESSAGE "Displayed ", list_arr.getLength() USING "<<<<<", " employees"

   DISPLAY ARRAY list_arr TO employees_list.*
      ON ACTION add
         LET selectedOption = cAddRecord
         EXIT DISPLAY
      ON ACTION modify
         LET selectedOption = cEditRecord
         LET selectedIdx = ARR_CURR()
         EXIT DISPLAY
      ON ACTION delete
         LET selectedIdx = ARR_CURR()
         LET selectedOption = cDeleteRecord
         EXIT DISPLAY
      ON ACTION exit
         LET int_flag = TRUE
         EXIT DISPLAY
      ON ACTION accept
         LET selectedIdx = ARR_CURR()
         LET selectedOption = cViewRecord
         EXIT DISPLAY
   END DISPLAY

   RETURN selectedIdx, selectedOption

END FUNCTION #employees_list_display

-- =====================================================================
-- Function: employees_do_command
-- Purpose : Execute a view command for employees
-- =====================================================================
FUNCTION employees_do_command(commandName STRING)
   CASE commandName
      WHEN "territories"
         CALL terr_by_empl(currentRec.employeeid)
      WHEN "orders"
         CALL view_orders_for_employee(currentRec.employeeid)
      OTHERWISE
         ERROR "Unknown command: ", commandName
   END CASE

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #employees_do_command

-- =====================================================================
-- Function: employee_lookup
-- Purpose : Open employee lookup window, return selected employee
-- =====================================================================
FUNCTION employee_lookup()
   DEFINE employee_id LIKE employees.employeeid
   DEFINE employee_name VARCHAR(32)

   OPEN WINDOW lookupWindow WITH FORM "employees"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_courtesy_combo()
   CALL employee_lookup_menu()
      RETURNING employee_id, employee_name

   CLOSE WINDOW lookupWindow

   RETURN employee_id, employee_name

END FUNCTION #employee_lookup

-- =====================================================================
-- Function: employee_lookup_menu
-- Purpose : Navigate employees for selection
-- =====================================================================
FUNCTION employee_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL employees_do_query()
   IF employeeList.getLength() == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= employeeList.getLength() AND selectedIdx == 0

      CALL employees_load_at(currentIdx)
      CALL employees_display_curr()
      LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", employeeList.getLength() USING "<<<<"
      MESSAGE statusMessage

      MENU "Employee Selection"
         COMMAND "First" "View first record in result set"
            LET currentIdx = 1
            EXIT MENU
         COMMAND "Previous" "View previous record in result set"
            LET currentIdx = currentIdx - 1
            IF currentIdx < 1 THEN
               LET currentIdx = 1
            END IF
            EXIT MENU
         COMMAND "Next" "View next record in result set"
            LET currentIdx = currentIdx + 1
            IF currentIdx > employeeList.getLength() THEN
               LET currentIdx = employeeList.getLength()
            END IF
            EXIT MENU
         COMMAND "Last" "View last record in result set"
            LET currentIdx = employeeList.getLength()
            EXIT MENU
         COMMAND "List" "Switch to List View"
            LET currentIdx = employees_lookup_table(currentIdx)
            IF int_flag OR currentIdx < 1 THEN
               LET int_flag = FALSE
            ELSE
               LET selectedIdx = currentIdx
               CALL employees_load_at(selectedIdx)
            END IF
            EXIT MENU
         COMMAND "Select" "Select the current employee"
            LET selectedIdx = currentIdx
            CALL employees_load_at(selectedIdx)
            EXIT MENU
         COMMAND "Exit" "Quit operation"
            LET currentIdx = 0
            EXIT MENU
      END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN currentRec.employeeid, currentRec.fullname
   END IF

   RETURN 0, ""

END FUNCTION #employee_lookup_menu

PRIVATE FUNCTION employees_lookup_table(currentIdx INTEGER) RETURNS (INTEGER)
   DEFINE list_arr DYNAMIC ARRAY OF t_employee_list
   DEFINE idx INTEGER

   OPEN WINDOW employees_list WITH FORM "employees_list"
      ATTRIBUTES(STYLE="modulewindow")

   FOR idx = 1 TO employeeList.getLength()
      CALL list_arr.appendElement()
      LET list_arr[idx].employeeid = employeeList[idx].employeeid
      LET list_arr[idx].lastname = employeeList[idx].lastname
      LET list_arr[idx].firstname = employeeList[idx].firstname
      LET list_arr[idx].title = employeeList[idx].title
      LET list_arr[idx].city = employeeList[idx].city
      LET list_arr[idx].country = employeeList[idx].country
   END FOR

   MESSAGE "Displayed ", list_arr.getLength() USING "<<<<<", " employees"

   VAR first_time = TRUE
   DISPLAY ARRAY list_arr TO employees_list.*
      ATTRIBUTES(DOUBLECLICK=ACCEPT)
      BEFORE ROW
         IF first_time THEN
            CALL DIALOG.setCurrentRow("employees_list", currentIdx)
            LET first_time = FALSE
         ELSE
            LET currentIdx = arr_curr()
         END IF
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT DISPLAY
      ON ACTION accept
         ACCEPT DISPLAY
   END DISPLAY

   CLOSE WINDOW employees_list

   RETURN currentIdx

END FUNCTION #employees_lookup_table

-- =====================================================================
-- Function: load_employees_ext
-- Purpose : Load employees using external where clause (for territories)
-- =====================================================================
FUNCTION load_employees_ext(where_clause)
   DEFINE where_clause VARCHAR(500)
   DEFINE sqlText CHAR(2000)

   LET sqlText = "SELECT ",
       "employees.employeeid, employees.lastname, employees.firstname, ",
       "employees.title, employees.titleofcourtesy, ",
       "employees.birthdate, employees.hiredate, employees.address, ",
       "employees.city, employees.region, employees.postalcode, employees.country, ",
       "employees.homephone, employees.extension, employees.reportsto, ",
       "RTRIM(e2.firstname) || ' ' || RTRIM(e2.lastname) as fullname, ",
       "employees.photopath, employees.notes ",
       "FROM employees ",
       "LEFT OUTER JOIN employees e2 ON e2.employeeid = employees.reportsto ",
       "WHERE ", where_clause CLIPPED
   CALL employees_do_load_sql(sqlText)

END FUNCTION #load_employees_ext

-- =====================================================================
-- Function: get_employees_count
-- Purpose : Return current employee list count
-- =====================================================================
FUNCTION get_employees_count()

   RETURN employeeList.getLength()

END FUNCTION #get_employees_count

-- =====================================================================
-- Function: submenu_employees_view
-- Purpose : View-only submenu for employees (no add/modify/delete)
--           Now delegates to the generic controller_navigate_view()
-- =====================================================================
FUNCTION submenu_employees_view()

   CALL controller_init(get_config())
   CALL controller_navigate_view()

END FUNCTION #submenu_employees_view

-- =====================================================================
-- Function: populate_courtesy_combo
-- Purpose : Populate the title of courtesy combobox with standard values
-- =====================================================================
FUNCTION populate_courtesy_combo()
   DEFINE cb ui.ComboBox

   LET cb = ui.ComboBox.forName("titleofcourtesy")
   IF cb IS NULL THEN
      RETURN
   END IF
   CALL cb.clear()
   CALL cb.addItem("Dr.",  "Dr.")
   CALL cb.addItem("Mr.",  "Mr.")
   CALL cb.addItem("Mrs.", "Mrs.")
   CALL cb.addItem("Ms.",  "Ms.")

END FUNCTION #populate_courtesy_combo

PRIVATE DEFINE load_empl_prepped BOOLEAN = FALSE
PUBLIC FUNCTION load_employees(cbx ui.ComboBox) RETURNS ()
   DEFINE empl_id LIKE employees.employeeid
   DEFINE empl_fname LIKE employees.firstname
   DEFINE empl_lname LIKE employees.lastname

   IF NOT load_empl_prepped THEN
      DECLARE curs_load_empls CURSOR FOR
         SELECT employees.employeeid, employees.firstname, employees.lastname
         FROM employees
         ORDER BY employees.lastname, employees.firstname
   END IF

   FOREACH curs_load_empls INTO empl_id, empl_fname, empl_lname
      CALL cbx.addItem(empl_id, SFMT("%1, %2 (%3)", empl_lname, empl_fname, empl_id))
   END FOREACH

END FUNCTION #load_employees


