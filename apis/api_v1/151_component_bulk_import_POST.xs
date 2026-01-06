query "component/bulk-import" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    // CSV file containing component data
    file csv_file?
  
    attachment? csv_file2
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // Retrieve the default location for the tenant
    db.query location {
      where = $db.location.tenant_id == $ctx_tenant.self.message.tenant_id && $db.location.is_default
      return = {type: "single"}
    } as $default_location
  
    precondition ($default_location != null) {
      error_type = "notfound"
      error = "Default location not found for this tenant. Please configure a default location."
    }
  
    // Parse the CSV data directly from the uploaded file
    stream.from_csv {
      value = $input.csv_file
      separator = ","
      enclosure = '"'
      escape_char = '"'
    } as $csv_items
  
    var $imported_components {
      value = []
    }
  
    foreach ($csv_items) {
      each as $row {
        // Check if SKU already exists for this tenant
        db.query component {
          where = $db.component.tenant_id == $ctx_tenant.self.message.tenant_id && ($db.component.sku|to_upper) == ($row.sku|to_upper)
          return = {type: "exists"}
        } as $sku_exists
      
        conditional {
          if ($sku_exists == false) {
            // Insert component row
            db.add component {
              data = {
                created_at         : "now"
                tenant_id          : $ctx_tenant.self.message.tenant_id
                sku                : $row.sku
                name               : $row.name
                description        : $row.description
                unit_of_measure    : $row.unit_of_measure
                cost_per_unit      : $row.cost_per_unit
                default_location_id: $default_location.id
                reorder_point      : $row.reorder_point
                preferred_supplier : $row.preferred_supplier
                is_active          : true
                updated_at         : "now"
              }
            } as $new_component
          
            // Create initial inventory balance for the default location
            db.add inventory_balance {
              data = {
                created_at     : "now"
                tenant_id      : $ctx_tenant.self.message.tenant_id
                component_id   : $new_component.id
                location_id    : $default_location.id
                on_hand_qty    : $row.on_hand
                in_progress_qty: $row.in_progress
                shipped_qty    : 0
                updated_at     : "now"
              }
            }
          
            // Log activity
            db.add activity_log {
              data = {
                created_at : "now"
                tenant_id  : $ctx_tenant.self.message.tenant_id
                user_id    : $auth.id
                event_type : "Component Added"
                entity_type: "COMPONENT"
                entity_id  : $new_component.id
                message    : "Bulk Import: Component " ~ $new_component.name ~ " Added"
              }
            }
          
            array.push $imported_components {
              value = $new_component
            }
          }
        }
      }
    }
  }

  response = $imported_components
}