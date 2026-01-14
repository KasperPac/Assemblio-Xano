query "shopify/webhooks/orders_create_update" verb=POST {
  api_group = "api_v1"

  input {
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $order_raw
  
    !var $headers {
      value = $env.$http_headers|json_decode
    }
  
    var $shop_domain {
      value = $env.$http_headers.X-Shopify-Shop-Domain
    }
  
    !var $shop_domain {
      value = "dibble-foods.myshopify.com"
    }
  
    conditional {
      if ($shop_domain == null) {
        var.update $shop_domain {
          value = $headers["X-Shopify-Shop-Domain"]
        }
      }
    }
  
    db.query shopify_store {
      where = $db.shopify_store.shop_domain == $shop_domain
      return = {type: "single"}
    } as $store
  
    conditional {
      if ($store == null) {
        throw {
          name = "AccessDenied"
          value = "Shop domain not registered"
        }
      }
    }
  
    var $tenant_id {
      value = $store.tenant_id
    }
  
    var $shopify_store_id {
      value = $store.id
    }
  
    var $shopify_order_id {
      value = $order_raw.id
    }
  
    var $order_number {
      value = $order_raw.order_number
    }
  
    var $placed_at {
      value = $order_raw.created_at|to_timestamp
    }
  
    var $financial_status {
      value = $order_raw.financial_status
    }
  
    var $fulfillment_status {
      value = $order_raw.fulfillment_status
    }
  
    var $currency {
      value = $order_raw.currency
    }
  
    var $total_price {
      value = $order_raw.subtotal_price
    }
  
    var $customer_name {
      value = [$order_raw.customer.first_name,$order_raw.customer.last_name]|join:" "
    }
  
    var $customer_email {
      value = $order_raw.customer.email
    }
  
    var $customer_phone {
      value = $order_raw.customer.phone
    }
  
    var $customer_address1 {
      value = [$order_raw.billing_address.address1,$order_raw.billing_address.city,$order_raw.billing_address.province,$order_raw.billing_address.country,$order_raw.billing_address.zip]|join:", "
    }
  
    conditional {
      if ($order_raw.customer != null) {
      }
    
      elseif ($order_raw.billing_address != null) {
        var.update $customer_name {
          value = $order_raw.billing_address.name
        }
      }
    }
  
    db.query order {
      where = $db.order.shopify_order_id == $shopify_order_id && $db.order.tenant_id == $tenant_id
      return = {type: "single"}
    } as $existing_order
  
    conditional {
      if ($existing_order != null) {
        db.edit order {
          field_name = "id"
          field_value = $existing_order.id
          data = {
            order_number      : $order_number
            placed_at         : $placed_at
            financial_status  : $financial_status
            fulfillment_status: $fulfillment_status
            customer_name     : $customer_name
            currency          : $currency
            total_price       : $total_price
            updated_at        : "now"
            customer_email    : $customer_email
            customer_phone    : $customer_phone
            customer_address  : $customer_address1
          }
        } as $order_record
      }
    
      else {
        db.add order {
          data = {
            created_at        : "now"
            tenant_id         : $tenant_id
            shopify_store_id  : $shopify_store_id
            shopify_order_id  : $shopify_order_id
            order_number      : $order_number
            placed_at         : $placed_at
            financial_status  : $financial_status
            fulfillment_status: $fulfillment_status
            customer_name     : $customer_name
            currency          : $currency
            total_price       : $total_price
            status_internal   : "new"
            updated_at        : "now"
            customer_email    : $customer_email
            customer_phone    : $customer_phone
            customer_address  : $customer_address1
          }
        } as $order_record
      }
    }
  
    // Step 7: Initialize Allocation Arrays
    var $missing_boms {
      value = []
    }
  
    var $missing_inventory_balances {
      value = []
    }
  
    var $allocation_outcomes {
      value = []
    }
  
    foreach ($order_raw.line_items) {
      each as $line_item {
        db.query shopify_variant {
          where = $db.shopify_variant.shopify_variant_id == $line_item.variant_id && $db.shopify_variant.tenant_id == $tenant_id
          return = {type: "single"}
        } as $variant
      
        var $variant_id_resolved {
          value = null
        }
      
        conditional {
          if ($variant != null) {
            var.update $variant_id_resolved {
              value = $variant.id
            }
          }
        }
      
        db.query order_line {
          where = $db.order_line.shopify_line_item_id == $line_item.id
          return = {type: "single"}
        } as $existing_line
      
        var $current_order_line_id {
          value = null
        }
      
        conditional {
          if ($existing_line != null) {
            db.edit order_line {
              field_name = "id"
              field_value = $existing_line.id
              data = {
                quantity_ordered  : $line_item.quantity
                title             : $line_item.title
                variant_title     : $line_item.variant_title
                shopify_variant_id: $variant_id_resolved
                line_price        : $line_item.price
                updated_at        : "now"
              }
            }
          
            var.update $current_order_line_id {
              value = $existing_line.id
            }
          }
        
          else {
            db.add order_line {
              data = {
                order_id            : $order_record.id
                shopify_line_item_id: $line_item.id
                shopify_variant_id  : $variant_id_resolved
                quantity_ordered    : $line_item.quantity
                quantity_fulfilled  : 0
                title               : $line_item.title
                variant_title       : $line_item.variant_title
                line_price          : $line_item.price
                created_at          : "now"
                updated_at          : "now"
              }
            } as $new_line
          
            var.update $current_order_line_id {
              value = $new_line.id
            }
          }
        }
      
        // Step 12: Find Active BOM for Variant
        db.query product_bom {
          where = $db.product_bom.shopify_variant_id == $variant_id_resolved && $db.product_bom.tenant_id == $tenant_id && $db.product_bom.is_active
          return = {type: "single"}
        } as $active_bom
      
        conditional {
          if ($active_bom == null) {
            array.push $missing_boms {
              value = {
                line_item_title   : $line_item.title
                shopify_variant_id: $line_item.variant_id
                reason            : "No active BOM found"
              }
            }
          }
        
          else {
            // Step 13: Process BOM Components
            db.query product_bom_component {
              where = $db.product_bom_component.product_bom_id == $active_bom.id
              return = {type: "list"}
            } as $bom_components
          
            foreach ($bom_components) {
              each as $bom_component {
                var $quantity_required {
                  value = $line_item.quantity * $bom_component.quantity_per_unit
                }
              
                // Step 14: Determine Allocation Location
                db.get component {
                  field_name = "id"
                  field_value = $bom_component.component_id
                } as $component_details
              
                var $allocation_location_id {
                  value = $component_details.default_location_id
                }
              
                conditional {
                  if ($allocation_location_id == null || $allocation_location_id == 0) {
                    db.query location {
                      where = $db.location.tenant_id == $tenant_id && $db.location.is_default
                      return = {type: "single"}
                    } as $tenant_default_location
                  
                    conditional {
                      if ($tenant_default_location != null) {
                        var.update $allocation_location_id {
                          value = $tenant_default_location.id
                        }
                      }
                    }
                  }
                }
              
                // Step 15: Get/Create Inventory Balance
                var $inventory_balance {
                  value = null
                }
              
                conditional {
                  if ($allocation_location_id != null) {
                    db.query inventory_balance {
                      where = $db.inventory_balance.component_id == $bom_component.component_id && $db.inventory_balance.location_id == $allocation_location_id && $db.inventory_balance.tenant_id == $tenant_id
                      return = {type: "single"}
                    } as $existing_balance
                  
                    conditional {
                      if ($existing_balance == null) {
                        db.add inventory_balance {
                          data = {
                            tenant_id      : $tenant_id
                            component_id   : $bom_component.component_id
                            location_id    : $allocation_location_id
                            on_hand_qty    : 0
                            in_progress_qty: 0
                            shipped_qty    : 0
                            created_at     : "now"
                            updated_at     : "now"
                          }
                        } as $inventory_balance
                      }
                    
                      else {
                        var.update $inventory_balance {
                          value = $existing_balance
                        }
                      }
                    }
                  }
                
                  else {
                    array.push $missing_inventory_balances {
                      value = {
                        line_item_title: $line_item.title
                        component_id   : $bom_component.component_id
                        reason         : "No allocation location determined"
                      }
                    }
                  }
                }
              
                // Step 16: Calculate Allocatable Quantity
                var $quantity_to_allocate {
                  value = 0
                }
              
                conditional {
                  if ($inventory_balance != null) {
                    // Allow stock levels to go below 0 by allocating the full required amount
                    var.update $quantity_to_allocate {
                      value = $quantity_required
                    }
                  
                    // Step 17: Update Inventory Balance
                    db.edit inventory_balance {
                      field_name = "id"
                      field_value = $inventory_balance.id
                      data = {
                        on_hand_qty    : $inventory_balance.on_hand_qty - $quantity_to_allocate
                        in_progress_qty: $inventory_balance.in_progress_qty + $quantity_to_allocate
                        updated_at     : "now"
                      }
                    } as $updated_inventory_balance
                  
                    // Step 18: Record Inventory Movement
                    db.add inventory_movement {
                      data = {
                        tenant_id     : $tenant_id
                        component_id  : $bom_component.component_id
                        location_id   : $allocation_location_id
                        movement_type : "allocation"
                        quantity_delta: 0 - $quantity_to_allocate
                        quantity_after: $updated_inventory_balance.on_hand_qty
                        reference_type: "order"
                        reference_id  : $order_record.id
                        reason_code   : "shopify_order"
                        note          : "Allocated for Shopify Order " ~ $order_number
                        created_at    : "now"
                      }
                    }
                  }
                }
              
                // Step 19: Upsert Order Component Allocation
                conditional {
                  if ($allocation_location_id != null) {
                    db.query order_component_allocation {
                      where = $db.order_component_allocation.order_line_id == $current_order_line_id && $db.order_component_allocation.component_id == $bom_component.component_id
                      return = {type: "single"}
                    } as $existing_allocation
                  
                    conditional {
                      if ($existing_allocation != null) {
                        db.edit order_component_allocation {
                          field_name = "id"
                          field_value = $existing_allocation.id
                          data = {
                            quantity_required : $quantity_required
                            quantity_allocated: $quantity_to_allocate
                            updated_at        : "now"
                          }
                        }
                      }
                    
                      else {
                        db.add order_component_allocation {
                          data = {
                            tenant_id         : $tenant_id
                            order_line_id     : $current_order_line_id
                            component_id      : $bom_component.component_id
                            location_id       : $allocation_location_id
                            quantity_required : $quantity_required
                            quantity_allocated: $quantity_to_allocate
                            quantity_consumed : 0
                            created_at        : "now"
                            updated_at        : "now"
                          }
                        }
                      }
                    }
                  }
                }
              
                // Step 20: Track Allocation Outcomes
                array.push $allocation_outcomes {
                  value = {
                    line_item_title   : $line_item.title
                    component_sku     : $component_details.sku
                    quantity_required : $quantity_required
                    quantity_allocated: $quantity_to_allocate
                    is_fully_allocated: $quantity_to_allocate >= $quantity_required
                  }
                }
              }
            }
          }
        }
      }
    }
  
    // Step 21: Final Order Status Update
    var $final_internal_status {
      value = "allocated"
    }
  
    conditional {
      if (($missing_boms|count) > 0 || ($missing_inventory_balances|count) > 0) {
        var.update $final_internal_status {
          value = "BOM_MISSING"
        }
      }
    
      else {
        // Check for any incomplete allocations
        var $incomplete_allocations {
          value = $allocation_outcomes
            |filter:($this.is_fully_allocated == false)
        }
      
        conditional {
          if (($incomplete_allocations|count) > 0) {
            var.update $final_internal_status {
              value = "partially_allocated"
            }
          }
        }
      }
    }
  
    db.edit order {
      field_name = "id"
      field_value = $order_record.id
      data = {
        status_internal: $final_internal_status
        updated_at     : "now"
      }
    }
  
    // Step 22: Return Success Response
    var $response_payload {
      value = {
        success: true
        message: "Order processed successfully"
        data   : {
          order_id: $order_record.id
          status: $final_internal_status
          allocation_stats: {
             processed: ($allocation_outcomes|count)
             missing_boms: ($missing_boms|count)
             missing_balances: ($missing_inventory_balances|count)
          }
          warnings: {
             boms: $missing_boms
             inventory: $missing_inventory_balances
          }
        }
      }
    }
  
    db.add activity_log {
      data = {
        created_at : "now"
        tenant_id  : $tenant_id
        event_type : "New Order"
        entity_type: "Order"
        entity_id  : $response_payload.data.order_id
        message    : ["New Order",$new_line.order_id,"Imported from Shopify"]|join:" "
        RawData    : `$input`
      }
    } as $activity_log1
  }

  response = $response_payload
}