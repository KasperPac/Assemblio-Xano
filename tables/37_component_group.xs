table component_group {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int tenant_id? {
      table = "tenant"
    }
  
    text Group? filters=trim
    text Code? filters=trim
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}