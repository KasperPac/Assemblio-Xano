// Get the record belonging to the authentication token
query "auth/me" verb=GET {
  api_group = "auth"
  auth = "user"

  input {
  }

  stack {
    db.get user {
      field_name = "id"
      field_value = $auth.id
      output = [
        "id"
        "created_at"
        "name"
        "email"
        "account_id"
        "password_reset"
        "full_name"
        "updated_at"
      ]
    } as $user
  
    db.query user_tenant_role {
      join = {
        role: {
          table: "role"
          where: $db.user_tenant_role.role_id == $db.role.id
        }
      }
    
      where = $db.user_tenant_role.user_id == $user.id
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