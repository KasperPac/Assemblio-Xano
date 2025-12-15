// Add shopify_variant record
query shopify_variant verb=POST {
  api_group = "api_v1"

  input {
    dblink {
      table = "shopify_variant"
    }
  }

  stack {
    db.add shopify_variant {
      data = {created_at: "now"}
    } as $shopify_variant
  }

  response = $shopify_variant
}