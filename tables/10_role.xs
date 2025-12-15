table role {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    text code?
    text name?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}