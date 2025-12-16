// Creates a new Purchase Order with status RECEIVED and updates inventory immediately.
query "purchase_orders/create_received" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    // The Purchase Order Number
    text po_number filters=trim
  
    // Name of the supplier
    text supplier_name? filters=trim
  
    // Optional notes
    text notes? filters=trim
  
    // List of components to order and receive
    object[1:1] components {
      schema {
        // ID of the component
        int component_id {
          table = "component"
        }
      
        // Quantity ordered and received
        decimal quantity
      
        // Target location ID. Defaults to component default if null.
        int location_id? {
          table = "location"
        }
      }
    }
  }

  stack {
    // Resolve Tenant for the authenticated user
    db.query user_tenant_role {
      where = $db.user_tenant_role.user_id == $auth.id
      return = {type: "single"}
    } as $user_role
  
    precondition ($user_role != null) {
      error_type = "accessdenied"
      error = "User is not associated with a tenant."
    }
  
    var $tenant_id {
      value = $user_role.tenant_id
    }
  
    // Validate Inputs
    precondition (($input.po_number|strlen) > 0) {
      error_type = "inputerror"
      error = "PO Number is required."
    }
  
    precondition (($input.components|count) > 0) {
      error_type = "inputerror"
      error = "At least one component is required."
    }
  
    // Verify Components exist and belong to tenant
    var $comp_ids {
      value = $input.components|map:$this.component_id|unique
    }
  
    db.query component {
      where = $db.component.id in $comp_ids && $db.component.tenant_id == $tenant_id
      return = {type: "list"}
    } as $valid_components
  
    precondition (($valid_components|count) == ($comp_ids|count)) {
      error_type = "inputerror"
      error = "One or more components are invalid or do not belong to your tenant."
    }
  
    // Create Purchase Order
    db.add purchase_order {
      data = {
        tenant         : $tenant_id
        created_by_user: $auth.id
        po_number      : $input.po_number
        status         : "RECEIVED"
        supplier_name  : $input.supplier_name
        notes          : $input.notes
        updated_at     : "now"
      }
    } as $po
  
    var $po_lines {
      value = []
    }
  
    // Process each component line
    foreach ($input.components) {
      each as $item {
        // Find component details from verification result
        var $comp {
          value = $valid_components
            |find:($this.id == $item.component_id)
        }
      
        // Determine Location
        var $target_location_id {
          value = $item.location_id != null ? $item.location_id : $comp.default_location_id
        }
      
        // Create PO Line
        db.add purchase_order_line {
          data = {
            tenant           : $tenant_id
            purchase_order   : $po.id
            component        : $item.component_id
            quantity_ordered : $item.quantity
            quantity_received: $item.quantity
            location         : $target_location_id
            unit_cost        : $comp.cost_per_unit
            updated_at       : "now"
          }
        } as $line
      
        // Update Inventory Balance
        db.query inventory_balance {
          where = $db.inventory_balance.component_id == $item.component_id && $db.inventory_balance.location_id == $target_location_id && $db.inventory_balance.tenant_id == $tenant_id
          return = {type: "single"}
        } as $balance
      
        var $qty_after {
          value = 0
        }
      
        conditional {
          if ($balance) {
            db.edit inventory_balance {
              field_name = "id"
              field_value = $balance.id
              data = {
                on_hand_qty: $balance.on_hand_qty + $item.quantity
                updated_at : "now"
              }
            } as $updated_balance
          
            var.update $qty_after {
              value = $updated_balance.on_hand_qty
            }
          }
        
          else {
            db.add inventory_balance {
              data = {
                tenant_id      : $tenant_id
                component_id   : $item.component_id
                location_id    : $target_location_id
                on_hand_qty    : $item.quantity
                in_progress_qty: 0
                shipped_qty    : 0
                updated_at     : "now"
              }
            } as $new_balance
          
            var.update $qty_after {
              value = $new_balance.on_hand_qty
            }
          }
        }
      
        // Log Inventory Movement
        db.add inventory_movement {
          data = {
            tenant_id         : $tenant_id
            component_id      : $item.component_id
            location_id       : $target_location_id
            movement_type     : "PURCHASE_RECEIPT"
            quantity_delta    : $item.quantity
            quantity_after    : $qty_after
            reference_type    : "purchase_order"
            reference_id      : $po.id
            created_by_user_id: $auth.id
          }
        }
      
        // Get Location Name for Response
        db.get location {
          field_name = "id"
          field_value = $target_location_id
        } as $loc
      
        // Build Line Response
        var $line_response {
          value = $line
        }
      
        var.update $line_response {
          value = $line_response
            |set:"component":($comp
              |pick:["sku", "name", "unit_of_measure"]
            )
        }
      
        var.update $line_response {
          value = $line_response|set:"location_name":$loc.name
        }
      
        array.push $po_lines {
          value = $line_response
        }
      }
    }
  
    // Log Activity
    db.add activity_log {
      data = {
        tenant_id  : $tenant_id
        user_id    : $auth.id
        event_type : "PURCHASE_ORDER_CREATED"
        entity_type: "purchase_order"
        entity_id  : $po.id
        message    : "Created received purchase order " ~ $po.po_number
      }
    }
  
    // Construct Final Response
    var $response_data {
      value = $po
    }
  
    var.update $response_data {
      value = $response_data|set:"lines":$po_lines
    }
  }

  response = $response_data
}