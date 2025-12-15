table product_bom_component {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int product_bom_id? {
      table = "product_bom"
    }
  
    int component_id? {
      table = "component"
    }
  
    decimal quantity_per_unit?
    int sort_order?
    timestamp updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}