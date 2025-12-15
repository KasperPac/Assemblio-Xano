// Add tenant record
query tenant verb=POST {
  api_group = "api_v1"

  input {
    dblink {
      table = "tenant"
    }
  }

  stack {
    db.add tenant {
      data = {created_at: "now"}
    } as $tenant
  }

  response = $tenant
}