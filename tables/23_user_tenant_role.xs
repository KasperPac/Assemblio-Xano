table user_tenant_role {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int user_id? {
      table = "user"
    }
  
    int tenant_id? {
      table = "tenant"
    }
  
    int role_id? {
      table = "role"
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}