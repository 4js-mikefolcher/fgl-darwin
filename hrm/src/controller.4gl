-- =====================================================================
-- Module:  controller.4gl
-- Purpose: Generic record-at-a-time navigation controller.
--          Modules register callbacks via dispatch.4gl and call
--          controller functions to drive the standard CRUD/navigation
--          flow without duplicating menu/navigation logic.
-- =====================================================================
IMPORT FGL list_view_helper
IMPORT FGL dispatch

-- =====================================================================
-- Controller Configuration
-- =====================================================================
PUBLIC TYPE t_controller_config RECORD
   moduleName    STRING,        -- dispatch key (e.g. "suppliers")
   formName      STRING,        -- detail form name (e.g. "suppliers")
   listFormName  STRING,        -- list form name  (e.g. "suppliers_list")
   windowTitle   STRING,        -- MENU title text
   hasModify     BOOLEAN,       -- TRUE if module supports edit/modify
   hasQuery      BOOLEAN,       -- TRUE if module supports CONSTRUCT query
   hasLookup     BOOLEAN,       -- TRUE if module has a lookup function
   entityName    STRING         -- display name (e.g. "Supplier")
END RECORD

PRIVATE DEFINE m_config   t_controller_config
PRIVATE DEFINE m_idx      INTEGER       -- current index in result set

-- =====================================================================
-- Function: controller_init
-- Purpose : Configure the controller for a specific module
-- =====================================================================
PUBLIC FUNCTION controller_init(cfg t_controller_config)
   LET m_config = cfg
   LET m_idx = 0
END FUNCTION #controller_init

-- =====================================================================
-- Function: controller_navigate
-- Purpose : Main record-at-a-time navigation loop.
--           Expects the result set to already be loaded (query done).
-- =====================================================================
PUBLIC FUNCTION controller_navigate()
   DEFINE statusMessage CHAR(60)

   LET m_idx = 1
   WHILE m_idx > 0 AND m_idx <= dispatch_get_count(m_config.moduleName)

       CALL dispatch_load_at(m_config.moduleName, m_idx)
       CALL dispatch_display(m_config.moduleName)
       LET statusMessage = "Viewing ", m_idx USING "<<<<", " of ",
                           dispatch_get_count(m_config.moduleName) USING "<<<<"
       MESSAGE statusMessage

       MENU m_config.windowTitle

          ON ACTION first
              LET m_idx = 1
              EXIT MENU
          ON ACTION previous
              LET m_idx = m_idx - 1
              IF m_idx < 1 THEN
                 LET m_idx = 1
              END IF
              EXIT MENU
          ON ACTION next
              LET m_idx = m_idx + 1
              IF m_idx > dispatch_get_count(m_config.moduleName) THEN
                 LET m_idx = dispatch_get_count(m_config.moduleName)
              END IF
              EXIT MENU
          ON ACTION last
              LET m_idx = dispatch_get_count(m_config.moduleName)
              EXIT MENU

          ON ACTION add
              CALL dispatch_add(m_config.moduleName)
              IF int_flag == FALSE THEN
                 CALL dispatch_refresh(m_config.moduleName, m_idx, "A")
                 LET m_idx = dispatch_get_count(m_config.moduleName)
              END IF
              EXIT MENU

          ON ACTION modify
              IF m_config.hasModify THEN
                 CALL dispatch_edit(m_config.moduleName)
                 IF int_flag == FALSE THEN
                    CALL dispatch_refresh(m_config.moduleName, m_idx, "C")
                 END IF
              END IF
              EXIT MENU

          ON ACTION delete
              CALL dispatch_delete(m_config.moduleName)
              IF int_flag == FALSE THEN
                 CALL dispatch_refresh(m_config.moduleName, m_idx, "D")
                 IF m_idx > dispatch_get_count(m_config.moduleName) THEN
                    LET m_idx = dispatch_get_count(m_config.moduleName)
                 END IF
              END IF
              EXIT MENU

          ON ACTION list
              CALL controller_list_view()
              EXIT MENU

          ON ACTION query
              IF m_config.hasQuery THEN
                 CALL dispatch_query(m_config.moduleName)
                 IF dispatch_get_count(m_config.moduleName) > 0 THEN
                    LET m_idx = 1
                 ELSE
                    LET m_idx = 0
                 END IF
              END IF
              EXIT MENU

          ON ACTION exit
              LET m_idx = 0
              EXIT MENU

       END MENU

   END WHILE

END FUNCTION #controller_navigate

-- =====================================================================
-- Function: controller_navigate_view
-- Purpose : Read-only navigation (no add/edit/delete/query).
--           Used when navigating from a parent module (e.g. view_supplier).
-- =====================================================================
PUBLIC FUNCTION controller_navigate_view()
   DEFINE statusMessage CHAR(60)

   LET m_idx = 1
   WHILE m_idx > 0 AND m_idx <= dispatch_get_count(m_config.moduleName)

       CALL dispatch_load_at(m_config.moduleName, m_idx)
       CALL dispatch_display(m_config.moduleName)
       LET statusMessage = "Viewing ", m_idx USING "<<<<", " of ",
                           dispatch_get_count(m_config.moduleName) USING "<<<<"
       MESSAGE statusMessage

       MENU m_config.windowTitle

          ON ACTION first
              LET m_idx = 1
              EXIT MENU
          ON ACTION previous
              LET m_idx = m_idx - 1
              IF m_idx < 1 THEN
                 LET m_idx = 1
              END IF
              EXIT MENU
          ON ACTION next
              LET m_idx = m_idx + 1
              IF m_idx > dispatch_get_count(m_config.moduleName) THEN
                 LET m_idx = dispatch_get_count(m_config.moduleName)
              END IF
              EXIT MENU
          ON ACTION last
              LET m_idx = dispatch_get_count(m_config.moduleName)
              EXIT MENU

          ON ACTION exit
              LET m_idx = 0
              EXIT MENU

       END MENU

   END WHILE

END FUNCTION #controller_navigate_view

-- =====================================================================
-- Function: controller_list_view
-- Purpose : Generic list view using DISPLAY ARRAY and dispatch callbacks
-- =====================================================================
PRIVATE FUNCTION controller_list_view()
   DEFINE selectedIdx    INTEGER
   DEFINE selectedOption INTEGER

   LET selectedOption = 0
   LET selectedIdx = 0
   LET int_flag = FALSE

   OPEN WINDOW listWindow WITH FORM m_config.listFormName
      ATTRIBUTES(STYLE="modulewindow")

   MESSAGE "Displayed ", dispatch_get_count(m_config.moduleName) USING "<<<<<",
            " ", m_config.entityName CLIPPED, " records"

   CALL dispatch_list_display(m_config.moduleName)
      RETURNING selectedIdx, selectedOption

   CLOSE WINDOW listWindow

   IF NOT int_flag THEN
      CASE selectedOption
         WHEN cAddRecord
            CALL dispatch_add(m_config.moduleName)
            IF int_flag == FALSE THEN
               CALL dispatch_refresh(m_config.moduleName,
                  dispatch_get_count(m_config.moduleName), "A")
            END IF
         WHEN cEditRecord
            IF m_config.hasModify
               AND selectedIdx >= 1
               AND selectedIdx <= dispatch_get_count(m_config.moduleName) THEN
               CALL dispatch_load_at(m_config.moduleName, selectedIdx)
               CALL dispatch_edit(m_config.moduleName)
               IF int_flag == FALSE THEN
                  CALL dispatch_refresh(m_config.moduleName, selectedIdx, "C")
               END IF
            END IF
         WHEN cDeleteRecord
            IF selectedIdx >= 1
               AND selectedIdx <= dispatch_get_count(m_config.moduleName) THEN
               CALL dispatch_load_at(m_config.moduleName, selectedIdx)
               CALL dispatch_delete(m_config.moduleName)
               IF int_flag == FALSE THEN
                  CALL dispatch_refresh(m_config.moduleName, selectedIdx, "D")
               END IF
            ELSE
               ERROR "Please select a ", m_config.entityName CLIPPED
            END IF
         WHEN cViewRecord
            IF selectedIdx >= 1
               AND selectedIdx <= dispatch_get_count(m_config.moduleName) THEN
               LET m_idx = selectedIdx
            END IF
      END CASE
   END IF

END FUNCTION #controller_list_view

-- =====================================================================
-- Function: controller_query_then_navigate
-- Purpose : Convenience entry point: query first, then navigate results.
--           Used by submenu_* functions.
-- =====================================================================
PUBLIC FUNCTION controller_query_then_navigate()

   CALL dispatch_query(m_config.moduleName)
   IF dispatch_get_count(m_config.moduleName) == 0 THEN
      RETURN
   END IF
   CALL controller_navigate()

END FUNCTION #controller_query_then_navigate

-- =====================================================================
-- Function: controller_get_index
-- Purpose : Return the current navigation index
-- =====================================================================
PUBLIC FUNCTION controller_get_index() RETURNS INTEGER
   RETURN m_idx
END FUNCTION #controller_get_index

-- =====================================================================
-- Function: controller_set_index
-- Purpose : Set the current navigation index
-- =====================================================================
PUBLIC FUNCTION controller_set_index(idx INTEGER)
   LET m_idx = idx
END FUNCTION #controller_set_index
