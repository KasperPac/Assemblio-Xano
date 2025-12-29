query "user/tenants" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    db.query user_tenant_role {
      join = {
        tenant: {
          table: "tenant"
          where: $db.user_tenant_role.tenant_id == $db.tenant.id
        }
      }
    
      where = $db.user_tenant_role.user_id == $auth.id
      eval = {
        tenant_name: $db.tenant.name
        tenant_logo: $db.tenant.logo
      }
    
      return = {type: "list"}
    } as $user_tenant_role1
  }

  response = $user_tenant_role1
}