// Details individual line items within a purchase order.
table purchase_order_line {
  auth = false

  schema {
    int id
    timestamp created_at?=now
  
    // Timestamp of the last update to the purchase order line item.
    timestamp updated_at?
  
    // Reference to the tenant account this purchase order line belongs to.
    int tenant? {
      table = "tenant"
    }
  
    // Reference to the parent purchase order.
    int purchase_order? {
      table = "purchase_order"
    }
  
    // Reference to the component being ordered.
    int component? {
      table = "component"
    }
  
    // The quantity of the component ordered.
    decimal quantity_ordered?
  
    // The quantity of the component already received.
    decimal quantity_received?
  
    // Reference to the location where the stock will be received, for future use.
    int location? {
      table = "location"
    }
  
    // The cost per unit of the component, for future costing.
    decimal unit_cost?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "gin", field: [{name: "xdo", op: "jsonb_path_op"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}