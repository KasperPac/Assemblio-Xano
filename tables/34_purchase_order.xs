// Manages purchase order data for inventory procurement.
table purchase_order {
  auth = false

  schema {
    int id
    timestamp created_at?=now
  
    // Timestamp of the last update to the purchase order.
    timestamp updated_at?
  
    // Reference to the tenant account this purchase order belongs to.
    int tenant? {
      table = "tenant"
    }
  
    // Reference to the user who created this purchase order.
    int created_by_user? {
      table = "user"
    }
  
    // The user-entered purchase order number.
    text po_number? filters=trim
  
    // Current status of the purchase order.
    enum status? {
      values = ["DRAFT", "ORDERED", "PARTIAL_RECEIVED", "RECEIVED", "CANCELLED"]
    }
  
    // Name of the supplier for this purchase order, for future UI use.
    text supplier_name? filters=trim
  
    // Additional notes related to the purchase order.
    text notes? filters=trim
  
    image? delivery_receipt?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "gin", field: [{name: "xdo", op: "jsonb_path_op"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}