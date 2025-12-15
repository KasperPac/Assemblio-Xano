// A multi-tenant SaaS application designed to help Shopify merchants manage their inventory, Bill of Materials (BOMs), and order fulfillment processes. It provides tools for tracking components, managing stock levels across multiple locations, processing orders, and conducting stocktakes, all integrated with Shopify store data.
workspace "SaaS Inventory & BOM Management" {
  acceptance = {ai_terms: false}
  preferences = {
    internal_docs    : false
    track_performance: true
    sql_names        : false
    sql_columns      : true
  }
}