// Edit role record
query "role/{role_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int role_id? filters=min:1
    dblink {
      table = "role"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch role {
      field_name = "id"
      field_value = $input.role_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $role
  }

  response = $role
}