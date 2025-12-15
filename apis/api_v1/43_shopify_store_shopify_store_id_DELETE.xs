// Delete shopify_store record.
query "shopify_store/{shopify_store_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int shopify_store_id? filters=min:1
  }

  stack {
    db.del shopify_store {
      field_name = "id"
      field_value = $input.shopify_store_id
    }
  }

  response = null
}