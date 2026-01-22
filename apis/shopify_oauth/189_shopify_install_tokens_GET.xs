// Query all shopify_install_tokens records
query shopify_install_tokens verb=GET {
  api_group = "shopify_Oauth"

  input {
  }

  stack {
    db.query shopify_install_tokens {
      return = {type: "list"}
    } as $shopify_install_tokens
  }

  response = $shopify_install_tokens
}