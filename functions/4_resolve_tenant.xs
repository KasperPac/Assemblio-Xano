function resolve_tenant {
  input {
    int user_id?
  }

  stack {
    !db.query user_tenant_role {
      join = {
        user_role: {
          table: "user_tenant_role"
          where: $input.user_id == $db.user_tenant_role.user_id
        }
      }
    
      return = {type: "list"}
    } as $user_role
  
    db.query user {
      where = $db.user.id == $input.user_id
      return = {type: "list"}
    } as $user1
  
    conditional {
      if ($user1 == null) {
        var $OutputVar {
          value = "{\n  \"error\": \"User has no tenant configured\"\n}"
        }
      }
    
      else {
        var $ctx_tenant_id {
          value = $user1.current_tenant
        }
      
        var $OutputVar {
          value = {tenant_id: $ctx_tenant_id}
        }
      }
    }
  }

  response = {self: $user1.current_tenant}
}