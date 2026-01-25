DATABASE northwind

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
          COMMAND "Territories" "Employee Territories"
              CALL terr_by_empl(currentRec.employeeid)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION

FUNCTION employee_lookup()
   DEFINE employee_id LIKE employees.employeeid
   DEFINE employee_name VARCHAR(32)

   OPEN WINDOW lookupWindow AT 5,5 WITH FORM "employees"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

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
   OPEN WINDOW viewWindow AT 5,5 WITH FORM "employees"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

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
        ON KEY(ACCEPT)
           ACCEPT INPUT
        ON KEY(CONTROL-P)
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
        ON KEY(ACCEPT)
           ACCEPT INPUT
        ON KEY(CONTROL-P)
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
    DEFINE answer CHAR(1)

    LET int_flag = FALSE
    PROMPT "Are you sure you want to delete this record? (Y/N)" FOR answer
    IF answer != "Y" THEN
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

        ON KEY(ACCEPT)
           ACCEPT CONSTRUCT
        ON KEY(CONTROL-P)
            LET int_flag = TRUE
            EXIT CONSTRUCT
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
      (currentRec.employeeid,
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

   SELECT 1 INTO employeeExists FROM employees WHERE employees.employeeid = currentRec.employeeid
   IF sqlca.sqlcode == NOTFOUND AND mode == "C" THEN
      RETURN FALSE, "Employee ID is not found"
   END IF
   IF sqlca.sqlcode == 0 AND mode == "A" THEN
      RETURN FALSE, "Employee ID already exists"
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
