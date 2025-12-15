// Get tenant record
query "tenant/{tenant_id}" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.get tenant {
      field_name = "id"
      field_value = $ctx_tenant.self.message.tenant_id
    } as $tenant
  
    precondition ($tenant != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $tenant
}