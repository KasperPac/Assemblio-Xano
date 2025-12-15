table order_line {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int order_id? {
      table = "order"
    }
  
    int shopify_line_item_id?
    int shopify_variant_id? {
      table = "shopify_variant"
    }
  
    decimal quantity_ordered?
    decimal quantity_fulfilled?
    text title?
    text variant_title?
    timestamp updated_at?
    decimal line_price?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}