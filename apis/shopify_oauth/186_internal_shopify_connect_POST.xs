// Connects a Shopify store to a tenant using a secure install token
query "internal/shopify/connect" verb=POST {
  api_group = "shopify_Oauth"

  input {
    // The Shopify store domain
    text shop_domain filters=trim
  
    // The OAuth access token
    text access_token filters=trim
  
    // The scopes granted to the app
    text scopes filters=trim
  
    // The installation token for validation
    text install_token filters=trim
  }

  stack {
    // Validate the shared secret header for internal security
    precondition ($http_headers["x-assemblio-internal-key"] == $env.ASSEMBLIO_INTERNAL_KEY) {
      error_type = "accessdenied"
      error = "Unauthorized: Invalid or missing X-Assemblio-Internal-Key"
    }
  
    // Query the shopify_install_tokens table to find a row where the install_token matches the input
    db.query shopify_install_tokens {
      where = $db.shopify_install_tokens.install_token == $input.install_token && $db.shopify_install_tokens.expires_at > now && $db.shopify_install_tokens.used_at == null
      return = {type: "single"}
    } as $valid_token
  
    // If no such token is found, throw an accessdenied error
    conditional {
      if ($valid_token == null) {
        throw {
          name = "accessdenied"
          value = "Invalid or expired install token"
        }
      }
    }
  
    // Store the tenant_id from the validated install_token record into a variable
    var $tenant_id {
      value = $valid_token.tenant_id
    }
  
    // Match existing records by tenant_id OR shop_domain to determine if we update or add
    db.query shopify_connections {
      where = $db.shopify_connections.tenant_id == $tenant_id || $db.shopify_connections.shop_domain == $input.shop_domain
      return = {type: "single"}
    } as $existing_connection
  
    conditional {
      if ($existing_connection) {
        // Update existing record
        db.edit shopify_connections {
          field_name = "id"
          field_value = $existing_connection.id
          data = {
            access_token: $input.access_token
            scopes      : $input.scopes
            status      : "active"
            updated_at  : "now"
            tenant_id   : $tenant_id
            shop_domain : $input.shop_domain
          }
        }
      }
    
      else {
        // Insert new record
        db.add shopify_connections {
          data = {
            tenant_id   : $tenant_id
            shop_domain : $input.shop_domain
            access_token: $input.access_token
            scopes      : $input.scopes
            status      : "active"
            installed_at: "now"
            updated_at  : "now"
          }
        }
      }
    }
  
    // Update the shopify_install_tokens record
    db.edit shopify_install_tokens {
      field_name = "id"
      field_value = $valid_token.id
      data = {used_at: "now"}
    }
  }

  response = {ok: true, tenant_id: $tenant_id}
}