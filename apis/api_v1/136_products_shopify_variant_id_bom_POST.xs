// Creates a new version of a Bill of Materials (BOM) for a specific product variant, deactivates previous versions, and adds the specified components.
query "products/{shopify_variant_id}/bom" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    // The ID of the Shopify variant
    int shopify_variant_id
  
    // Optional notes for this BOM version
    text notes?
  
    // List of components to include in the BOM
    object[] components? {
      schema {
        // ID of the component
        int component_id
      
        // Quantity of the component required per unit
        decimal quantity_per_unit
      
        // Optional sort order for the component
        int sort_order?
      }
    }
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // Find nested Variant ID
    db.query shopify_variant {
      where = $db.shopify_variant.tenant_id == $ctx_tenant.self.message.tenant_id && $db.shopify_variant.shopify_variant_id == $input.shopify_variant_id
      return = {type: "single"}
      output = ["id", "shopify_product_id", "shopify_variant_id", "sku", "title"]
    } as $nested_variant_id
  
    // Find currently active BOMs for this variant and tenant to deactivate them
    db.query product_bom {
      where = $db.product_bom.tenant_id == $ctx_tenant.self.message.tenant_id && $db.product_bom.shopify_variant_id == $nested_variant_id.id && $db.product_bom.is_active
      return = {type: "list"}
    } as $active_boms
  
    // Iterate through active BOMs and set is_active to false
    foreach ($active_boms) {
      each as $bom {
        db.edit product_bom {
          field_name = "id"
          field_value = $bom.id
          data = {
            tenant_id: $ctx_tenant.self.message.tenant_id
            is_active: false
            notes    : $input.notes
          }
        } as $deactivated_bom
      }
    }
  
    // Fetch the latest BOM version for this variant to determine the new version number
    db.query product_bom {
      where = $db.product_bom.shopify_variant_id == $nested_variant_id.id && $db.product_bom.tenant_id == $ctx_tenant.self.message.tenant_id
      sort = {version: "desc"}
      return = {type: "single"}
    } as $last_bom
  
    // Initialize new version to 1
    var $new_version {
      value = 1
    }
  
    // Increment version if a previous BOM exists
    conditional {
      if ($last_bom) {
        var.update $new_version {
          value = $last_bom.version + 1
        }
      }
    }
  
    // Create the new BOM record
    db.add product_bom {
      data = {
        created_at        : "now"
        tenant_id         : $ctx_tenant.self.message.tenant_id
        shopify_variant_id: $nested_variant_id.id
        version           : $new_version
        is_active         : true
        notes             : $input.notes
        updated_at        : ""
        created_by_user_id: $auth.id
      }
    } as $new_bom
  
    // Initialize array to hold the added components for the response
    var $added_components {
      value = []
    }
  
    // Loop through input components and add them to the database linked to the new BOM
    foreach ($input.components) {
      each as $component {
        db.add product_bom_component {
          data = {
            created_at       : "now"
            product_bom_id   : $new_bom.id
            component_id     : $component.component_id
            quantity_per_unit: $component.quantity_per_unit
            sort_order       : $component.sort_order
            updated_at       : ""
          }
        } as $new_component
      
        array.push $added_components {
          value = $new_component
        }
      }
    }
  
    // Combine the BOM record and components into the response object
    var $response {
      value = $new_bom
        |set:"components":$added_components
    }
  
    db.query shopify_product {
      where = $db.shopify_product.tenant_id == $ctx_tenant.self.message.tenant_id && $db.shopify_product.id == $nested_variant_id.shopify_product_id
      return = {type: "list"}
    } as $shopify_product
  
    db.add activity_log {
      data = {
        created_at : "now"
        tenant_id  : $ctx_tenant.self.message.tenant_id
        user_id    : $auth.id
        event_type : "BoM Created"
        entity_type: "BoM"
        entity_id  : 0
        message    : [Bill of Materials created for variant,$nested_variant_id.sku,$nested_variant_id.title,for product,$shopify_product.0.title,version,$response.version]|join:" "
      }
    } as $activity_log1
  }

  response = $response
}