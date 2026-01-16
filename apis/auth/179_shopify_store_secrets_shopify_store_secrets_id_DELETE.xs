// Delete shopify_store_secrets record.
query "shopify_store_secrets/{shopify_store_secrets_id}" verb=DELETE {
  api_group = "auth"

  input {
    int shopify_store_secrets_id? filters=min:1
  }

  stack {
    db.del shopify_store_secrets {
      field_name = "id"
      field_value = $input.shopify_store_secrets_id
    }
  }

  response = null
}