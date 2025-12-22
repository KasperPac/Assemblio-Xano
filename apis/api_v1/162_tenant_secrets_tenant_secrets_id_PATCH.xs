// Edit tenant_secrets record
query "tenant_secrets/{tenant_secrets_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int tenant_secrets_id? filters=min:1
    dblink {
      table = "tenant_secrets"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch tenant_secrets {
      field_name = "id"
      field_value = $input.tenant_secrets_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $tenant_secrets
  }

  response = $tenant_secrets
}