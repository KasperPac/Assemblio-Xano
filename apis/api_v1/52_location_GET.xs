// Query all location records
query location verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query location {
      where = $db.location.tenant_id == $ctx_tenant.self.message.tenant_id
      return = {type: "list"}
    } as $location
  }

  response = $location
}