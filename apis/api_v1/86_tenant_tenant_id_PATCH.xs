// Edit tenant record
query "tenant/{tenant_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int tenant_id? filters=min:1
    dblink {
      table = "tenant"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch tenant {
      field_name = "id"
      field_value = $input.tenant_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $tenant
  }

  response = $tenant
}