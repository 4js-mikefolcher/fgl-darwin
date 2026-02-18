-- =====================================================================
-- Module:  dispatch.4gl
-- Purpose: Central dispatch router for the generic controller.
--          Routes action calls to the correct module function based
--          on a module name key. Each module implements a standard set
--          of functions; this module provides the routing layer.
--
-- To add a new module:
--   1. Add a WHEN clause for the module name in each dispatch function
--   2. Map it to the module's corresponding function
-- =====================================================================

-- =====================================================================
-- Function: dispatch_get_count
-- Purpose : Return the number of records in the module's result set
-- =====================================================================
PUBLIC FUNCTION dispatch_get_count(moduleName STRING) RETURNS INTEGER

   CASE moduleName
      WHEN "suppliers"
         RETURN suppliers_get_count()
      WHEN "categories"
         RETURN categories_get_count()
      WHEN "customers"
         RETURN customers_get_count()
      WHEN "employees"
         RETURN employees_get_count()
      WHEN "empl_terr"
         RETURN empl_terr_get_count()
      WHEN "orders"
         RETURN orders_get_count()
      WHEN "order_details"
         RETURN order_details_get_count()
      WHEN "products"
         RETURN products_get_count()
      WHEN "region"
         RETURN region_get_count()
      WHEN "shippers"
         RETURN shippers_get_count()
      WHEN "territories"
         RETURN territories_get_count()
      WHEN "usstates"
         RETURN usstates_get_count()
      OTHERWISE
         RETURN 0
   END CASE

END FUNCTION #dispatch_get_count

-- =====================================================================
-- Function: dispatch_load_at
-- Purpose : Load the record at the given index into the current record
-- =====================================================================
PUBLIC FUNCTION dispatch_load_at(moduleName STRING, idx INTEGER)

   CASE moduleName
      WHEN "suppliers"
         CALL suppliers_load_at(idx)
      WHEN "categories"
         CALL categories_load_at(idx)
      WHEN "customers"
         CALL customers_load_at(idx)
      WHEN "employees"
         CALL employees_load_at(idx)
      WHEN "empl_terr"
         CALL empl_terr_load_at(idx)
      WHEN "orders"
         CALL orders_load_at(idx)
      WHEN "order_details"
         CALL order_details_load_at(idx)
      WHEN "products"
         CALL products_load_at(idx)
      WHEN "region"
         CALL region_load_at(idx)
      WHEN "shippers"
         CALL shippers_load_at(idx)
      WHEN "territories"
         CALL territories_load_at(idx)
      WHEN "usstates"
         CALL usstates_load_at(idx)
      OTHERWISE
         ERROR "Unknown module: ", moduleName
   END CASE

END FUNCTION #dispatch_load_at

-- =====================================================================
-- Function: dispatch_display
-- Purpose : Display the current record on the form
-- =====================================================================
PUBLIC FUNCTION dispatch_display(moduleName STRING)

   CASE moduleName
      WHEN "suppliers"
         CALL suppliers_display_curr()
      WHEN "categories"
         CALL categories_display_curr()
      WHEN "customers"
         CALL customers_display_curr()
      WHEN "employees"
         CALL employees_display_curr()
      WHEN "empl_terr"
         CALL empl_terr_display_curr()
      WHEN "orders"
         CALL orders_display_curr()
      WHEN "order_details"
         CALL order_details_display_curr()
      WHEN "products"
         CALL products_display_curr()
      WHEN "region"
         CALL region_display_curr()
      WHEN "shippers"
         CALL shippers_display_curr()
      WHEN "territories"
         CALL territories_display_curr()
      WHEN "usstates"
         CALL usstates_display_curr()
      OTHERWISE
         ERROR "Unknown module: ", moduleName
   END CASE

END FUNCTION #dispatch_display

-- =====================================================================
-- Function: dispatch_clear
-- Purpose : Clear the current record and form
-- =====================================================================
PUBLIC FUNCTION dispatch_clear(moduleName STRING)

   CASE moduleName
      WHEN "suppliers"
         CALL suppliers_clear_curr()
      WHEN "categories"
         CALL categories_clear_curr()
      WHEN "customers"
         CALL customers_clear_curr()
      WHEN "employees"
         CALL employees_clear_curr()
      WHEN "empl_terr"
         CALL empl_terr_clear_curr()
      WHEN "orders"
         CALL orders_clear_curr()
      WHEN "order_details"
         CALL order_details_clear_curr()
      WHEN "products"
         CALL products_clear_curr()
      WHEN "region"
         CALL region_clear_curr()
      WHEN "shippers"
         CALL shippers_clear_curr()
      WHEN "territories"
         CALL territories_clear_curr()
      WHEN "usstates"
         CALL usstates_clear_curr()
      OTHERWISE
         ERROR "Unknown module: ", moduleName
   END CASE

END FUNCTION #dispatch_clear

-- =====================================================================
-- Function: dispatch_query
-- Purpose : Execute the module's query (CONSTRUCT + load)
-- =====================================================================
PUBLIC FUNCTION dispatch_query(moduleName STRING)

   CASE moduleName
      WHEN "suppliers"
         CALL suppliers_do_query()
      WHEN "categories"
         CALL categories_do_query()
      WHEN "customers"
         CALL customers_do_query()
      WHEN "employees"
         CALL employees_do_query()
      WHEN "empl_terr"
         CALL empl_terr_do_query()
      WHEN "orders"
         CALL orders_do_query()
      WHEN "order_details"
         CALL order_details_do_query()
      WHEN "products"
         CALL products_do_query()
      WHEN "region"
         CALL region_do_query()
      WHEN "shippers"
         CALL shippers_do_query()
      WHEN "territories"
         CALL territories_do_query()
      WHEN "usstates"
         CALL usstates_do_query()
      OTHERWISE
         ERROR "Unknown module: ", moduleName
   END CASE

END FUNCTION #dispatch_query

-- =====================================================================
-- Function: dispatch_add
-- Purpose : Execute the module's add/insert flow
-- =====================================================================
PUBLIC FUNCTION dispatch_add(moduleName STRING)

   CASE moduleName
      WHEN "suppliers"
         CALL suppliers_do_add()
      WHEN "categories"
         CALL categories_do_add()
      WHEN "customers"
         CALL customers_do_add()
      WHEN "employees"
         CALL employees_do_add()
      WHEN "empl_terr"
         CALL empl_terr_do_add()
      WHEN "orders"
         CALL orders_do_add()
      WHEN "order_details"
         CALL order_details_do_add()
      WHEN "products"
         CALL products_do_add()
      WHEN "region"
         CALL region_do_add()
      WHEN "shippers"
         CALL shippers_do_add()
      WHEN "territories"
         CALL territories_do_add()
      WHEN "usstates"
         CALL usstates_do_add()
      OTHERWISE
         ERROR "Unknown module: ", moduleName
   END CASE

END FUNCTION #dispatch_add

-- =====================================================================
-- Function: dispatch_edit
-- Purpose : Execute the module's edit/update flow
-- =====================================================================
PUBLIC FUNCTION dispatch_edit(moduleName STRING)

   CASE moduleName
      WHEN "suppliers"
         CALL suppliers_do_edit()
      WHEN "categories"
         CALL categories_do_edit()
      WHEN "customers"
         CALL customers_do_edit()
      WHEN "employees"
         CALL employees_do_edit()
      WHEN "empl_terr"
         CALL empl_terr_do_edit()
      WHEN "orders"
         CALL orders_do_edit()
      WHEN "order_details"
         CALL order_details_do_edit()
      WHEN "products"
         CALL products_do_edit()
      WHEN "region"
         CALL region_do_edit()
      WHEN "shippers"
         CALL shippers_do_edit()
      WHEN "territories"
         CALL territories_do_edit()
      WHEN "usstates"
         CALL usstates_do_edit()
      OTHERWISE
         ERROR "Unknown module: ", moduleName
   END CASE

END FUNCTION #dispatch_edit

-- =====================================================================
-- Function: dispatch_delete
-- Purpose : Execute the module's delete flow
-- =====================================================================
PUBLIC FUNCTION dispatch_delete(moduleName STRING)

   CASE moduleName
      WHEN "suppliers"
         CALL suppliers_do_delete()
      WHEN "categories"
         CALL categories_do_delete()
      WHEN "customers"
         CALL customers_do_delete()
      WHEN "employees"
         CALL employees_do_delete()
      WHEN "empl_terr"
         CALL empl_terr_do_delete()
      WHEN "orders"
         CALL orders_do_delete()
      WHEN "order_details"
         CALL order_details_do_delete()
      WHEN "products"
         CALL products_do_delete()
      WHEN "region"
         CALL region_do_delete()
      WHEN "shippers"
         CALL shippers_do_delete()
      WHEN "territories"
         CALL territories_do_delete()
      WHEN "usstates"
         CALL usstates_do_delete()
      OTHERWISE
         ERROR "Unknown module: ", moduleName
   END CASE

END FUNCTION #dispatch_delete

-- =====================================================================
-- Function: dispatch_refresh
-- Purpose : Refresh the module's array after add/change/delete
-- =====================================================================
PUBLIC FUNCTION dispatch_refresh(moduleName STRING, idx INTEGER, operation CHAR(1))

   CASE moduleName
      WHEN "suppliers"
         CALL suppliers_do_refresh(idx, operation)
      WHEN "categories"
         CALL categories_do_refresh(idx, operation)
      WHEN "customers"
         CALL customers_do_refresh(idx, operation)
      WHEN "employees"
         CALL employees_do_refresh(idx, operation)
      WHEN "empl_terr"
         CALL empl_terr_do_refresh(idx, operation)
      WHEN "orders"
         CALL orders_do_refresh(idx, operation)
      WHEN "order_details"
         CALL order_details_do_refresh(idx, operation)
      WHEN "products"
         CALL products_do_refresh(idx, operation)
      WHEN "region"
         CALL region_do_refresh(idx, operation)
      WHEN "shippers"
         CALL shippers_do_refresh(idx, operation)
      WHEN "territories"
         CALL territories_do_refresh(idx, operation)
      WHEN "usstates"
         CALL usstates_do_refresh(idx, operation)
      OTHERWISE
         ERROR "Unknown module: ", moduleName
   END CASE

END FUNCTION #dispatch_refresh

-- =====================================================================
-- Function: dispatch_list_display
-- Purpose : Execute the module's DISPLAY ARRAY for list view.
--           Returns: selectedIdx (row chosen), selectedOption (action)
-- =====================================================================
PUBLIC FUNCTION dispatch_list_display(moduleName STRING)
   RETURNS (INTEGER, INTEGER)
   DEFINE l_idx INTEGER
   DEFINE l_opt INTEGER

   CASE moduleName
      WHEN "suppliers"
         CALL suppliers_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      WHEN "categories"
         CALL categories_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      WHEN "customers"
         CALL customers_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      WHEN "employees"
         CALL employees_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      WHEN "empl_terr"
         CALL empl_terr_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      WHEN "orders"
         CALL orders_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      WHEN "order_details"
         CALL order_details_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      WHEN "products"
         CALL products_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      WHEN "region"
         CALL region_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      WHEN "shippers"
         CALL shippers_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      WHEN "territories"
         CALL territories_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      WHEN "usstates"
         CALL usstates_list_display() RETURNING l_idx, l_opt
         RETURN l_idx, l_opt
      OTHERWISE
         ERROR "Unknown module: ", moduleName
         RETURN 0, 0
   END CASE

END FUNCTION #dispatch_list_display
