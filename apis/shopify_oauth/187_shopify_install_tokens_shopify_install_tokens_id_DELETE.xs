// Delete shopify_install_tokens record.
query "shopify_install_tokens/{shopify_install_tokens_id}" verb=DELETE {
  api_group = "shopify_Oauth"

  input {
    int shopify_install_tokens_id? filters=min:1
  }

  stack {
    db.del shopify_install_tokens {
      field_name = "id"
      field_value = $input.shopify_install_tokens_id
    }
  }

  response = null
}