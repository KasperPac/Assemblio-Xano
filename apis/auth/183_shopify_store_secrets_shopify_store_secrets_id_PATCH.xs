// Edit shopify_store_secrets record
query "shopify_store_secrets/{shopify_store_secrets_id}" verb=PATCH {
  api_group = "auth"

  input {
    int shopify_store_secrets_id? filters=min:1
    dblink {
      table = "shopify_store_secrets"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch shopify_store_secrets {
      field_name = "id"
      field_value = $input.shopify_store_secrets_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $shopify_store_secrets
  }

  response = $shopify_store_secrets
}