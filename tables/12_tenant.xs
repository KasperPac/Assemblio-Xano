table tenant {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    text name?
    text slug?
    text timezone?
    text currency?
    timestamp updated_at?
    image? logo?
    enum Plan? {
      values = ["Lite", "Starter", "Professional", "Enterprise"]
    }
  
    password token? {
      sensitive = true
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}