IMPORT os
IMPORT FGL greruntime

-- =====================================================================
-- Module:  report_helper.4gl
-- Purpose: Report utility functions for viewing text report output
-- =====================================================================

-- Module-level variable to get the maximum width of the current report file for display purposes
PRIVATE DEFINE rpt_max_width INTEGER = 0
PRIVATE TYPE t_report_line RECORD
   line_text STRING
END RECORD
PRIVATE TYPE t_report_lines DYNAMIC ARRAY OF t_report_line

-- =====================================================================
-- Function: display_report_file
-- Purpose : Read a text file and display its contents in a DISPLAY ARRAY
-- Params  : rpt_file - full path to the text file to display
-- =====================================================================
FUNCTION display_report_file(rpt_file)
   DEFINE rpt_file STRING
   DEFINE lines t_report_lines
   DEFINE ch base.Channel
   DEFINE line STRING

   LET lines = file_to_array(rpt_file)

   IF lines.getLength() == 0 THEN
      ERROR "Report file is empty."
      RETURN
   END IF

   -- Display the report content
   OPEN WINDOW rptViewerWindow WITH FORM "report_viewer"
      ATTRIBUTES(STYLE="modulewindow")

   DISPLAY ARRAY lines TO s_lines.*

      ON ACTION exit
         EXIT DISPLAY

      ON ACTION to_pdf
         CALL export_report_to_pdf(rpt_file)

   END DISPLAY

   CLOSE WINDOW rptViewerWindow

END FUNCTION #display_report_file

PRIVATE FUNCTION file_to_array(rpt_file STRING) RETURNS (t_report_lines)
   DEFINE lines t_report_lines
   DEFINE ch base.Channel
   DEFINE line STRING

   LET ch = base.Channel.create()
   TRY
      CALL ch.openFile(rpt_file, "r")
   CATCH
      ERROR "Unable to open file: ", rpt_file
      RETURN lines -- empty array
   END TRY

   LET rpt_max_width = 0
   WHILE TRUE
      LET line = ch.readLine()
      IF ch.isEof() THEN
         EXIT WHILE
      END IF
      CALL lines.appendElement()
      LET lines[lines.getLength()].line_text = line
      IF line.getLength() > rpt_max_width THEN
         LET rpt_max_width = line.getLength()
      END IF
   END WHILE
   CALL ch.close()

   RETURN lines

END FUNCTION #file_to_array

PRIVATE FUNCTION export_report_to_pdf(rpt_file STRING)
   DEFINE pdf_file STRING

   -- Generate a PDF filename based on the report file
   LET pdf_file = rpt_file.replaceAll(".txt", ".pdf")

   -- Call a utility function to convert text report to PDF (implementation not shown)
   CALL convert_to_pdf(rpt_file, pdf_file)

   MESSAGE "Report exported to PDF: ", pdf_file

END FUNCTION #export_report_to_pdf

PRIVATE FUNCTION get_pdf_handler(pdf_file STRING) RETURNS om.SaxDocumentHandler

   IF greruntime.fgl_report_loadCurrentSettings(NULL) THEN
      VAR font_path = SFMT("..%1fonts%1inconsolata", os.Path.separator())
      CALL fgl_report_setPageMargins(15,15,15,15)
      CALL fgl_report_configurePDFDevice(font_path,NULL,NULL,NULL,NULL,NULL)
      CALL greruntime.fgl_report_configureCompatibilityOutput(
         rpt_max_width,
         --"Inconsolata Condensed SemiBold", 
         "Courier New",
         TRUE, 
         NULL, 
         NULL, 
         NULL
      )
      CALL fgl_report_selectDevice("PDF")
      CALL fgl_report_selectPreview(FALSE)
      CALL fgl_report_setOutputFileName(pdf_file)
      RETURN greruntime.fgl_report_commitCurrentSettings()
   END IF

   RETURN NULL

END FUNCTION #getPDFReportHandler

PRIVATE FUNCTION convert_to_pdf(rpt_file STRING, pdf_file STRING)

   DEFINE handler om.SaxDocumentHandler
   LET handler = get_pdf_handler(pdf_file)
   IF handler IS NULL THEN
      ERROR "Failed to configure PDF report handler."
      RETURN
   END IF
   VAR lines = file_to_array(rpt_file)

   START REPORT rpt_pdf_report
      TO XML HANDLER handler

   VAR idx INTEGER
   FOR idx = 1 TO lines.getLength()
      OUTPUT TO REPORT rpt_pdf_report(lines[idx].line_text)
   END FOR

   FINISH REPORT rpt_pdf_report

   CALL fgl_putfile(pdf_file, pdf_file) -- Ensure the file is saved to disk

END FUNCTION #convert_to_pdf

PRIVATE REPORT rpt_pdf_report(line STRING)

   FORMAT
      ON EVERY ROW
         PRINT line

END REPORT #rpt_pdf_report
