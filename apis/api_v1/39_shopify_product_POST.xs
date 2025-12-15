// Add shopify_product record
query shopify_product verb=POST {
  api_group = "api_v1"

  input {
    dblink {
      table = "shopify_product"
    }
  }

  stack {
    db.add shopify_product {
      data = {created_at: "now"}
    } as $shopify_product
  }

  response = $shopify_product
}