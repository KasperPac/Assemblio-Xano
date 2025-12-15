query products verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    text search? filters=trim
    bool has_bom?
    text status? filters=trim
    int limit?
    int offset?
    int page?
  }

  stack {
    conditional {
      if ($input.status == "all") {
        var $status_1 {
          value = ""
        }
      }
    
      else {
        var $status_1 {
          value = $input.status
        }
      }
    }
  
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
          where: $db.product_bom.shopify_variant_id == $db.shopify_variant.id
        }
      }
    
      where = $db.shopify_product.status ==? $status_1 && ($db.shopify_variant.title includes? $input.search || $db.shopify_variant.sku includes? $input.search || $db.shopify_product.title includes? $input.search) && $db.shopify_product.tenant_id == $ctx_tenant.self.message.tenant_id
      return = {
        type  : "list"
        paging: {
          page    : $input.page
          per_page: $input.limit
          totals  : true
          offset  : $input.offset
        }
      }
    
      addon = [
        {
          name : "shopify_variant_by_product"
          input: {
            tenant_id         : $output.tenant_id
            shopify_product_id: $output.id
          }
          addon: [
            {
              name : "has_active_bom"
              input: {shopify_variant_id: $output.id}
              as   : "has_active_bom"
            }
          ]
          as   : "items.variant"
        }
      ]
    } as $products_result
  }

  response = $products_result
  tags = ["products"]
}