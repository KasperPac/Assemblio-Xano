table order_component_allocation {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int tenant_id? {
      table = "tenant"
    }
  
    int order_line_id? {
      table = "order_line"
    }
  
    int component_id? {
      table = "component"
    }
  
    int location_id? {
      table = "location"
    }
  
    decimal quantity_required?
    decimal quantity_allocated?
    decimal quantity_consumed?
    timestamp updated_at?
    bool? ShortStock?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}