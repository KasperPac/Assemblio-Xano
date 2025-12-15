table activity_log {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int tenant_id? {
      table = "tenant"
    }
  
    int user_id? {
      table = "user"
    }
  
    text event_type?
    text entity_type?
    int entity_id?
    text message?
    object RawData? {
      schema
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}