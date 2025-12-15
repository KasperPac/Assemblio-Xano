// Query all shopify_variant records
query shopify_variant verb=GET {
  api_group = "api_v1"

  input {
  }

  stack {
    db.query shopify_variant {
      return = {type: "list"}
    } as $shopify_variant
  }

  response = $shopify_variant
}