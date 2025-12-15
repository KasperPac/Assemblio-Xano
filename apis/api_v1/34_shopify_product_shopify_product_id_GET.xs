// Get shopify_product record
query "shopify_product/{shopify_product_id}" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    int shopify_product_id? filters=min:1
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $cxt_tenant
  
    db.query shopify_product {
      where = $db.shopify_product.tenant_id == $cxt_tenant.self.message.tenant_id && $db.shopify_product.shopify_product_id == $input.shopify_product_id
      return = {type: "list"}
    } as $shopify_product1
  
    precondition ($shopify_product1 != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $shopify_product1
}