// Initialize a stocktake session
query "stocktake/create_session" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    // Name of the stocktake session
    text name
  
    // ID of the location to stocktake
    int location_id
  
    // Optional filters for selecting components
    json filters?
  
    text status? filters=trim
    date? date_from?
  }

  stack {
    // Resolve Tenant ID for the authenticated user
    db.query user_tenant_role {
      where = $db.user_tenant_role.user_id == $auth.id
      return = {type: "single"}
    } as $user_role
  
    precondition ($user_role != null) {
      error_type = "accessdenied"
      error = "User is not associated with any tenant."
    }
  
    var $tenant_id {
      value = $user_role.tenant_id
    }
  
    // Verify Location belongs to Tenant
    db.get location {
      field_name = "id"
      field_value = $input.location_id
    } as $location
  
    precondition ($location != null && $location.tenant_id == $tenant_id) {
      error_type = "inputerror"
      error = "Invalid location or location does not belong to your tenant."
    }
  
    // Create Stocktake Session
    db.add stocktake_session {
      data = {
        created_at        : "now"
        tenant_id         : $tenant_id
        location_id       : $input.location_id
        name              : $input.name
        status            : "NEW"
        started_at        : "now"
        created_by_user_id: $auth.id
        date_from         : $input.date_from
      }
    } as $new_session
  
    // Retrieve Inventory Balance
    db.query inventory_balance {
      join = {
        component: {
          table: "component"
          where: $db.inventory_balance.component_id == $db.component.id
        }
      }
    
      where = $db.inventory_balance.tenant_id == $tenant_id && $db.inventory_balance.location_id == $input.location_id
      return = {type: "list"}
    } as $inventory_items
  
    // Create Stocktake Lines
    foreach ($inventory_items) {
      each as $item {
        db.add stocktake_line {
          data = {
            created_at          : "now"
            stocktake_session_id: $new_session.id
            tenant_id           : $tenant_id
            component_id        : $item.component_id
            expected_qty        : $item.on_hand_qty
            counted_qty         : null
            variance_qty        : null
            status              : "PENDING"
            note                : ""
            updated_at          : ""
          }
        } as $line
      }
    }
  
    // Retrieve Paginated Lines for Response
    db.query stocktake_line {
      where = $db.stocktake_line.stocktake_session_id == $new_session.id
      return = {type: "list", paging: {page: 1, per_page: 25}}
    } as $session_lines
  }

  response = {session: $new_session, lines: $session_lines}
}