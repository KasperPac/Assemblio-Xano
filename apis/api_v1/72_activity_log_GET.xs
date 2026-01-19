// Query all activity_log records
query activity_log verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    int page?
    object filters? {
      schema {
        text search? filters=trim
        int user?
      }
    }
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query activity_log {
      where = $db.activity_log.tenant_id == $ctx_tenant.self.message.tenant_id && ($db.activity_log.message includes? $input.filters.search || $db.activity_log.user_id ==? $input.filters.user)
      additional_where = $input.search
      return = {
        type  : "list"
        paging: {page: $input.page, per_page: 100, totals: true}
      }
    
      addon = [
        {
          name : "user"
          input: {user_id: $output.user_id}
          as   : "items._user"
        }
      ]
    } as $activity_log
  }

  response = $activity_log
}