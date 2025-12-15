// Get shopify_store record
query "shopify_store/{shopify_store_id}" verb=GET {
  api_group = "api_v1"

  input {
    int shopify_store_id? filters=min:1
  }

  stack {
    db.get shopify_store {
      field_name = "id"
      field_value = $input.shopify_store_id
    } as $shopify_store
  
    precondition ($shopify_store != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $shopify_store
}