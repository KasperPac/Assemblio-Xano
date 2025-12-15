// Edit shopify_variant record
query "shopify_variant/{shopify_variant_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int shopify_variant_id? filters=min:1
    dblink {
      table = "shopify_variant"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch shopify_variant {
      field_name = "id"
      field_value = $input.shopify_variant_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $shopify_variant
  }

  response = $shopify_variant
}