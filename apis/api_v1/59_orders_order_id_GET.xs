query "orders/{order_id}" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    int order_id
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // 2. Get Order
    db.query order {
      where = $db.order.tenant_id == $ctx_tenant.self.message.tenant_id && $db.order.id == $input.order_id
      return = {type: "single"}
    } as $order
  
    precondition ($order) {
      error_type = "notfound"
      error = "Order not found."
    }
  
    // 3. Get Order Lines
    db.query order_line {
      join = {
        shopify_variant: {
          table: "shopify_variant"
          type : "left"
          where: $db.order_line.shopify_variant_id == $db.shopify_variant.id
        }
        shopify_product: {
          table: "shopify_product"
          where: $db.shopify_variant.shopify_product_id == $db.shopify_product.id
        }
      }
    
      where = $db.order_line.order_id == $order.id
      eval = {
        image_url  : $db.shopify_product.iamge_url
        var_sku    : $db.shopify_variant.sku
        line_price : $db.shopify_variant.price
        product_url: $db.shopify_product.iamge_url
      }
    
      return = {type: "list"}
      addon = [
        {
          name : "order_component_allocation_of_order_line"
          input: {order_line_id: $output.id}
          addon: [
            {
              name : "component"
              input: {component_id: $output.component_id}
              as   : "_component"
            }
          ]
          as   : "_order_component_allocation_of_order_line"
        }
      ]
    } as $order_lines
  
    // Extract Line IDs for the IN clause
    var $line_ids {
      value = []
    }
  
    foreach ($order_lines) {
      each as $line {
        array.push $line_ids {
          value = $line.id
        }
      }
    }
  
    // 4. Get Allocations with Joins (Simpler & Faster)
    var $allocations {
      value = []
    }
  
    conditional {
      if (($line_ids|count) > 0) {
        db.query order_component_allocation {
          join = {
            component: {
              table: "component"
              where: $db.order_component_allocation.component_id == $db.component.id
            }
            location : {
              table: "location"
              where: $db.order_component_allocation.location_id == $db.location.id
            }
          }
        
          where = $db.order_component_allocation.order_line_id in $line_ids
          eval = {
            component_sku : $db.component.sku
            component_name: $db.component.name
            location_name : $db.location.name
          }
        
          return = {type: "list"}
        } as $allocations
      }
    }
  
    // 5. Merge Allocations into Lines
    var $lines_with_allocations {
      value = []
    }
  
    foreach ($order_lines) {
      each as $line {
        var $this_allocations {
          value = $allocations
            |filter:$$.order_line_id == $line.id
        }
      
        var $line_item_cost {
          value = 0
        }
      
        // Calculate cost using the nested addon data from Step 3
        foreach ($line._order_component_allocation_of_order_line) {
          each as $nested_alloc {
            var $qty_req {
              value = $nested_alloc.quantity_required
            }
          
            var $comp_obj {
              value = $nested_alloc._component
            }
          
            conditional {
              if ($comp_obj|is_array) {
                var.update $comp_obj {
                  value = $comp_obj|first
                }
              }
            }
          
            var $cost_unit {
              value = $comp_obj.cost_per_unit
            }
          
            var.update $qty_req {
              value = $qty_req|first_notnull:0|to_decimal
            }
          
            var.update $cost_unit {
              value = $cost_unit|first_notnull:0|to_decimal
            }
          
            var.update $line_item_cost {
              value = $line_item_cost + ($qty_req * $cost_unit)
            }
          }
        }
      
        array.push $lines_with_allocations {
          value = $line
            |set:"component_allocations":$this_allocations
            |set:"line_item_cost":$line_item_cost
        }
      }
    }
  
    // 6. Final Response
    var $response_payload {
      value = $order
        |set:"lines":$lines_with_allocations
    }
  }

  response = $response_payload
}