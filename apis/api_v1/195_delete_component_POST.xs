query "delete/component" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    int id?
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.edit component {
      field_name = "id"
      field_value = $input.id
      data = {is_active: false, deleted: true, deleted_at: now}
    } as $component
  
    var $response {
      value = $component
    }
  }

  response = ""
}