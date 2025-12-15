// Retrieves a report of component usage within a date range
query "reports/component_usage" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    // Optional component ID to filter by
    int component_id?
  
    // Pagination limit
    int limit?=20
  
    // Pagination offset
    int offset?
  
    text date_from_text? filters=trim
    text date_to_text? filters=trim
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    var $date_from {
      value = $input.date_from_text|to_timestamp:"UTC"
    }
  
    var $date_to {
      value = $input.date_to_text|to_timestamp:"UTC"
    }
  
    db.query inventory_movement {
      where = $db.inventory_movement.tenant_id == $ctx_tenant.self.message.tenant_id && $db.inventory_movement.created_at >= $date_from && $db.inventory_movement.created_at <= $date_to && ($db.inventory_movement.movement_type == "allocation" || $db.inventory_movement.movement_type == "fullfilment") && $db.inventory_movement.component_id ==? $input.component_id
      return = {type: "list"}
    } as $movements
  
    array.group_by ($movements) {
      by = $this.component_id
    } as $grouped_movements
  
    object.entries {
      value = $grouped_movements
    } as $grouped_entries
  
    var $report_data {
      value = []
    }
  
    foreach ($grouped_entries) {
      each as $entry {
        var $component_id {
          value = $entry.key
        }
      
        var $component_movements {
          value = $entry.value
        }
      
        // Map the quantity_delta from each movement
        array.map ($component_movements) {
          by = $this.quantity_delta
        } as $quantity_deltas
      
        // Calculate the total used quantity
        var $total_used {
          value = $quantity_deltas|sum|abs
        }
      
        db.get component {
          field_name = "id"
          field_value = $component_id|to_int
        } as $component
      
        array.push $report_data {
          value = {
            component_id       : $component.id
            sku                : $component.sku
            name               : $component.name
            total_quantity_used: $total_used
          }
        }
      }
    }
  
    var $paginated_report {
      value = $report_data|slice:$input.offset:$input.limit
    }
  }

  response = $paginated_report
}