table stocktake_line {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int stocktake_session_id? {
      table = "stocktake_session"
    }
  
    int tenant_id? {
      table = "tenant"
    }
  
    int component_id? {
      table = "component"
    }
  
    decimal expected_qty?
    decimal counted_qty?
    decimal? variance_qty?
    text status?
    text note?
    timestamp updated_at?
    decimal? variance_cost?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}