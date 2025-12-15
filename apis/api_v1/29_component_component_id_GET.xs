// Get component record
query "component/{component_id}" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    int component_id? filters=min:1
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query component {
      where = $db.component.tenant_id == $ctx_tenant.self.message.tenant_id && $db.component.id == $input.component_id
      return = {type: "single"}
      addon = [
        {
          name : "inventory_balance_of_component"
          input: {component_id: $input.component_id}
          addon: [
            {
              name  : "location"
              output: ["name"]
              input : {location_id: $output.location_id}
              as    : "_location"
            }
          ]
          as   : "_inventory_balance_of_component"
        }
      ]
    } as $component
  
    precondition ($component != null) {
      error_type = "notfound"
      error = "Component Not Found"
    }
  }

  response = $component
}