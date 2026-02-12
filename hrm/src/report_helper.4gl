-- =====================================================================
-- Module:  report_helper.4gl
-- Purpose: Report utility functions for viewing text report output
-- =====================================================================

-- =====================================================================
-- Function: display_report_file
-- Purpose : Read a text file and display its contents in a DISPLAY ARRAY
-- Params  : rpt_file - full path to the text file to display
-- =====================================================================
FUNCTION display_report_file(rpt_file)
   DEFINE rpt_file STRING
   DEFINE lines DYNAMIC ARRAY OF RECORD
      line_text STRING
   END RECORD
   DEFINE ch base.Channel
   DEFINE line STRING

   -- Read the file into the array
   LET ch = base.Channel.create()
   TRY
      CALL ch.openFile(rpt_file, "r")
   CATCH
      ERROR "Unable to open file: ", rpt_file
      RETURN
   END TRY

   WHILE TRUE
      LET line = ch.readLine()
      IF ch.isEof() THEN
         EXIT WHILE
      END IF
      CALL lines.appendElement()
      LET lines[lines.getLength()].line_text = line
   END WHILE
   CALL ch.close()

   IF lines.getLength() == 0 THEN
      ERROR "Report file is empty."
      RETURN
   END IF

   -- Display the report content
   OPEN WINDOW rptViewerWindow WITH FORM "report_viewer"

   DISPLAY ARRAY lines TO s_lines.*

      ON ACTION exit
         EXIT DISPLAY

   END DISPLAY

   CLOSE WINDOW rptViewerWindow

END FUNCTION #display_report_file
