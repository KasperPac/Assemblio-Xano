// Syncs products and variants from Shopify Store
query "products/shopify/import" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    // The internal ID of the Shopify store to sync
    int store_id {
      table = "shopify_store"
    }
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // Retrieve the store and secrets. Using 'single' to ensure we get a scalar object for headers.
    db.query tenant {
      join = {
        shopify_store : {
          table: "shopify_store"
          where: $db.tenant.id == $db.shopify_store.tenant_id
        }
        tenant_secrets: {
          table: "tenant_secrets"
          where: $db.tenant.id == $db.tenant_secrets.tenant_id
        }
      }
    
      where = $db.tenant.id == $ctx_tenant.self.message.tenant_id
      eval = {
        shop_domain : $db.shopify_store.shop_domain
        access_token: $db.tenant_secrets.shopify_token
        store_id    : $db.shopify_store.id
      }
    
      return = {type: "single"}
    } as $store
  
    // GraphQL Query to fetch products and variants
    var $graphql_query {
      value = "{ products(first: 250) { nodes { id title description featuredMedia { preview { image { url } } } onlineStorePreviewUrl options(first: 250) { id name } variants(first: 250) { nodes { id title price sku selectedOptions { name value } } } } } }"
    }
  
    // Fetch products from Shopify Admin API using GraphQL
    api.request {
      url = "https://" ~ $store.shop_domain ~ "/admin/api/2025-10/graphql.json"
      method = "POST"
      params = {query: $graphql_query}
      headers = []
        |push:"X-Shopify-Access-Token: " ~ $store.access_token
        |push:"Content-Type: application/json"
    } as $shopify_api_response
  
    // Extract the list of products from the GraphQL response
    var $shopify_products {
      value = $shopify_api_response.response.result.data.products.nodes
    }
  
    // Iterate through each product returned by Shopify
    foreach ($shopify_products) {
      each as $current_product {
        // Extract the numeric ID from the GraphQL GID (gid://shopify/Product/12345)
        var $shopify_product_id {
          value = $current_product.id
            |split:"/"
            |last
            |to_int
        }
      
        // Safely extract image URL
        var $image_url {
          value = $current_product.featuredMedia.preview.image.url
        }
      
        // Check if the product already exists in the local database
        db.get shopify_product {
          field_name = "shopify_product_id"
          field_value = $shopify_product_id
        } as $existing_product
      
        // Update existing product or create a new one
        conditional {
          if ($existing_product != null) {
            db.edit shopify_product {
              field_name = "id"
              field_value = $existing_product.id
              data = {
                tenant_id         : $ctx_tenant.self.message.tenant_id
                shopify_store_id  : $store.store_id
                shopify_product_id: $shopify_product_id
                title             : $current_product.title
                iamge_url         : $image_url
              }
            } as $product_record
          }
        
          else {
            db.add shopify_product {
              data = {
                created_at        : "now"
                tenant_id         : $ctx_tenant.self.message.tenant_id
                shopify_store_id  : $store.store_id
                shopify_product_id: $shopify_product_id
                title             : $current_product.title
                status            : ""
                iamge_url         : $image_url
                updated_at        : ""
              }
            } as $product_record
          }
        }
      
        // Iterate through the variants of the current product
        foreach ($current_product.variants.nodes) {
          each as $current_variant {
            // Extract the numeric ID from the GraphQL GID
            var $shopify_variant_id {
              value = $current_variant.id
                |split:"/"
                |last
                |to_int
            }
          
            // Check if the variant already exists in the local database
            db.get shopify_variant {
              field_name = "shopify_variant_id"
              field_value = $shopify_variant_id
            } as $existing_variant
          
            // Update existing variant or create a new one
            conditional {
              if ($existing_variant != null) {
                db.edit shopify_variant {
                  field_name = "id"
                  field_value = $existing_variant.id
                  data = {
                    tenant_id         : $ctx_tenant.self.message.tenant_id
                    shopify_product_id: $product_record.id
                    shopify_variant_id: $shopify_variant_id
                    sku               : $current_variant.sku
                    title             : $current_variant.title
                    price             : $current_variant.price
                  }
                } as $variant_record
              }
            
              else {
                db.add shopify_variant {
                  data = {
                    created_at        : "now"
                    tenant_id         : $ctx_tenant.self.message.tenant_id
                    shopify_product_id: $product_record.id
                    shopify_variant_id: $shopify_variant_id
                    sku               : $current_variant.sku
                    title             : $current_variant.title
                    price             : $current_variant.price
                    updated_at        : ""
                  }
                } as $variant_record
              }
            }
          }
        }
      }
    }
  }

  response = {
    status      : "success"
    synced_count: $shopify_products|count
  }
}