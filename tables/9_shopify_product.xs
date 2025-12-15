table shopify_product {
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
  
    int shopify_product_id?
    text title?
    text handle?
    text status?
    text iamge_url? filters=trim
    timestamp updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}