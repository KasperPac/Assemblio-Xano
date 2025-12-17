// Approves a stocktake session, updates inventory balances, records movements, and finalizes the session.
query "stocktake-sessions/{session_id}/approve" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    // The ID of the stocktake session to approve.
    int session_id
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // Fetch stocktake session
    db.get stocktake_session {
      field_name = "id"
      field_value = $input.session_id
    } as $session
  
    // Validate session exists and belongs to tenant
    precondition ($session != null && $session.tenant_id == $ctx_tenant.self.message.tenant_id) {
      error_type = "accessdenied"
      error = "Session not found or access denied."
    }
  
    // Validate session status
    precondition ($session.status != "APPROVED") {
      error_type = "inputerror"
      error = "Session is already approved."
    }
  
    // Fetch stocktake lines with counts
    db.query stocktake_line {
      where = $db.stocktake_line.stocktake_session_id == $input.session_id && $db.stocktake_line.counted_qty != null
      return = {type: "list"}
    } as $lines
  
    var $total_variance {
      value = 0
    }
  
    var $processed_lines {
      value = []
    }
  
    foreach ($lines) {
      each as $line {
        // Compute variance if null
        var $variance {
          value = $line.variance_qty
        }
      
        conditional {
          if ($variance == null) {
            var.update $variance {
              value = $line.counted_qty - $line.expected_qty
            }
          }
        }
      
        // Update total variance
        var.update $total_variance {
          value = $total_variance + $variance
        }
      
        // Find inventory balance
        db.query inventory_balance {
          where = $db.inventory_balance.component_id == $line.component_id && $db.inventory_balance.location_id == $session.location_id && $db.inventory_balance.tenant_id == $ctx_tenant.self.message.tenant_id
          return = {type: "single"}
        } as $balance
      
        // Update or Create Inventory Balance
        conditional {
          if ($balance) {
            db.edit inventory_balance {
              field_name = "id"
              field_value = $balance.id
              data = {on_hand_qty: $line.counted_qty, updated_at: "now"}
            }
          }
        
          else {
            db.add inventory_balance {
              data = {
                tenant_id      : $tenant_id
                component_id   : $line.component_id
                location_id    : $session.location_id
                on_hand_qty    : $line.counted_qty
                in_progress_qty: 0
                shipped_qty    : 0
                created_at     : "now"
                updated_at     : "now"
              }
            }
          }
        }
      
        // Update Stocktake Line
        db.edit stocktake_line {
          field_name = "id"
          field_value = $line.id
          data = {
            status      : "APPROVED"
            variance_qty: $variance
            updated_at  : "now"
          }
        } as $updated_line
      
        array.push $processed_lines {
          value = $updated_line
        }
      
        // Insert Inventory Movement
        db.add inventory_movement {
          data = {
            created_at        : "now"
            tenant_id         : $ctx_tenant.self.message.tenant_id
            component_id      : $line.component_id
            location_id       : $session.location_id
            movement_type     : "STOCKTAKE_ADJUST"
            quantity_delta    : $variance
            quantity_after    : $line.counted_qty
            reference_type    : "STOCKTAKE"
            reference_id      : $input.session_id
            reason_code       : ""
            note              : ""
            created_by_user_id: $auth.id
          }
        }
      }
    }
  
    // Update Session Status
    db.edit stocktake_session {
      field_name = "id"
      field_value = $input.session_id
      data = {
        status      : "COMPLETED"
        completed_at: "now"
        updated_at  : "now"
        APPROVED    : true
        LOCKED      : true
      }
    } as $updated_session
  
    // Construct Response
    var $response {
      value = {
        total_variance: $total_variance
        session       : $updated_session
        lines         : $processed_lines
      }
    }
  }

  response = $response[""]
}