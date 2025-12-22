// Add tenant_secrets record
query tenant_secrets verb=POST {
  api_group = "api_v1"

  input {
    dblink {
      table = "tenant_secrets"
    }
  }

  stack {
    db.add tenant_secrets {
      data = {created_at: "now"}
    } as $tenant_secrets
  }

  response = $tenant_secrets
}