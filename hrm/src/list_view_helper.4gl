IMPORT os
IMPORT util
IMPORT FGL com.fourjs.poiapi.fgl_table_export

PUBLIC CONSTANT cAddRecord = 1
PUBLIC CONSTANT cEditRecord = 2
PUBLIC CONSTANT cDeleteRecord = 3
PUBLIC CONSTANT cViewRecord = 4
PUBLIC CONSTANT cRefreshList = 5
PUBLIC CONSTANT cExportToExcel = 6

-- =====================================================================
-- Function: export_array_to_excel (PUBLIC)
-- Purpose : Export a JSON array to an Excel file via the POI API and
--           offer the resulting file to the client for download.
-- Params  : screen_record - the SCREEN RECORD name in the .per form
--           jsonData      - rows as a util.JSONArray (use
--                           util.JSONArray.fromFGL(arr) at the call site)
-- =====================================================================
PUBLIC FUNCTION export_array_to_excel(screen_record STRING, jsonData util.JSONArray) RETURNS ()
   DEFINE excelFile STRING

   LET excelFile = tableExcelExport(screen_record, jsonData)
   IF excelFile IS NOT NULL AND excelFile.getLength() > 0 THEN
      CALL fgl_putfile(excelFile, os.Path.baseName(excelFile))
   ELSE
      ERROR "Excel export failed."
   END IF

END FUNCTION #export_array_to_excel
