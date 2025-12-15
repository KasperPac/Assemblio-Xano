// Get inventory_movement record
query "inventory_movement/{component_id}" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    int component_id? filters=min:1
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tennant
  
    db.query inventory_movement {
      where = $db.inventory_movement.tenant_id == $ctx_tennant.self.message.tenant_id && $db.inventory_movement.component_id == $input.component_id
      return = {type: "list"}
      addon = [
        {
          name  : "user"
          output: ["id", "created_at", "name", "full_name"]
          input : {user_id: $auth.id}
          as    : "_user"
        }
      ]
    } as $inventory_movement1
  }

  response = $inventory_movement1
}