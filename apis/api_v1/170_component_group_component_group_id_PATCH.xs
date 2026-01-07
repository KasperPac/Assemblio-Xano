// Edit component_group record
query "component_group/{component_group_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int component_group_id? filters=min:1
    dblink {
      table = "component_group"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch component_group {
      field_name = "id"
      field_value = $input.component_group_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $component_group
  }

  response = $component_group
}