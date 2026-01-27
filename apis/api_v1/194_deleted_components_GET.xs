query "deleted/components" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query component {
      where = $db.component.tenant_id == $ctx_tenant.self.message.tenant_id && $db.component.deleted
      return = {type: "list"}
    } as $response
  }

  response = $var.response
}