// Query all shopify_store_secrets records
query shopify_store_secrets verb=GET {
  api_group = "auth"

  input {
  }

  stack {
    db.query shopify_store_secrets {
      return = {type: "list"}
    } as $shopify_store_secrets
  }

  response = $shopify_store_secrets
}