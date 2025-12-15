// Edit order_component_allocation record
query "order_component_allocation/{order_component_allocation_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int order_component_allocation_id? filters=min:1
    dblink {
      table = "order_component_allocation"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch order_component_allocation {
      field_name = "id"
      field_value = $input.order_component_allocation_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $order_component_allocation
  }

  response = $order_component_allocation
}