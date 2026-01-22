// Edit shopify_install_tokens record
query "shopify_install_tokens/{shopify_install_tokens_id}" verb=PATCH {
  api_group = "shopify_Oauth"

  input {
    int shopify_install_tokens_id? filters=min:1
    dblink {
      table = "shopify_install_tokens"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch shopify_install_tokens {
      field_name = "id"
      field_value = $input.shopify_install_tokens_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $shopify_install_tokens
  }

  response = $shopify_install_tokens
}