// Copies an active BOM from one variant to another
query "products/bom/copy" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    // The Shopify Variant ID (internal or external) of the source BOM
    int copy_variant
  
    // The Shopify Variant ID (internal or external) to assign the new BOM to
    int shopify_variant
  }

  stack {
    !var $tenant_id {
      value = $auth.account_id
    }
  
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    var $tenant_id {
      value = $ctx_tenant.self.message.tenant_id
    }
  
    db.query product_bom {
      where = $db.product_bom.shopify_variant_id == $input.copy_variant && $db.product_bom.is_active && $db.product_bom.tenant_id == $tenant_id
      return = {type: "single"}
    } as $source_bom
  
    precondition ($source_bom != null) {
      error_type = "inputerror"
      error = "Active source BOM not found for the provided variant."
    }
  
    db.add product_bom {
      data = {
        tenant_id         : $tenant_id
        shopify_variant_id: $input.shopify_variant
        version           : 1
        is_active         : $source_bom.is_active
        notes             : $source_bom.notes
        created_by_user_id: $auth.id
      }
    } as $new_bom
  
    db.query product_bom_component {
      where = $db.product_bom_component.product_bom_id == $source_bom.id
      return = {type: "list"}
    } as $source_components
  
    foreach ($source_components) {
      each as $component {
        db.add product_bom_component {
          data = {
            product_bom_id   : $new_bom.id
            component_id     : $component.component_id
            quantity_per_unit: $component.quantity_per_unit
            sort_order       : $component.sort_order
          }
        }
      }
    }
  
    db.add activity_log {
      data = {
        created_at : "now"
        tenant_id  : $ctx_tenant.self.message.tenant_id
        user_id    : $auth.id
        event_type : "BoM Coppied"
        entity_type: "BoM"
        entity_id  : $new_bom.id
        message    : [$var.source_bom.shopify_variant_id,"Coppied to",$var.new_bom.shopify_variant_id]|join:" "
        RawData    : [$var.source_bom]|append:$var.new_bom
      }
    } as $activity_log1
  }

  response = {
    message   : "BOM copied successfully"
    new_bom_id: $new_bom.id
  }
}