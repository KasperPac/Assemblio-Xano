// Add user_tenant_role record
query user_tenant_role verb=POST {
  api_group = "api_v1"

  input {
    dblink {
      table = "user_tenant_role"
    }
  }

  stack {
    db.add user_tenant_role {
      data = {created_at: "now"}
    } as $user_tenant_role
  }

  response = $user_tenant_role
}