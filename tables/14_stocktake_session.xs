table stocktake_session {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int tenant_id? {
      table = "tenant"
    }
  
    int location_id? {
      table = "location"
    }
  
    text name?
    text status?
    timestamp started_at?
    timestamp completed_at?
    int created_by_user_id? {
      table = "user"
    }
  
    timestamp updated_at?
    bool APPROVED?
    bool LOCKED?
    date date_from?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}