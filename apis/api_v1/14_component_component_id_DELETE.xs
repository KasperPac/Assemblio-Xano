// Delete component record.
query "component/{component_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int component_id? filters=min:1
  }

  stack {
    db.del component {
      field_name = "id"
      field_value = $input.component_id
    }
  }

  response = null
}