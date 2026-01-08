// Creates a new Purchase Order with status RECEIVED and updates inventory immediately.
query "purchase_orders/create_received" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    text po_number filters=trim
    text supplier_name? filters=trim
    text notes? filters=trim
    object[] components {
      schema {
        int component_id {
          table = "component"
        }
      
        decimal quantity
        int location_id? {
          table = "location"
        }
      }
    }
  
    date? order_date?
    date? delivery_date?
    file? delivery_docket?
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // Simplified tenant_id extraction. Assuming resolve_tenant returns the tenant record.
    var $tenant_id {
      value = $ctx_tenant.self.message.tenant_id
    }
  
    precondition (($input.po_number|strlen) > 0) {
      error_type = "inputerror"
      error = "PO Number is required."
    }
  
    precondition (($input.components|count) > 0) {
      error_type = "inputerror"
      error = "At least one component is required."
    }
  
    array.map ($input.components) {
      by = $this.component_id
    } as $comp_ids
  
    var.update $comp_ids {
      value = $comp_ids|unique
    }
  
    db.query component {
      where = $db.component.id in $comp_ids && $db.component.tenant_id == $tenant_id
      return = {type: "list"}
    } as $valid_components
  
    precondition (($valid_components|count) == ($comp_ids|count)) {
      error_type = "inputerror"
      error = "One or more components are invalid or do not belong to your tenant."
    }
  
    // Create an indexed object for O(1) lookups: { "id_string": component_object }
    // This ensures robust lookup regardless of integer/string type differences
    array.map ($valid_components) {
      by = {key: $this.id|to_text, value: $this}
    } as $component_map_entries
  
    var $indexed_components {
      value = $component_map_entries|create_object_from_entries
    }
  
    storage.create_attachment {
      value = $input.delivery_docket
      access = "public"
      filename = ""
    } as $delivery_docket
  
    db.add purchase_order {
      data = {
        created_at     : "now"
        updated_at     : "now"
        tenant         : $tenant_id
        created_by_user: $auth.id
        po_number      : $input.po_number
        status         : "RECEIVED"
        supplier_name  : $input.supplier_name
        notes          : $input.notes
        order_date     : $input.order_date
        delivery_date  : $input.delivery_date
      }
    } as $po
  
    var $po_lines {
      value = []
    }
  
    foreach ($input.components) {
      each as $item {
        // Direct lookup using the indexed object. 
        // Casting to text ensures the key matches the object key format.
        var $comp {
          value = $indexed_components|get:($item.component_id|to_text)
        }
      
        var $target_location_id {
          value = $item.location_id != null ? $item.location_id : $comp.default_location_id
        }
      
        db.add purchase_order_line {
          data = {
            created_at       : "now"
            updated_at       : "now"
            tenant           : $tenant_id
            purchase_order   : $po.id
            component        : $item.component_id
            quantity_ordered : $item.quantity
            quantity_received: $item.quantity
            location         : $target_location_id
          }
        } as $line
      
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
                created_at     : "now"
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
            reason_code       : "PO_CREATE"
            note              : "Stock received via PO " ~ $input.po_number
          }
        }
      
        db.get location {
          field_name = "id"
          field_value = $target_location_id
        } as $loc
      
        // Explicitly construct the component details object to avoid filter argument errors
        var $comp_details {
          value = {
            sku            : $comp.sku
            name           : $comp.name
            unit_of_measure: $comp.unit_of_measure
          }
        }
      
        var $line_response {
          value = $line
        }
      
        var.update $line_response {
          value = $line_response|set:"component":$comp_details
        }
      
        var.update $line_response {
          value = $line_response|set:"location_name":$loc.name
        }
      
        array.push $po_lines {
          value = $line_response
        }
      }
    }
  
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
  
    var $response_data {
      value = $po
    }
  
    var.update $response_data {
      value = $response_data|set:"lines":$po_lines
    }
  }

  response = $response_data
}