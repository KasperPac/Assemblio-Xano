// Get shopify_variant record
query "shopify_variant/{shopify_variant_id}" verb=GET {
  api_group = "api_v1"

  input {
    int shopify_variant_id? filters=min:1
  }

  stack {
    db.get shopify_variant {
      field_name = "id"
      field_value = $input.shopify_variant_id
    } as $shopify_variant
  
    precondition ($shopify_variant != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $shopify_variant
}