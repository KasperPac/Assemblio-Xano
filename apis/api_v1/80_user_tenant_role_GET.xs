// Query all user_tenant_role records
query user_tenant_role verb=GET {
  api_group = "api_v1"

  input {
  }

  stack {
    db.query user_tenant_role {
      return = {type: "list"}
    } as $user_tenant_role
  }

  response = $user_tenant_role
}