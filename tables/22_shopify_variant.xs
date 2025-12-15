table shopify_variant {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int tenant_id? {
      table = "tenant"
    }
  
    int shopify_product_id? {
      table = "shopify_product"
    }
  
    int shopify_variant_id?
    text sku?
    text title?
    decimal price?
    timestamp updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}