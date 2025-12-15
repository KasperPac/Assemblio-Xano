query "product-boms/{bom_id}" verb=PATCH {
  api_group = "api_v1"
  auth = "user"

  input {
    text bom_id? filters=trim
    text notes? filters=trim
    bool is_active?
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // Load Product BOM
    db.query product_bom {
      where = $db.product_bom.tenant_id == $ctx_tenant.self.message.tenant_id && $db.product_bom.id == $input.bom_id
      return = {type: "single"}
    } as $bom
  
    precondition ($bom != null) {
      error_type = "notfound"
      payload = "BOM Not Found"
    }
  
    db.edit product_bom {
      field_name = "id"
      field_value = $bom.id
      data = {is_active: $input.is_active, notes: $input.notes}
    } as $Updated_BOM
  
    db.add activity_log {
      data = {
        created_at : "now"
        tenant_id  : $ctx_tenant.self.message.tenant_id
        user_id    : $auth.id
        event_type : "BoM Updated"
        entity_type: "BoM"
        entity_id  : 0
        message    : [Shopify variant,$bom.shopify_variant_id,BoM version,$bom.version,modified]|join:" "
        RawData    : $bom
      }
    } as $activity_log2
  
    conditional {
      if ($Updated_BOM.is_active) {
        db.query product_bom {
          where = $Updated_BOM.shopify_variant_id == $db.product_bom.shopify_variant_id && $db.product_bom.tenant_id == $ctx_tenant.self.message.tenant_id
          return = {type: "list"}
        } as $product_bom1
      
        foreach ($product_bom1) {
          each as $item {
            conditional {
              if ($item.id != $bom.id) {
                db.edit product_bom {
                  field_name = "id"
                  field_value = $item.id
                  data = {is_active: false}
                } as $product_bom2
              
                db.add activity_log {
                  data = {
                    created_at : "now"
                    tenant_id  : $ctx_tenant.self.message.tenant_id
                    user_id    : $auth.id
                    event_type : "BoM Deactivated"
                    entity_type: "BoM"
                    entity_id  : 0
                    message    : ```
                      
                      [Shopify variant,$var.product_bom2.shopify_variant_id,BoM version,$bom.version,deactivated]|join:" "
                      ```
                    RawData    : $product_bom2
                  }
                } as $activity_log1
              }
            }
          }
        }
      }
    }
  }

  response = $ctx_tenant
  tags = ["bom"]
}