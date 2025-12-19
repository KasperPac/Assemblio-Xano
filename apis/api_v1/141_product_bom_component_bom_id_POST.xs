// Add product_bom_component record
query "product_bom_component/{bom_id}" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    dblink {
      table = "product_bom_component"
    }
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query product_bom_component {
      where = $db.product_bom_component.product_bom_id == $input.product_bom_id
      return = {type: "list"}
    } as $product_bom_component1
  
    precondition ($ctx_tenant != null) {
      error_type = "notfound"
      error = "BOM not found"
    }
  
    precondition ($product_bom_component1.component_id != $input.component_id) {
      error_type = "badrequest"
      error = "Component already exists in BoM"
    }
  
    db.add product_bom_component {
      data = {
        created_at       : "now"
        product_bom_id   : $input.product_bom_id
        component_id     : $input.component_id
        quantity_per_unit: $input.quantity_per_unit
        updated_at       : now
      }
    } as $product_bom_component
  
    db.add activity_log {
      data = {
        created_at : "now"
        tenant_id  : $ctx_tenant.self.message.tenant_id
        user_id    : $auth.id
        event_type : "Product BoM"
        entity_type: "BoM"
        entity_id  : 0
        message    : [Component,$product_bom_component.component_id,quantity,$input.quantity_per_unit,added to BoM,$product_bom_component.product_bom_id]|join:" "
        RawData    : $product_bom_component
      }
    } as $activity_log1
  }

  response = $product_bom_component
}