// Add shopify_store record
query shopify_store verb=POST {
  api_group = "api_v1"

  input {
    dblink {
      table = "shopify_store"
    }
  }

  stack {
    db.add shopify_store {
      data = {created_at: "now"}
    } as $shopify_store
  }

  response = $shopify_store
}