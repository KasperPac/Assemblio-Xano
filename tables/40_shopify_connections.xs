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
    text scopes? filters=trim
    text status? filters=trim
    timestamp? installed_at?
    timestamp? updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}