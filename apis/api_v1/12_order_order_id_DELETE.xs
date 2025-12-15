// Delete order record.
query "order/{order_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int order_id? filters=min:1
  }

  stack {
    db.del order {
      field_name = "id"
      field_value = $input.order_id
    }
  }

  response = null
}