table inventory_balance {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int tenant_id? {
      table = "tenant"
    }
  
    int component_id? {
      table = "component"
    }
  
    int location_id? {
      table = "location"
    }
  
    decimal on_hand_qty?
    decimal in_progress_qty?
    decimal shipped_qty?
    timestamp updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}