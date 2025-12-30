// Get the record belonging to the authentication token
query "auth/me" verb=GET {
  api_group = "auth"
  auth = "user"

  input {
  }

  stack {
    !db.get user {
      field_name = "id"
      field_value = $auth.id
      output = [
        "id"
        "created_at"
        "name"
        "full_name"
        "email"
        "account_id"
        "updated_at"
        "Avatar.url"
      ]
    } as $user
  
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query user {
      join = {
        user_tenant_role: {
          table: "user_tenant_role"
          where: $db.user_tenant_role.user_id == $auth.id
        }
      }
    
      where = $db.user_tenant_role.tenant_id == $ctx_tenant.self.message.tenant_id && $db.user.id == $auth.id
      eval = {role_id: $db.user_tenant_role.role_id}
      return = {type: "single"}
    } as $user
  
    db.query user_tenant_role {
      join = {
        role: {
          table: "role"
          where: $db.user_tenant_role.role_id == $db.role.id
        }
      }
    
      where = $db.user_tenant_role.user_id == $user.id && $db.user_tenant_role.tenant_id == $user.current_tenant
      eval = {role_name: $db.role.name}
      return = {type: "single"}
    } as $tenant_role_info
  
    conditional {
      if ($tenant_role_info != null) {
        var.update $user {
          value = $user
            |set:"role_name":$tenant_role_info.role_name
            |set:"role_id":$tenant_role_info.role_id
        }
      }
    }
  }

  response = $user
}