// Add shopify_install_tokens record
query shopify_install_tokens verb=POST {
  api_group = "shopify_Oauth"

  input {
    dblink {
      table = "shopify_install_tokens"
    }
  }

  stack {
    db.add shopify_install_tokens {
      data = {created_at: "now"}
    } as $shopify_install_tokens
  }

  response = $shopify_install_tokens
}