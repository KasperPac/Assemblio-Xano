// Delete order_line record.
query "order_line/{order_line_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int order_line_id? filters=min:1
  }

  stack {
    db.del order_line {
      field_name = "id"
      field_value = $input.order_line_id
    }
  }

  response = null
}