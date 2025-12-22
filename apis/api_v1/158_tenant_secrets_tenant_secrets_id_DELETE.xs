// Delete tenant_secrets record.
query "tenant_secrets/{tenant_secrets_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int tenant_secrets_id? filters=min:1
  }

  stack {
    db.del tenant_secrets {
      field_name = "id"
      field_value = $input.tenant_secrets_id
    }
  }

  response = null
}