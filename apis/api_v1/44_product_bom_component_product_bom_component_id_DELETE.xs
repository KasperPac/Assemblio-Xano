// Delete product_bom_component record.
query "product_bom_component/{product_bom_component_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int product_bom_component_id? filters=min:1
  }

  stack {
    db.del product_bom_component {
      field_name = "id"
      field_value = $input.product_bom_component_id
    }
  }

  response = null
}