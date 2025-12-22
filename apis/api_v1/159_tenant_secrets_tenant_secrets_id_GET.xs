// Get tenant_secrets record
query "tenant_secrets/{tenant_secrets_id}" verb=GET {
  api_group = "api_v1"

  input {
    int tenant_secrets_id? filters=min:1
  }

  stack {
    db.get tenant_secrets {
      field_name = "id"
      field_value = $input.tenant_secrets_id
    } as $tenant_secrets
  
    precondition ($tenant_secrets != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $tenant_secrets
}