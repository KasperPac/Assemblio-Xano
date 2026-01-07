// Delete component_group record.
query "component_group/{component_group_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int component_group_id? filters=min:1
  }

  stack {
    db.del component_group {
      field_name = "id"
      field_value = $input.component_group_id
    }
  }

  response = null
}