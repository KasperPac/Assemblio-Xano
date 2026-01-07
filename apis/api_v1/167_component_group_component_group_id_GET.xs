// Get component_group record
query "component_group/{component_group_id}" verb=GET {
  api_group = "api_v1"

  input {
    int component_group_id? filters=min:1
  }

  stack {
    db.get component_group {
      field_name = "id"
      field_value = $input.component_group_id
    } as $component_group
  
    precondition ($component_group != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $component_group
}