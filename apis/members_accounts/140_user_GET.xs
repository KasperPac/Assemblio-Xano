query user verb=GET {
  api_group = "Members & Accounts"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // Fetch all users associated with the resolved tenant via the user_tenant_role table
    db.query user {
      join = {
        user_tenant_role: {
          table: "user_tenant_role"
          where: $db.user.id == $db.user_tenant_role.user_id
        }
        role            : {
          table: "role"
          type : "left"
          where: $db.user_tenant_role.id == $db.role.id
        }
      }
    
      where = $db.user_tenant_role.tenant_id == $ctx_tenant.self.message.tenant_id
      eval = {role_id: $db.user_tenant_role.role_id}
      return = {type: "list"}
      addon = [{name: "role", input: {role_id: ""}, as: "_role"}]
    } as $users
  }

  response = $users
  tags = ["users"]
}