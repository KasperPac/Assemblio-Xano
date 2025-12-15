table component {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int tenant_id? {
      table = "tenant"
    }
  
    text sku?
    text name?
    text description?
    text unit_of_measure?
    decimal cost_per_unit?
    bool no_depreciate?
    int default_location_id? {
      table = "location"
    }
  
    decimal reorder_point?
    text preferred_supplier?
    bool is_active?
    timestamp updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}