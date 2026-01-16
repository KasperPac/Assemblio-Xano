table shopify_store_secrets {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int shopify_store_id? {
      table = "shopify_store"
    }
  
    text access_token? filters=trim
    text scopes? filters=trim
    timestamp? installed_at?
    text? state? filters=trim
    timestamp? updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}