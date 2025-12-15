// Query all shopify_product records
query shopify_product verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $cxt_tenant
  
    db.query shopify_product {
      return = {type: "list"}
    } as $shopify_product
  }

  response = $shopify_product
}