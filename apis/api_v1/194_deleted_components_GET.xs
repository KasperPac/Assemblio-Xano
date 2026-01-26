query "deleted/components" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
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
    
      where = $db.product_bom.tenant_id == $ctx_tenant.self.message.tenant_id && $db.product_bom.deleted
      eval = {
        sku  : $db.shopify_variant.sku
        title: $db.shopify_variant.title
      }
    
      return = {type: "list"}
    } as $response
  }

  response = $var.response
}