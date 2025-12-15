table order {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int tenant_id? {
      table = "tenant"
    }
  
    int shopify_store_id? {
      table = "shopify_store"
    }
  
    int shopify_order_id?
    text order_number?
    timestamp placed_at?
    text financial_status?
    text fulfillment_status?
    text customer_name?
    text currency?
    decimal total_price?
    text status_internal?
    timestamp updated_at?
    email customer_email?
    text? customer_phone? filters=trim
    text? customer_address? filters=trim
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}