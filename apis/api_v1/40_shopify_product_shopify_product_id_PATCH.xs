// Edit shopify_product record
query "shopify_product/{shopify_product_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int shopify_product_id? filters=min:1
    dblink {
      table = "shopify_product"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch shopify_product {
      field_name = "id"
      field_value = $input.shopify_product_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $shopify_product
  }

  response = $shopify_product
}