IMPORT com
IMPORT FGL rest_categories
IMPORT FGL rest_customers
IMPORT FGL rest_employees
IMPORT FGL rest_orders
IMPORT FGL rest_order_details
IMPORT FGL rest_products
IMPORT FGL rest_suppliers
IMPORT FGL rest_shippers
IMPORT FGL rest_region
IMPORT FGL rest_territories
IMPORT FGL rest_usstates
IMPORT FGL rest_empl_terr
IMPORT FGL rest_cust_demo
IMPORT FGL rest_cust_cust_demo

SCHEMA northwind

MAIN
   DEFINE status INTEGER

   DEFER INTERRUPT

   DATABASE northwind

   -- Register REST service modules
   CALL com.WebServiceEngine.RegisterRestService("rest_categories", "cat")
   CALL com.WebServiceEngine.RegisterRestService("rest_customers", "cust")
   CALL com.WebServiceEngine.RegisterRestService("rest_employees", "emp")
   CALL com.WebServiceEngine.RegisterRestService("rest_orders", "ord")
   CALL com.WebServiceEngine.RegisterRestService("rest_order_details", "odtl")
   CALL com.WebServiceEngine.RegisterRestService("rest_products", "prod")
   CALL com.WebServiceEngine.RegisterRestService("rest_suppliers", "supp")
   CALL com.WebServiceEngine.RegisterRestService("rest_shippers", "ship")
   CALL com.WebServiceEngine.RegisterRestService("rest_region", "regn")
   CALL com.WebServiceEngine.RegisterRestService("rest_territories", "terr")
   CALL com.WebServiceEngine.RegisterRestService("rest_usstates", "st")
   CALL com.WebServiceEngine.RegisterRestService("rest_empl_terr", "empt")
   CALL com.WebServiceEngine.RegisterRestService("rest_cust_demo", "demo")
   CALL com.WebServiceEngine.RegisterRestService("rest_cust_cust_demo", "cust_demo")

   DISPLAY "Northwind REST Server starting..."
   DISPLAY "Registered 14 REST service modules under /api"

   -- Start the web service engine
   CALL com.WebServiceEngine.Start()

   DISPLAY "REST Server is ready and listening for requests"

   -- Process incoming requests
   WHILE INT_FLAG = FALSE
      LET status = com.WebServiceEngine.ProcessServices(-1)
      CASE status
         WHEN 0    -- Request processed successfully
            DISPLAY "Processed request"
         WHEN -1   -- Timeout, continue waiting
            DISPLAY "Request Timeout"
         WHEN -2   -- Disconnected from application server
            DISPLAY "Disconnected from application server"
            EXIT WHILE
         WHEN -23  -- Deserialization error
            DISPLAY "REST deserialization error (status -23)"
         WHEN -35  -- REST operation not found
            DISPLAY "REST operation not found (status -35)"
         WHEN -36  -- Missing REST parameter
            DISPLAY "Missing REST parameter (status -36)"
         OTHERWISE
            DISPLAY SFMT("Unexpected status: %1", status)
      END CASE
   END WHILE

   DISPLAY "Northwind REST Server shutting down"
   DISCONNECT CURRENT
END MAIN
