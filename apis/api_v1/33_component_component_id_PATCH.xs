// Edit component record
query "component/{component_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int component_id? filters=min:1
    dblink {
      table = "component"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch component {
      field_name = "id"
      field_value = $input.component_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $component
  }

  response = $component
}