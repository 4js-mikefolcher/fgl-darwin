IMPORT FGL list_view_helper
IMPORT FGL controller
DATABASE northwind

TYPE t_employee_list RECORD
   employeeid LIKE employees.employeeid,
   lastname LIKE employees.lastname,
   firstname LIKE employees.firstname,
   title LIKE employees.title,
   city LIKE employees.city,
   country LIKE employees.country
END RECORD

DEFINE employeeList DYNAMIC ARRAY OF RECORD
   employeeid LIKE employees.employeeid,
   lastname LIKE employees.lastname,
   firstname LIKE employees.firstname,
   title LIKE employees.title,
   titleofcourtesy LIKE employees.titleofcourtesy,
   birthdate LIKE employees.birthdate,
   hiredate LIKE employees.hiredate,
   address LIKE employees.address,
   city LIKE employees.city,
   region LIKE employees.region,
   postalcode LIKE employees.postalcode,
   country LIKE employees.country,
   homephone LIKE employees.homephone,
   extension LIKE employees.extension,
   reportsto LIKE employees.reportsto,
   fullname VARCHAR(32),
   photopath LIKE employees.photopath,
   notes LIKE employees.notes
END RECORD

DEFINE currentRec RECORD
   employeeid LIKE employees.employeeid,
   lastname LIKE employees.lastname,
   firstname LIKE employees.firstname,
   title LIKE employees.title,
   titleofcourtesy LIKE employees.titleofcourtesy,
   birthdate LIKE employees.birthdate,
   hiredate LIKE employees.hiredate,
   address LIKE employees.address,
   city LIKE employees.city,
   region LIKE employees.region,
   postalcode LIKE employees.postalcode,
   country LIKE employees.country,
   homephone LIKE employees.homephone,
   extension LIKE employees.extension,
   reportsto LIKE employees.reportsto,
   fullname VARCHAR(32),
   photopath LIKE employees.photopath,
   notes LIKE employees.notes
END RECORD

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

   RETURN cfg

END FUNCTION #get_config

-- =====================================================================
-- Function: submenu_employee
-- Purpose : Main entry point for employee management
-- =====================================================================
FUNCTION submenu_employee()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_employee

-- =====================================================================
-- Function: view_employee
-- Purpose : View a specific employee record (called from other modules)
-- =====================================================================
FUNCTION view_employee(empl_id)
   DEFINE empl_id LIKE employees.employeeid
   DEFINE sqlText CHAR(2000)

   IF empl_id IS NULL OR empl_id < 1 THEN
      ERROR "Employee ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewWindow WITH FORM "employees"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_courtesy_combo()
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
       "WHERE employees.employeeid = ", empl_id
   CALL employees_do_load_sql(sqlText)

   IF employeeList.getLength() == 0 THEN
      CLOSE WINDOW viewWindow
      ERROR "Employee not found"
      RETURN
   END IF

   CALL controller_init(get_config())
   CALL controller_navigate_view()

   CLOSE WINDOW viewWindow

END FUNCTION #view_employee

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
-- Dispatch interface: employees_do_add
-- =====================================================================
FUNCTION employees_do_add()
   DEFINE isValid SMALLINT
   DEFINE validMessage CHAR(60)

   CLEAR FORM
   CALL employees_clear_curr()
   CALL populate_courtesy_combo()
   LET int_flag = FALSE

   INPUT BY NAME currentRec.* WITHOUT DEFAULTS
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      AFTER INPUT
         CALL employeeValidation('A')
            RETURNING isValid, validMessage
         IF isValid == FALSE THEN
            ERROR validMessage
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      MESSAGE "Employee add canceled"
      RETURN
   END IF

   INSERT INTO employees
      (employeeid,
      lastname,
      firstname,
      title,
      titleofcourtesy,
      birthdate,
      hiredate,
      address,
      city,
      region,
      postalcode,
      country,
      homephone,
      extension,
      reportsto,
      photopath,
      notes)
   VALUES
      (DEFAULT,
      currentRec.lastname,
      currentRec.firstname,
      currentRec.title,
      currentRec.titleofcourtesy,
      currentRec.birthdate,
      currentRec.hiredate,
      currentRec.address,
      currentRec.city,
      currentRec.region,
      currentRec.postalcode,
      currentRec.country,
      currentRec.homephone,
      currentRec.extension,
      currentRec.reportsto,
      currentRec.photopath,
      currentRec.notes)
   LET currentRec.employeeid = sqlca.sqlerrd[2]
   CALL employees_display_curr()
   MESSAGE "Employee record added"

END FUNCTION #employees_do_add

-- =====================================================================
-- Dispatch interface: employees_do_edit
-- =====================================================================
FUNCTION employees_do_edit()
   DEFINE isValid SMALLINT
   DEFINE validMessage CHAR(60)

   CALL populate_courtesy_combo()
   LET int_flag = FALSE
   INPUT BY NAME currentRec.* WITHOUT DEFAULTS
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      AFTER INPUT
         CALL employeeValidation('C')
            RETURNING isValid, validMessage
         IF isValid == FALSE THEN
            ERROR validMessage
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      MESSAGE "Employee update canceled"
      RETURN
   END IF

   UPDATE employees
      SET lastname = currentRec.lastname,
          firstname = currentRec.firstname,
          title = currentRec.title,
          titleofcourtesy = currentRec.titleofcourtesy,
          birthdate = currentRec.birthdate,
          hiredate = currentRec.hiredate,
          address = currentRec.address,
          city = currentRec.city,
          region = currentRec.region,
          postalcode = currentRec.postalcode,
          country = currentRec.country,
          homephone = currentRec.homephone,
          extension = currentRec.extension,
          notes = currentRec.notes,
          reportsto = currentRec.reportsto,
          photopath = currentRec.photopath
    WHERE employeeid = currentRec.employeeid
   MESSAGE "Employee record updated"

END FUNCTION #employees_do_edit

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

   DELETE FROM employees WHERE employeeid = currentRec.employeeid
   MESSAGE "Employee record deleted"

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
-- =====================================================================
FUNCTION submenu_employees_view()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= employeeList.getLength()

      CALL employees_load_at(currentIdx)
      CALL employees_display_curr()
      LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", employeeList.getLength() USING "<<<<"
      MESSAGE statusMessage

      MENU "Employees View"
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
         COMMAND "Territories" "Employee Territories"
            CALL terr_by_empl(currentRec.employeeid)
         COMMAND "Orders" "View Orders for this Employee"
            CALL view_orders_for_employee(currentRec.employeeid)
         COMMAND "Exit" "Quit operation"
            LET currentIdx = 0
            EXIT MENU
      END MENU

   END WHILE

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

-- =====================================================================
-- Function: employeeValidation (PRIVATE)
-- Purpose : Validate employee data
-- =====================================================================
PRIVATE FUNCTION employeeValidation(mode)
   DEFINE mode CHAR(1)
   DEFINE employeeExists SMALLINT
   DEFINE fullname VARCHAR(32)

   IF mode == "C" THEN
      SELECT 1 INTO employeeExists FROM employees WHERE employees.employeeid = currentRec.employeeid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Employee ID is not found"
      END IF
   END IF

   IF currentRec.firstname IS NULL OR LENGTH(currentRec.firstname) == 0 THEN
      RETURN FALSE, "First name is missing"
   END IF

   IF currentRec.lastname IS NULL OR LENGTH(currentRec.lastname) == 0 THEN
      RETURN FALSE, "Last name is missing"
   END IF

   IF currentRec.birthdate IS NULL THEN
      RETURN FALSE, "Birth date is missing"
   END IF

   IF currentRec.hiredate IS NULL THEN
      RETURN FALSE, "Hire date name is missing"
   END IF

   IF currentRec.hiredate <= currentRec.birthdate THEN
      RETURN FALSE, "Hire date is before birth date"
   END IF

   IF currentRec.reportsto IS NOT NULL AND currentRec.reportsto > 0 THEN
      SELECT RTRIM(firstname) || ' ' || RTRIM(lastname) INTO fullname
        FROM employees WHERE employees.employeeid = currentRec.reportsto
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Invalid reports to employee id value"
      END IF
      LET currentRec.fullname = fullname
   END IF

   RETURN TRUE, "Okay"

END FUNCTION #employeeValidation
