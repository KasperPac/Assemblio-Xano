// Delete tenant record.
query "tenant/{tenant_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int tenant_id? filters=min:1
  }

  stack {
    db.del tenant {
      field_name = "id"
      field_value = $input.tenant_id
    }
  }

  response = null
}