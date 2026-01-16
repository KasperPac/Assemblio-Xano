table shopify_store_secrets {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int shopify_store_id? {
      table = "shopify_store"
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}