table product_bom {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int tenant_id? {
      table = "tenant"
    }
  
    int shopify_variant_id? {
      table = "shopify_variant"
    }
  
    int version?
    bool is_active?
    text notes?
    timestamp updated_at?
    int created_by_user_id? {
      table = "user"
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}