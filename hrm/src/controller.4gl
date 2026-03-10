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
-- View Command Configuration
-- =====================================================================
PUBLIC TYPE t_view_command RECORD
   commandName    STRING,       -- action name (e.g. "orders")
   commandLabel   STRING,       -- display text (e.g. "Orders")
   commandComment STRING        -- tooltip/description
END RECORD

-- =====================================================================
-- Controller Configuration
-- =====================================================================
PUBLIC TYPE t_controller_config RECORD
   moduleName        STRING,        -- dispatch key (e.g. "suppliers")
   formName          STRING,        -- detail form name (e.g. "suppliers")
   listFormName      STRING,        -- list form name  (e.g. "suppliers_list")
   windowTitle       STRING,        -- MENU title text
   hasModify         BOOLEAN,       -- TRUE if module supports edit/modify
   hasQuery          BOOLEAN,       -- TRUE if module supports CONSTRUCT query
   hasLookup         BOOLEAN,       -- TRUE if module has a lookup function
   entityName        STRING,        -- display name (e.g. "Supplier")
   availableCommands DYNAMIC ARRAY OF t_view_command  -- view-related commands
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
-- Function: has_command (PRIVATE)
-- Purpose : Check if a command name exists in the availableCommands array
-- =====================================================================
PRIVATE FUNCTION has_command(cmdName STRING) RETURNS BOOLEAN
   DEFINE i INTEGER

   FOR i = 1 TO m_config.availableCommands.getLength()
      IF m_config.availableCommands[i].commandName == cmdName THEN
         RETURN TRUE
      END IF
   END FOR
   RETURN FALSE

END FUNCTION #has_command

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

          BEFORE MENU
             -- Hide view commands that are not available for this module
             CALL DIALOG.setActionHidden("cmd_orders",      NOT has_command("orders"))
             CALL DIALOG.setActionHidden("cmd_products",    NOT has_command("products"))
             CALL DIALOG.setActionHidden("cmd_territories", NOT has_command("territories"))
             CALL DIALOG.setActionHidden("cmd_customer",    NOT has_command("customer"))
             CALL DIALOG.setActionHidden("cmd_employee",    NOT has_command("employee"))
             CALL DIALOG.setActionHidden("cmd_shipper",     NOT has_command("shipper"))
             CALL DIALOG.setActionHidden("cmd_details",     NOT has_command("details"))
             CALL DIALOG.setActionHidden("cmd_supplier",    NOT has_command("supplier"))
             CALL DIALOG.setActionHidden("cmd_category",    NOT has_command("category"))
             CALL DIALOG.setActionHidden("cmd_region",      NOT has_command("region"))
             CALL DIALOG.setActionHidden("cmd_employees",   NOT has_command("employees"))
             CALL DIALOG.setActionHidden("cmd_cust_cust_demo", NOT has_command("cust_cust_demo"))

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

          -- View-related commands (hidden/shown per module)
          ON ACTION cmd_orders ATTRIBUTES(TEXT="Orders", IMAGE="fa-shopping-cart", COMMENT="View Orders")
              CALL dispatch_command(m_config.moduleName, "orders")
          ON ACTION cmd_products ATTRIBUTES(TEXT="Products", IMAGE="fa-list", COMMENT="View Products")
              CALL dispatch_command(m_config.moduleName, "products")
          ON ACTION cmd_territories ATTRIBUTES(TEXT="Territories", IMAGE="fa-map-marker", COMMENT="View Territories")
              CALL dispatch_command(m_config.moduleName, "territories")
          ON ACTION cmd_customer ATTRIBUTES(TEXT="Customer", IMAGE="fa-user", COMMENT="View Customer")
              CALL dispatch_command(m_config.moduleName, "customer")
          ON ACTION cmd_employee ATTRIBUTES(TEXT="Employee", IMAGE="fa-id-card", COMMENT="View Employee")
              CALL dispatch_command(m_config.moduleName, "employee")
          ON ACTION cmd_shipper ATTRIBUTES(TEXT="Shipper", IMAGE="fa-ship", COMMENT="View Shipper")
              CALL dispatch_command(m_config.moduleName, "shipper")
          ON ACTION cmd_details ATTRIBUTES(TEXT="Details", IMAGE="fa-list-alt", COMMENT="View Order Details")
              CALL dispatch_command(m_config.moduleName, "details")
          ON ACTION cmd_supplier ATTRIBUTES(TEXT="Supplier", IMAGE="fa-truck", COMMENT="View Supplier")
              CALL dispatch_command(m_config.moduleName, "supplier")
          ON ACTION cmd_category ATTRIBUTES(TEXT="Category", IMAGE="fa-tag", COMMENT="View Category")
              CALL dispatch_command(m_config.moduleName, "category")
          ON ACTION cmd_region ATTRIBUTES(TEXT="Region", IMAGE="fa-globe", COMMENT="View Region")
              CALL dispatch_command(m_config.moduleName, "region")
          ON ACTION cmd_employees ATTRIBUTES(TEXT="Employees", IMAGE="fa-users", COMMENT="View Employees")
              CALL dispatch_command(m_config.moduleName, "employees")
          ON ACTION cmd_cust_cust_demo ATTRIBUTES(TEXT="Customer Type", IMAGE="fa-tags", COMMENT="View Customer Type Assignments")
              CALL dispatch_command(m_config.moduleName, "cust_cust_demo")

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
-- Function: controller_add
-- Purpose : Convenience entry point: Single add at the root menu level.
-- =====================================================================
PUBLIC FUNCTION controller_add()

   CALL dispatch_add(m_config.moduleName)

END FUNCTION #controller_add

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
