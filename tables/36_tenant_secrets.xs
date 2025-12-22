table tenant_secrets {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    text shopify_token? filters=trim {
      sensitive = true
    }
  
    int tenant_id {
      table = "tenant"
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}