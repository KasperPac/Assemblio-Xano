query "products/{shopify_product_id}" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    text shopify_product_id? filters=trim
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query shopify_product {
      join = {
        shopify_variant: {
          table: "shopify_variant"
          where: $db.shopify_product.id == $db.shopify_variant.shopify_product_id
        }
        product_bom    : {
          table: "product_bom"
          type : "left"
          where: $db.product_bom.tenant_id == $ctx_tenant.self.message.tenant_id && $db.product_bom.shopify_variant_id == $db.shopify_variant.id
        }
      }
    
      where = $db.shopify_product.tenant_id == $ctx_tenant.self.message.tenant_id && $db.shopify_product.shopify_product_id == $input.shopify_product_id
      return = {type: "list"}
      addon = [
        {
          name : "shopify_variant_by_product"
          input: {
            tenant_id         : $ctx_tenant.self.message.tenant_id
            shopify_product_id: $output.id
          }
          addon: [
            {
              name : "product_bom_of_shopify_variant"
              input: {shopify_variant_id: $output.id}
              as   : "has_bom"
            }
          ]
          as   : "variant"
        }
      ]
    } as $output_product
  }

  response = $output_product
  tags = ["products"]
}