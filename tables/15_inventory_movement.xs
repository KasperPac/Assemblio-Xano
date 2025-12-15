table inventory_movement {
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
  
    text movement_type?
    decimal quantity_delta?
    decimal quantity_after?
    text reference_type?
    int reference_id?
    text reason_code?
    text note?
    int created_by_user_id? {
      table = "user"
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}