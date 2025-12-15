// Delete order_component_allocation record.
query "order_component_allocation/{order_component_allocation_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int order_component_allocation_id? filters=min:1
  }

  stack {
    db.del order_component_allocation {
      field_name = "id"
      field_value = $input.order_component_allocation_id
    }
  }

  response = null
}