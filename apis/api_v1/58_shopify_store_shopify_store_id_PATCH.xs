// Edit shopify_store record
query "shopify_store/{shopify_store_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int shopify_store_id? filters=min:1
    dblink {
      table = "shopify_store"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch shopify_store {
      field_name = "id"
      field_value = $input.shopify_store_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $shopify_store
  }

  response = $shopify_store
}