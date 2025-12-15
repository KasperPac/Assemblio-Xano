query "shopify_product/bulk-insert" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    api.request {
      url = "https://pactechnologies.app.n8n.cloud/webhook/import-products"
      method = "POST"
    } as $api1
  }

  response = $ctx_tenant
  tags = ["shopify"]
}