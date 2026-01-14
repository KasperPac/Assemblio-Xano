// Handles Shopify order cancellation webhooks by releasing allocated stock and updating order status.
query "shopify/webhooks/orders_cancel" verb=POST {
  api_group = "api_v1"

  input {
    // The Shopify Order ID from the webhook payload
    int id
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $payload
  
    db.query order {
      where = $db.order.shopify_order_id == $input.id
      return = {type: "single"}
    } as $existing_order
  
    conditional {
      if ($existing_order) {
        db.edit order {
          field_name = "id"
          field_value = $existing_order.id
          data = {status_internal: "cancelled", updated_at: "now"}
        }
      
        db.query order_component_allocation {
          join = {
            order_line: {
              table: "order_line"
              where: $db.order_component_allocation.order_line_id == $db.order_line.id
            }
          }
        
          where = $db.order_line.order_id == $existing_order.id
          return = {type: "list"}
        } as $allocations
      
        foreach ($allocations) {
          each as $allocation {
            db.query inventory_balance {
              where = $db.inventory_balance.component_id == $allocation.component_id && $db.inventory_balance.location_id == $allocation.location_id
              return = {type: "single"}
            } as $balance
          
            conditional {
              if ($balance) {
                db.edit inventory_balance {
                  field_name = "id"
                  field_value = $balance.id
                  data = {
                    on_hand_qty    : $balance.on_hand_qty + $allocation.quantity_allocated
                    in_progress_qty: $balance.in_progress_qty - $allocation.quantity_allocated
                    updated_at     : "now"
                  }
                } as $updated_balance
              
                db.add inventory_movement {
                  data = {
                    tenant_id         : $existing_order.tenant_id
                    component_id      : $allocation.component_id
                    location_id       : $allocation.location_id
                    movement_type     : "adjustment"
                    quantity_delta    : $allocation.quantity_allocated
                    quantity_after    : $updated_balance.on_hand_qty
                    reference_type    : "order"
                    reference_id      : $existing_order.id
                    reason_code       : "ORDER_CANCELLED"
                    note              : "Stock returned from cancelled order"
                    created_by_user_id: null
                    created_at        : "now"
                  }
                }
              }
            }
          
            db.del order_component_allocation {
              field_name = "id"
              field_value = $allocation.id
            }
          }
        }
      
        db.add activity_log {
          data = {
            tenant_id  : $existing_order.tenant_id
            event_type : "ORDER_CANCELLED"
            entity_type: "order"
            entity_id  : $existing_order.id
            message    : "Order cancellation processed successfully"
            created_at : "now"
          }
        }
      
        var $message {
          value = "Order cancellation processed successfully"
        }
      }
    
      else {
        var $message {
          value = "Order not found"
        }
      }
    }
  }

  response = {message: $message}
}