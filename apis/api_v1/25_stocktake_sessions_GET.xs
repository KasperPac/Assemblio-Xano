// Retrieves a paginated list of stocktake sessions filtered by status, location, and date range.
query stocktake_sessions verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    // Filter by the status of the stocktake session
    text status?
  
    // Filter by the location ID
    int location_id?
  
    // Filter for sessions started after this date
    timestamp date_from?
  
    // Filter for sessions started before this date
    timestamp date_to?
  
    // The number of items to return per page
    int limit?=25 filters=min:1
  
    // The number of items to skip
    int offset? filters=min:0
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query stocktake_session {
      join = {
        location: {
          table: "location"
          type : "left"
          where: $db.stocktake_session.location_id == $db.location.id
        }
      }
    
      where = $db.stocktake_session.tenant_id == $ctx_tenant.self.message.tenant_id && $db.stocktake_session.status ==? $input.status && $db.stocktake_session.location_id ==? $input.location_id && $db.stocktake_session.started_at >=? $input.date_from && $db.stocktake_session.started_at <=? $input.date_to
      sort = {stocktake_session.started_at: "desc"}
      eval = {location_name: $db.location.name}
      return = {
        type  : "list"
        paging: {page: $page, per_page: $input.limit}
      }
    } as $stocktake_sessions
  }

  response = $stocktake_sessions
}