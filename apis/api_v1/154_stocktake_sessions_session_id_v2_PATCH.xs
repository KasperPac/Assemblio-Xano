query "stocktake-sessions/{session_id}/v2" verb=PATCH {
  api_group = "api_v1"
  auth = "user"

  input {
    int session_id
    int line_id?
    text status? filters=trim
    text note? filters=trim
    decimal counted_qty?
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.get stocktake_session {
      field_name = "id"
      field_value = $input.session_id
    } as $stocktake_session
  
    precondition ($stocktake_session != null && $stocktake_session.tenant_id == $ctx_tenant.self.message.tenant_id) {
      error_type = "accessdenied"
      error = "Stocktake session not found or access denied."
    }
  
    precondition ($stocktake_session.status != "APPROVED") {
      error_type = "inputerror"
      error = "Cannot modify a stocktake session that has already been approved."
    }
  
    var $updated_line {
      value = null
    }
  
    conditional {
      if ($input.line_id != null) {
        db.get stocktake_line {
          field_name = "id"
          field_value = $input.line_id
        } as $stocktake_line
      
        precondition ($stocktake_line != null && $stocktake_line.stocktake_session_id == $stocktake_session.id && $stocktake_line.tenant_id == $ctx_tenant.self.message.tenant_id) {
          error_type = "inputerror"
          error = "Stocktake line not found or does not belong to this session."
        }
      
        !var $qty_key {
          value = $input.line_id|to_text
        }
      
        !var $extracted_qty {
          value = $input.counted_qty|get:$qty_key
        }
      
        var $extracted_qty {
          value = $input.counted_qty
        }
      
        var $final_counted_qty {
          value = ($extracted_qty != null ? $extracted_qty : $stocktake_line.counted_qty)
        }
      
        var $variance_qty {
          value = $final_counted_qty - $stocktake_line.expected_qty
        }
      
        db.edit stocktake_line {
          field_name = "id"
          field_value = $stocktake_line.id
          data = {
            counted_qty : $final_counted_qty
            variance_qty: $variance_qty
            status      : "ADJUSTED"
            note        : ($input.note != null ? $input.note : $stocktake_line.note)
            updated_at  : now
          }
        } as $updated_line
      }
    
      elseif ($input.status != null) {
        db.edit stocktake_session {
          field_name = "id"
          field_value = $stocktake_session.id
          data = {status: $input.status, updated_at: "now"}
        }
      }
    }
  }

  response = {session: $stocktake_session, line: $updated_line}
}