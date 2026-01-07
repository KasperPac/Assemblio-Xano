query "component/groups/" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query component_group {
      where = $db.component_group.tenant_id == $ctx_tenant.self.message.tenant_id
      return = {type: "list"}
    } as $component_group
  }

  response = $component_group
}