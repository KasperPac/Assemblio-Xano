function resolve_tenant {
  input {
    int user_id?
  }

  stack {
    !db.query "" {
      join = {
        user_role: {
          table: ""
          where: $input.user_id == $db.user_tenant_role.user_id
        }
      }
    
      return = {type: "list"}
    } as $user_role
  
    db.query user_tenant_role {
      join = {
        user: {
          table: "user"
          where: $db.user.id == $db.user_tenant_role.user_id
        }
      }
    
      return = {type: "list"}
    } as $user_role
  
    conditional {
      if ($user_role == null) {
        var $OutputVar {
          value = "{\n  \"error\": \"User has no tenant configured\"\n}"
        }
      }
    
      else {
        var $ctx_tenant_id {
          value = $user_role.0.tenant_id
        }
      
        var $ctx_role_id {
          value = $user_role.0.role_id
        }
      
        var $OutputVar {
          value = {
            tenant_id: $ctx_tenant_id
            role_id  : $ctx_role_id
            role_code: $ctx_role_code
          }
        }
      }
    }
  }

  response = {
    self: ```
      {
        "message": $OutputVar
      }
      ```
  }
}