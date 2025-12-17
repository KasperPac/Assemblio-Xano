query component verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    // Unique identifier for the component
    text sku filters=trim|lower
  
    // Name of the component
    text name filters=trim
  
    // Description of the component
    text description? filters=trim
  
    // Unit of measure for the component (e.g., 'pcs', 'kg')
    text unit_of_measure filters=trim
  
    // Default location ID for inventory; must belong to the tenant
    int default_location_id?
  
    // Minimum stock level to trigger a reorder
    decimal reorder_point? filters=min:0
  
    // Preferred supplier for this component
    text preferred_supplier? filters=trim
  
    int? cost_per_item?
    bool no_depreciate?
    bool modify?
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // 2) Validate sku is unique for tenant.
    db.query component {
      where = $db.component.tenant_id == $ctx_tenant.self.message.tenant_id && ($db.component.sku|to_upper) == ($input.sku|to_upper)
      return = {type: "single"}
    } as $existing_component
  
    conditional {
      if ($input.modify == false) {
        precondition ($existing_component == null) {
          error_type = "badrequest"
          error = "SKU already exists"
        }
      }
    }
  
    !precondition ($existing_component == null) {
      error_type = "inputerror"
      error = "SKU already exists for this tenant."
    }
  
    // 3) Validate default_location_id belongs to tenant if provided.
    conditional {
      if ($input.default_location_id != null) {
        db.get location {
          field_name = "id"
          field_value = $input.default_location_id
        } as $default_location
      
        precondition ($default_location != null && $default_location.tenant_id == $ctx_tenant.self.message.tenant_id) {
          error_type = "inputerror"
          error = "Default location ID is invalid or does not belong to your tenant."
        }
      }
    }
  
    // 4) Insert component row with tenant_id and provided fields; is_active defaults to true.
    db.add component {
      data = {
        created_at         : "now"
        tenant_id          : $ctx_tenant.self.message.tenant_id
        sku                : $input.sku|to_upper
        name               : $input.name
        description        : $input.description
        unit_of_measure    : $input.unit_of_measure
        cost_per_unit      : $input.cost_per_item
        default_location_id: $input.default_location_id
        reorder_point      : $input.reorder_point
        preferred_supplier : $input.preferred_supplier
        is_active          : true
        updated_at         : "now"
      }
    } as $new_component
  
    var $initial_balance {
      value = null
    }
  
    // 5) Optionally create inventory_balance rows with zero quantities for default_location_id.
    conditional {
      if ($input.default_location_id != null) {
        db.add inventory_balance {
          data = {
            created_at     : "now"
            tenant_id      : $ctx_tenant.self.message.tenant_id
            component_id   : $new_component.id
            location_id    : $input.default_location_id
            on_hand_qty    : 0
            in_progress_qty: 0
            shipped_qty    : 0
            updated_at     : "now"
          }
        } as $created_balance
      
        var.update $initial_balance {
          value = $created_balance
        }
      }
    }
  
    // 6) Return created component (and related balances if created).
    var $response_data {
      value = {
        component                : $new_component
        initial_inventory_balance: $initial_balance
      }
    }
  
    db.add activity_log {
      data = {
        created_at : "now"
        tenant_id  : $ctx_tenant.self.message.tenant_id
        user_id    : $auth.id
        event_type : "Component Added"
        entity_type: "COMPONENT"
        entity_id  : $response_data.component.id
        message    : ["Component",$new_component.name,"Added with ID:",$new_component.id]|join:" "
      }
    }
  }

  response = $response_data
}