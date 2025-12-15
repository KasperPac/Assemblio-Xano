// Query all activity_log records
query activity_log verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query activity_log {
      where = $db.activity_log.tenant_id == $ctx_tenant.self.message.tenant_id
      return = {type: "list"}
      addon = [
        {
          name : "user"
          input: {user_id: $output.user_id}
          as   : "_user"
        }
      ]
    } as $activity_log
  }

  response = $activity_log
}