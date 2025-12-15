// Delete shopify_variant record.
query "shopify_variant/{shopify_variant_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int shopify_variant_id? filters=min:1
  }

  stack {
    db.del shopify_variant {
      field_name = "id"
      field_value = $input.shopify_variant_id
    }
  }

  response = null
}