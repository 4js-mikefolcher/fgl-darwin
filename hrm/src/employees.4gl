IMPORT FGL list_view_helper
DATABASE northwind

TYPE t_employee_list RECORD
   employeeid LIKE employees.employeeid,
   lastname LIKE employees.lastname,
   firstname LIKE employees.firstname,
   title LIKE employees.title,
   city LIKE employees.city,
   country LIKE employees.country
END RECORD

DEFINE employeeList ARRAY[1000] OF RECORD
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

DEFINE listCount INTEGER
DEFINE arrayMax INTEGER

FUNCTION init_employees()

   LET arrayMax = get_arr_max()

END FUNCTION #init_region

FUNCTION submenu_employee()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   CALL init_employees()
   CALL query_employee()
   IF listCount == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= listCount

       CALL fillCurrentRec(currentIdx)
       CALL displayCurrentRec()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", listCount USING "<<<<"
       MESSAGE statusMessage

       MENU "Employee Management"
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
              IF currentIdx > listCount THEN
                 LET currentIdx = listCount
              END IF 
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = listCount
              EXIT MENU
          COMMAND "Add" "Add a new employee"
              CALL add_employee()
              IF int_flag == FALSE THEN
                 CALL appendEmployee()
                 LET currentIdx = listCount
              END IF
              EXIT MENU
          COMMAND "Modify" "Edit an existing employee"
              CALL edit_employee()
              IF int_flag == FALSE THEN
                 CALL updateEmployee()
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete an employee"
              CALL delete_employee()
              IF int_flag == FALSE THEN
                 CALL removeEmployee()
                 IF currentIdx > listCount THEN
                    LET currentIdx = listCount
                 END IF
              END IF
          COMMAND "List" "Switch to list view"
              CALL list_employees_view()
              EXIT MENU
          COMMAND "Territories" "Employee Territories"
              CALL terr_by_empl(currentRec.employeeid)
          COMMAND "Orders" "View Orders for this Employee"
              CALL view_orders_for_employee(currentRec.employeeid)
          COMMAND "ReportsTo" "View Manager"
              CALL view_employee(currentRec.reportsto)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION

-- =====================================================================
-- Function: list_employees_view
-- Purpose : Display employees in a list/table view
-- =====================================================================
FUNCTION list_employees_view()
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER
   DEFINE list_arr DYNAMIC ARRAY OF t_employee_list
   DEFINE idx INTEGER

   FOR idx = 1 TO listCount
      CALL list_arr.appendElement()
      LET list_arr[idx].employeeid = employeeList[idx].employeeid
      LET list_arr[idx].lastname = employeeList[idx].lastname
      LET list_arr[idx].firstname = employeeList[idx].firstname
      LET list_arr[idx].title = employeeList[idx].title
      LET list_arr[idx].city = employeeList[idx].city
      LET list_arr[idx].country = employeeList[idx].country
   END FOR

   OPEN WINDOW listEmployeesWindow WITH FORM "employees_list"
      ATTRIBUTES(STYLE="modulewindow")

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

   CLOSE WINDOW listEmployeesWindow

   IF int_flag THEN
      RETURN
   END IF

   CASE selectedOption
      WHEN cAddRecord
         CALL add_employee()
         IF int_flag == FALSE THEN
            CALL appendEmployee()
         END IF
      WHEN cEditRecord
         IF selectedIdx >= 1 AND selectedIdx <= listCount THEN
            CALL fillCurrentRec(selectedIdx)
            CALL edit_employee()
            IF int_flag == FALSE THEN
                  CALL updateEmployee()
            END IF
         ELSE
            ERROR "Please select an employee"
         END IF
      WHEN cDeleteRecord
         IF selectedIdx >= 1 AND selectedIdx <= listCount THEN
            CALL fillCurrentRec(selectedIdx)
            CALL delete_employee()
            IF int_flag == FALSE THEN
                  CALL removeEmployee()
            END IF
         ELSE
            ERROR "Please select an employee"
         END IF
      WHEN cViewRecord
         CALL fillCurrentRec(selectedIdx)
         CALL displayCurrentRec()
   END CASE

END FUNCTION #list_employees_view

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

FUNCTION employee_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL init_employees()
   CALL query_employee()
   IF listCount == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= listCount AND selectedIdx == 0

       CALL fillCurrentRec(currentIdx)
       CALL displayCurrentRec()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", listCount USING "<<<<"
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
              IF currentIdx > listCount THEN
                 LET currentIdx = listCount
              END IF 
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = listCount
              EXIT MENU
          COMMAND "Select" "Select the current region"
              LET selectedIdx = currentIdx
              CALL fillCurrentRec(selectedIdx)
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

END FUNCTION

FUNCTION view_employee(empl_id)
   DEFINE empl_id LIKE employees.employeeid
   DEFINE sqlText CHAR(2000)

   IF empl_id IS NULL OR empl_id < 1 THEN
      ERROR "Employee ID is missing or invalid"
      RETURN
   END IF

   CALL init_employees()
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
   CALL fillResultList(sqlText)

   IF listCount == 0 THEN
      CLOSE WINDOW viewWindow
      ERROR "Employee not found"
      RETURN
   END IF

   CALL fillCurrentRec(1)
   CALL displayCurrentRec()
   MENU "Employee View"

      COMMAND "Territories" "Employee Territories"
         CALL terr_by_empl(currentRec.employeeid)

      COMMAND "Exit" "Quit operation"
         EXIT MENU

   END MENU

   CLOSE WINDOW viewWindow

END FUNCTION

FUNCTION add_employee()
    DEFINE isValid SMALLINT
    DEFINE validMessage CHAR(60)

    CLEAR FORM
    CALL clearCurrentRec()
    LET int_flag = FALSE

    INPUT BY NAME currentRec.* WITHOUT DEFAULTS
        ON ACTION accept
           ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
           #Do validation
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

    CALL insertCurrentRec()
    MESSAGE "Employee record added"

END FUNCTION

FUNCTION edit_employee()
    DEFINE isValid SMALLINT
    DEFINE validMessage CHAR(60)

    LET int_flag = FALSE
    INPUT BY NAME currentRec.* WITHOUT DEFAULTS
        ON ACTION accept
           ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
           #Do validation
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

    CALL updateCurrentRec()
    MESSAGE "Employee record updated"

END FUNCTION


FUNCTION delete_employee()

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
        MESSAGE "Employee delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL deleteCurrentRec()
    MESSAGE "Employee record deleted"

END FUNCTION


FUNCTION query_employee()
    DEFINE id SMALLINT
    DEFINE sqlText CHAR(2000)

    LET int_flag = FALSE
    CONSTRUCT BY NAME sqlText
       ON employees.employeeid, employees.lastname, employees.firstname,
       employees.title, employees.titleofcourtesy,
       employees.birthdate, employees.hiredate, employees.address,
       employees.city, employees.region, employees.postalcode, employees.country,
       employees.homephone, employees.extension, employees.reportsto,
       employees.photopath, employees.notes # FROM s_employees.*

        ON ACTION accept
           ACCEPT CONSTRUCT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT CONSTRUCT

    END CONSTRUCT

    IF int_flag THEN
       CALL clearResultList()
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
    CALL fillResultList(sqlText)

    IF listCount == 0 THEN
        ERROR "No employees found"
        LET int_flag = TRUE
        RETURN
    END IF

    RETURN
END FUNCTION

FUNCTION clearResultList()
   DEFINE idx INTEGER

   FOR idx = 1 TO arrayMax
      INITIALIZE employeeList[idx].* TO NULL   
   END FOR
   LET listCount = 0

END FUNCTION #clearResultList

FUNCTION fillResultList(sqlText CHAR(2000))

   PREPARE prepResultSQL FROM sqlText
   DECLARE cursResultSQL CURSOR FOR prepResultSQL


   CALL clearResultList()
   FOREACH cursResultSQL INTO currentRec.*
      LET listCount = listCount + 1
      LET employeeList[listCount] = currentRec 
   END FOREACH

END FUNCTION #fillResultList

FUNCTION appendEmployee()

   LET listCount = listCount + 1
   LET employeeList[listCount] = currentRec

END FUNCTION

FUNCTION updateEmployee()
   DEFINE idx INTEGER

   FOR idx = 1 TO listCount
      IF employeeList[idx].employeeid = currentRec.employeeid THEN
         LET employeeList[idx] = currentRec
         EXIT FOR
      END IF
   END FOR

END FUNCTION

FUNCTION removeEmployee()
   DEFINE idx INTEGER
   DEFINE newIdx INTEGER
   DEFINE replaceRec SMALLINT

   LET newIdx = 0
   LET replaceRec = FALSE

   FOR idx = 1 TO listCount
      IF employeeList[idx].employeeid = currentRec.employeeid THEN
         LET replaceRec = TRUE
         CONTINUE FOR
      END IF
      LET newIdx = newIdx + 1
      LET employeeList[newIdx] = employeeList[idx]
   END FOR

   IF replaceRec THEN
      INITIALIZE employeeList[listCount].* TO NULL   
      LET listCount = listCount - 1
   END IF

END FUNCTION

FUNCTION clearCurrentRec()

   INITIALIZE currentRec.* TO NULL

END FUNCTION #clearCurrentRec

FUNCTION fillCurrentRec(idx)
   DEFINE idx INTEGER

   IF idx > 0 AND idx <= arrayMax THEN
      LET currentRec = employeeList[idx]
   ELSE
      CALL clearCurrentRec()
   END IF

END FUNCTION #fillCurrentRec

FUNCTION displayCurrentRec()

   DISPLAY BY NAME currentRec.*   

END FUNCTION #displayCurrentRec

FUNCTION insertCurrentRec()

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
   CALL displayCurrentRec()

END FUNCTION #insertCurrentRec

FUNCTION updateCurrentRec()

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

END FUNCTION #updateCurrentRec

FUNCTION deleteCurrentRec()

   DELETE FROM employees WHERE employeeid = currentRec.employeeid

END FUNCTION #deleteCurrentRec

FUNCTION employeeValidation(mode)
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

-- =====================================================================
-- Function: load_employees_ext
-- Purpose : Load employees using external where clause (for territories)
-- =====================================================================
FUNCTION load_employees_ext(where_clause)
   DEFINE where_clause VARCHAR(500)
   DEFINE sqlText CHAR(2000)

   CALL init_employees()

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
   CALL fillResultList(sqlText)

END FUNCTION #load_employees_ext

-- =====================================================================
-- Function: get_employees_count
-- Purpose : Return current employee list count
-- =====================================================================
FUNCTION get_employees_count()

   RETURN listCount

END FUNCTION #get_employees_count

-- =====================================================================
-- Function: submenu_employees_view
-- Purpose : View-only submenu for employees (no add/modify/delete)
-- =====================================================================
FUNCTION submenu_employees_view()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= listCount

       CALL fillCurrentRec(currentIdx)
       CALL displayCurrentRec()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", listCount USING "<<<<"
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
              IF currentIdx > listCount THEN
                 LET currentIdx = listCount
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = listCount
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