// Edit order_line record
query "order_line/{order_line_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int order_line_id? filters=min:1
    dblink {
      table = "order_line"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch order_line {
      field_name = "id"
      field_value = $input.order_line_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $order_line
  }

  response = $order_line
}