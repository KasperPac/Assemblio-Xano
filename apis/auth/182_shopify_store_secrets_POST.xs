// Add shopify_store_secrets record
query shopify_store_secrets verb=POST {
  api_group = "auth"

  input {
    dblink {
      table = "shopify_store_secrets"
    }
  }

  stack {
    db.add shopify_store_secrets {
      data = {created_at: "now"}
    } as $shopify_store_secrets
  }

  response = $shopify_store_secrets
}