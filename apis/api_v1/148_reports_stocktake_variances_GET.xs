// Retrieves a list of completed stocktake sessions, including variance details, with optional date and pagination filters.
query "reports/stocktake-variances" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    // The start date for filtering stocktake sessions by their completion date.
    timestamp date_from?
  
    // The end date for filtering stocktake sessions by their completion date.
    timestamp date_to?
  
    // The maximum number of stocktake sessions to return per page.
    int limit?=20 filters=min:1
  
    // The number of records to skip for pagination purposes.
    int offset? filters=min:0
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // Retrieve completed stocktake sessions, filtering by tenant ID and optional date range, and joining with location details.
    db.query stocktake_session {
      join = {
        location: {
          table: "location"
          type : "left"
          where: $db.stocktake_session.location_id == $db.location.id
        }
      }
    
      where = $db.stocktake_session.tenant_id == $ctx_tenant.self.message.tenant_id && $db.stocktake_session.status == "COMPLETED" && $db.stocktake_session.completed_at >=? $input.date_from && $db.stocktake_session.completed_at <=? $input.date_to
      return = {
        type  : "list"
        paging: {page: $page, per_page: $input.limit}
      }
    
      addon = [
        {
          name : "location_1"
          input: {location_id: $output.location_id}
          as   : "items._location_1"
        }
      ]
    } as $sessions
  
    // Initialize an empty list to store stocktake sessions with calculated variance data.
    var $enriched_items {
      value = []
    }
  
    // Iterate through each retrieved stocktake session to calculate and add variance totals.
    foreach ($sessions.items) {
      each as $session {
        // Fetch all individual stocktake lines associated with the current session.
        db.query stocktake_line {
          where = $db.stocktake_line.stocktake_session_id == $session.id
          return = {type: "list"}
        } as $lines
      
        // Calculate the sum of all positive variance quantities for the current session.
        var $pos {
          value = $lines
            |filter:$$.variance_qty > 0
            |map:$$.variance_qty
            |sum
        }
      
        // Calculate the sum of all negative variance quantities for the current session.
        var $neg {
          value = $lines
            |filter:$$.variance_qty < 0
            |map:$$.variance_qty
            |sum
        }
      
        // Calculate the sum of all absolute variance quantities for the current session.
        var $abs {
          value = $lines|map:($$.variance_qty|abs)|sum
        }
      
        // Add the calculated total positive, negative, and absolute variances, along with the location name, to the current session object.
        var.update $session {
          value = $session
            |set:"total_positive_variance":($pos|first_notnull:0)
            |set:"total_negative_variance":($neg|first_notnull:0)
            |set:"total_absolute_variance":($abs|first_notnull:0)
            |set:"location_name":$session._location_1.name
        }
      
        // Add the enriched stocktake session data to the list of enriched items.
        array.push $enriched_items {
          value = $session
        }
      }
    }
  
    // Replace the original list of sessions with the newly enriched list, including variance totals and location names.
    var.update $sessions {
      value = $sessions|set:"items":$enriched_items
    }
  }

  response = $sessions
}