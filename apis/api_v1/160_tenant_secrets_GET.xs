// Query all tenant_secrets records
query tenant_secrets verb=GET {
  api_group = "api_v1"

  input {
  }

  stack {
    db.query tenant_secrets {
      return = {type: "list"}
    } as $tenant_secrets
  }

  response = $tenant_secrets
}