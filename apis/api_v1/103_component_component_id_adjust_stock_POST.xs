query "component/{component_id}/adjust-stock" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    int component_id?
    int location_id?
    int quantity_delta?
    text reason_code? filters=trim
    text note? filters=trim
    text type? filters=trim
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query component {
      where = $db.component.id == $input.component_id && $db.component.tenant_id == $ctx_tenant.self.message.tenant_id
      return = {type: "list"}
    } as $component_record
  
    db.has inventory_balance {
      field_name = "component_id"
      field_value = $input.component_id
    } as $balanceexist
  
    conditional {
      if ($balanceexist) {
      }
    
      else {
        db.add inventory_balance {
          data = {
            created_at     : "now"
            tenant_id      : $ctx_tenant.self.message.tenant_id
            component_id   : $input.component_id
            location_id    : $input.location_id
            on_hand_qty    : 0
            in_progress_qty: 0
            shipped_qty    : 0
            updated_at     : ""
          }
        }
      }
    }
  
    db.query inventory_balance {
      where = $db.inventory_balance.tenant_id == $ctx_tenant.self.message.tenant_id && $db.inventory_balance.component_id == $input.component_id
      return = {type: "list"}
    } as $balance
  
    var $AdjustType {
      value = ""
    }
  
    conditional {
      if ($input.type == "add") {
        math.add $balance[0].on_hand_qty {
          value = $input.quantity_delta
        }
      
        var.update $AdjustType {
          value = `"+" | concat: $input.quantity_delta`
        }
      }
    
      elseif ($input.type == "sub") {
        math.sub $balance[0].on_hand_qty {
          value = $input.quantity_delta
        }
      
        var.update $AdjustType {
          value = `"-" | concat: $input.quantity_delta`
        }
      }
    }
  
    !conditional {
      if ($balance.0.on_hand_qty < 0) {
        var.update $balance[0].on_hand_qty {
          value = 0
        }
      }
    }
  
    db.edit inventory_balance {
      field_name = "id"
      field_value = $balance.0.id
      data = {on_hand_qty: $balance.0.on_hand_qty}
    } as $inventory_balance1
  
    db.add inventory_movement {
      data = {
        created_at        : "now"
        tenant_id         : $ctx_tenant.self.message.tenant_id
        component_id      : $input.component_id
        location_id       : $input.location_id
        movement_type     : "MANUAL ADJUST"
        quantity_delta    : $AdjustType
        quantity_after    : $balance.0.on_hand_qty
        reference_type    : "ADJUST"
        reason_code       : $input.reason_code
        note              : $input.note
        created_by_user_id: $auth.id
      }
    }
  
    db.add activity_log {
      data = {
        created_at : "now"
        tenant_id  : $ctx_tenant.self.message.tenant_id
        user_id    : $auth.id
        event_type : "Stock Adjustment"
        entity_type: "COMONENT"
        entity_id  : 0
        message    : ["Component",$component_record.0.name,"stock levels adjusted by",$input.quantity_delta]|join:" "
        RawData    : [$var.balance]|append:$var.inventory_balance1
      }
    } as $activity_log1
  }

  response = {result1: $component_record, b: $balance}
  tags = ["component"]
}