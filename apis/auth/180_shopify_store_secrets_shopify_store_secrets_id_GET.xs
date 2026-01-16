// Get shopify_store_secrets record
query "shopify_store_secrets/{shopify_store_secrets_id}" verb=GET {
  api_group = "auth"

  input {
    int shopify_store_secrets_id? filters=min:1
  }

  stack {
    db.get shopify_store_secrets {
      field_name = "id"
      field_value = $input.shopify_store_secrets_id
    } as $shopify_store_secrets
  
    precondition ($shopify_store_secrets != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $shopify_store_secrets
}