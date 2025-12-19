query "ShopifyAPI/products" verb=GET {
  api_group = "api_v1"

  input {
  }

  stack {
    api.request {
      url = ""
      method = "GET"
    } as $api1
  }

  response = $api1
}