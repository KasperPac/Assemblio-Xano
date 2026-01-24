query "products/{variant_id}/bom" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    text shopify_variant_id? filters=trim
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query product_bom {
      join = {
        shopify_variant: {
          table: "shopify_variant"
          where: $db.product_bom.shopify_variant_id == $db.shopify_variant.id
        }
      }
    
      where = $db.product_bom.tenant_id == $ctx_tenant.self.message.tenant_id && $db.shopify_variant.shopify_variant_id == $input.shopify_variant_id && $db.product_bom.deleted == false
      return = {type: "list"}
      addon = [
        {
          name : "component_bom_from_product_bom"
          input: {product_bom_id: $output.id}
          addon: [
            {
              name : "component"
              input: {component_id: $output.component_id}
              as   : "_component"
            }
          ]
          as   : "bom_components"
        }
      ]
    } as $output_bom
  }

  response = $output_bom
  tags = ["bom"]
}