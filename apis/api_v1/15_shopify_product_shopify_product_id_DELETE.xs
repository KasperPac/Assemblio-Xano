// Delete shopify_product record.
query "shopify_product/{shopify_product_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int shopify_product_id? filters=min:1
  }

  stack {
    db.del shopify_product {
      field_name = "id"
      field_value = $input.shopify_product_id
    }
  }

  response = null
}