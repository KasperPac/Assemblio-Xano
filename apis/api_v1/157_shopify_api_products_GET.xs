query "ShopifyAPI/products" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query tenant {
      join = {
        tenant_secrets: {
          table: "tenant_secrets"
          where: $db.tenant.id == $db.tenant_secrets.tenant_id
        }
        shopify_store : {
          table: "shopify_store"
          where: $db.tenant.id == $db.shopify_store.tenant_id
        }
      }
    
      where = $db.tenant.id == $ctx_tenant.self.message.tenant_id
      eval = {
        shopify: $db.tenant_secrets.shopify_token
        domain : $db.shopify_store.shop_domain
      }
    
      return = {type: "list"}
    } as $tenant1
  
    api.request {
      url = ["https://",$tenant1[0].domain,"/admin/api/2025-10/graphql"]|join:""
      method = "POST"
      params = {}
        |set:"query":"{   products(first: 250) {     nodes {       id       title       description       featuredMedia {         id         preview{           image{             url           }         }       }       onlineStorePreviewUrl       options (first: 250) {         id         name                }       variants(first: 250) {         nodes {           id           title           price           sku           selectedOptions {             name             value           }         }       }     }   } }"
      headers = []
        |push:(["X-Shopify-Access-Token:", $tenant1[0].shopify] | join:" ")
        |push:"Content-Type: application/json"
    } as $api1
  }

  response = $api1
}