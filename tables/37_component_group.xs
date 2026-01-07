table component_group {
  auth = false

  schema {
    int id
    text Name? filters=trim
    text Code? filters=trim
    int tenant_id? {
      table = "tenant"
    }
  
    timestamp created_at?=now
    text Description? filters=trim
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}