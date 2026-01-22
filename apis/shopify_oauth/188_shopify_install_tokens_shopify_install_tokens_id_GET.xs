// Get shopify_install_tokens record
query "shopify_install_tokens/{shopify_install_tokens_id}" verb=GET {
  api_group = "shopify_Oauth"

  input {
    int shopify_install_tokens_id? filters=min:1
  }

  stack {
    db.get shopify_install_tokens {
      field_name = "id"
      field_value = $input.shopify_install_tokens_id
    } as $shopify_install_tokens
  
    precondition ($shopify_install_tokens != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $shopify_install_tokens
}