table shopify_connections {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int tenant_id? {
      table = "tenant"
    }
  
    text shop_domain? filters=trim
    text access_token? filters=trim
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}