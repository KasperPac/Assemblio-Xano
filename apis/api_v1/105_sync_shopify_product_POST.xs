query sync_shopify_product verb=POST {
  api_group = "api_v1"

  input {
    text id
    text title
    text handle
    text status
    json products_json
    text image_url? filters=trim
  }

  stack {
    // Upsert the parent product record first to get its internal ID
    db.add_or_edit shopify_product {
      field_name = "shopify_product_id"
      field_value = $input.id
      data = {
        created_at      : now
        tenant_id       : 3
        shopify_store_id: 2
        title           : $input.title
        handle          : $input.handle
        status          : $input.status
        iamge_url       : $input.image_url
        updated_at      : now
      }
    } as $upserted_product
  
    var $variants_array {
      value = $input.products_json
    }
  
    var $new_variants {
      value = []
    }
  
    foreach ($variants_array) {
      each as $variant_item {
        // Check if the variant already exists
        db.has shopify_variant {
          field_name = "shopify_variant_id"
          field_value = $variant_item.id
        } as $variant_exists
      
        // Upsert the variant, linking it to the parent product's internal ID
        db.add_or_edit shopify_variant {
          field_name = "shopify_variant_id"
          field_value = $variant_item.id
          data = {
            created_at        : now
            tenant_id         : $upserted_product.tenant_id
            shopify_product_id: $upserted_product.id
            sku               : $variant_item.sku
            title             : $variant_item.title
            price             : $variant_item.price
            updated_at        : now
          }
        } as $processed_variant
      
        conditional {
          if ($variant_exists == false) {
            array.push $new_variants {
              value = $processed_variant
            }
          }
        }
      }
    }
  
    conditional {
      if (($new_variants|count) == 0) {
        var $response_output {
          value = "No New Products"
        }
      }
    
      else {
        var $response_output {
          value = $new_variants
        }
      }
    }
  }

  response = $response_output
}