IMPORT FGL main_lib
IMPORT FGL report_helper
DATABASE northwind

-- =====================================================================
-- Report: Corporate Org Chart
-- Shows all employees in organizational chart structure using the
-- reportsto field to determine the supervisor hierarchy.
-- Uses Genero REPORT engine for text output.
-- =====================================================================

TYPE t_org_rec RECORD
   employeeid LIKE employees.employeeid,
   lastname LIKE employees.lastname,
   firstname LIKE employees.firstname,
   title LIKE employees.title,
   level INTEGER
END RECORD

DEFINE m_org_arr DYNAMIC ARRAY OF t_org_rec
DEFINE m_org_count INTEGER

-- =====================================================================
-- Function: run_org_chart
-- Purpose : Main entry point for the Corporate Org Chart report
-- =====================================================================
FUNCTION run_org_chart()
   DEFINE where_clause STRING
   DEFINE done SMALLINT

   LET done = FALSE

   OPEN WINDOW rptOrgWindow WITH FORM "rpt_org_chart"
      ATTRIBUTES(BORDER, STYLE="noactions")

   LET int_flag = FALSE

   MENU "Run Corporate Org Chart Report"

      ON ACTION run
         -- Execute report
         CALL execute_org_chart_report()
   
      ON ACTION exit
         LET int_flag = TRUE
         EXIT MENU

   END MENU

   CLOSE WINDOW rptOrgWindow

END FUNCTION #run_org_chart

-- =====================================================================
-- Function: execute_org_chart_report
-- Purpose : Build the org tree and output the report
-- =====================================================================
FUNCTION execute_org_chart_report()
   DEFINE where_clause STRING
   DEFINE rpt_file STRING
   DEFINE sql_stmt STRING
   DEFINE emp_id LIKE employees.employeeid
   DEFINE idx INTEGER

   CALL m_org_arr.clear()
   LET m_org_count = 0
   LET rpt_file = generate_temp_filename("rpt_org", "txt")

   CALL build_org_tree(NULL,0)  -- Start with top-level employees (reportsto IS NULL)

   IF m_org_arr.getLength() == 0 THEN
      MESSAGE "No employees found for the selected criteria."
      RETURN
   END IF

   -- Output the report
   START REPORT rpt_org_chart_output TO FILE rpt_file

   FOR idx = 1 TO m_org_arr.getLength()
      OUTPUT TO REPORT rpt_org_chart_output(m_org_arr[idx])
   END FOR

   FINISH REPORT rpt_org_chart_output

   MESSAGE SFMT("%1 employees written to %2", m_org_arr.getLength(), rpt_file)
   CALL display_report_file(rpt_file)

END FUNCTION #execute_org_chart_report

PRIVATE DEFINE m_define_null_cursor BOOLEAN = TRUE
PRIVATE DEFINE m_define_empl_cursor BOOLEAN = TRUE

-- =====================================================================
-- Function: build_org_tree
-- Purpose : Recursively build the org tree array starting from emp_id
-- Params  : emp_id - employee to add
--           level  - indentation level (0 = root)
-- =====================================================================
FUNCTION build_org_tree(emp_id LIKE employees.employeeid, level INTEGER)
   DEFINE rec t_org_rec
   DEFINE idx INTEGER
   DEFINE l_org_arr DYNAMIC ARRAY OF t_org_rec

   DISPLAY SFMT("Employee ID (%1) and Level (%2)", emp_id, level)

   -- If emp_id is NULL, we want to start with top-level employees (reportsto IS NULL)
   IF emp_id IS NULL THEN
      IF m_define_null_cursor THEN
         DECLARE c_top_employees CURSOR FROM
            "SELECT employeeid, lastname, firstname, title, 0 FROM employees WHERE reportsto IS NULL ORDER BY lastname, firstname"
         LET m_define_null_cursor = FALSE
      END IF
      FOREACH c_top_employees INTO rec.*
         LET rec.level = level
         LET idx = l_org_arr.getLength() + 1
         LET l_org_arr[idx] = rec
      END FOREACH
   ELSE
      IF m_define_empl_cursor THEN
         DECLARE c_employees CURSOR FROM
            "SELECT employeeid, lastname, firstname, title, 0 FROM employees WHERE reportsto = ? ORDER BY lastname, firstname"
         LET m_define_empl_cursor = FALSE
      END IF
      FOREACH c_employees USING emp_id INTO rec.*
         LET rec.level = level
         LET idx = l_org_arr.getLength() + 1
         LET l_org_arr[idx] = rec
      END FOREACH
   END IF

   FOR idx = 1 TO l_org_arr.getLength()
      VAR arrLen = m_org_arr.getLength() + 1
      LET m_org_arr[arrLen] = l_org_arr[idx]
      CALL build_org_tree(l_org_arr[idx].employeeid, level + 1)
   END FOR

END FUNCTION #build_org_tree

-- =====================================================================
-- Report: rpt_org_chart_output
-- Purpose : Format the Corporate Org Chart report output
-- =====================================================================
REPORT rpt_org_chart_output(r)
   DEFINE r t_org_rec
   DEFINE indent STRING
   DEFINE i INTEGER
   DEFINE line STRING
   DEFINE connector STRING

   OUTPUT
      PAGE LENGTH 66
      LEFT MARGIN 1

   FORMAT

      FIRST PAGE HEADER
         PRINT COLUMN 1, "==================================================================="
         PRINT COLUMN 1, "Corporate Org Chart"
         PRINT COLUMN 1, "Date: ", TODAY USING "mm/dd/yyyy"
         PRINT COLUMN 1, "==================================================================="
         SKIP 1 LINE

      PAGE HEADER
         PRINT COLUMN 1, "Corporate Org Chart (continued)"
         PRINT COLUMN 1, "-------------------------------------------------------------------"
         SKIP 1 LINE

      ON EVERY ROW
         -- Build indent based on level
         LET indent = ""
         FOR i = 1 TO r.level
            LET indent = indent, "|--"
         END FOR

         LET line = indent CLIPPED, connector CLIPPED,
                    r.firstname CLIPPED, " ", r.lastname CLIPPED

         IF r.title IS NOT NULL AND LENGTH(r.title) > 0 THEN
            LET line = line CLIPPED, " (", r.title CLIPPED, ")"
         END IF

         PRINT COLUMN 1, line CLIPPED

      ON LAST ROW
         SKIP 1 LINE
         PRINT COLUMN 1, "==================================================================="
         PRINT COLUMN 1, "Total Employees: ", COUNT(*) USING "###,##&"

END REPORT #rpt_org_chart_output
