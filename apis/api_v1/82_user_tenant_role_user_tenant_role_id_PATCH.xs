// Edit user_tenant_role record
query "user_tenant_role/{user_tenant_role_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int user_tenant_role_id? filters=min:1
    dblink {
      table = "user_tenant_role"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch user_tenant_role {
      field_name = "id"
      field_value = $input.user_tenant_role_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $user_tenant_role
  }

  response = $user_tenant_role
}