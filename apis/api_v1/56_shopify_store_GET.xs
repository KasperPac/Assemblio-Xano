// Query all shopify_store records
query shopify_store verb=GET {
  api_group = "api_v1"

  input {
  }

  stack {
    db.query shopify_store {
      return = {type: "list"}
    } as $shopify_store
  }

  response = $shopify_store
}