query "dashboard/monthly_stats" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    var $current_tenant {
      value = $ctx_tenant.self.message.tenant_id
    }
  
    var $now {
      value = "now"
    }
  
    // 1. Monthly Stats Setup
    var $stats_map {
      value = {}
    }
  
    var $graph_labels {
      value = []
    }
  
    var $month_keys {
      value = []
    }
  
    // Generate last 12 months keys (Newest to Oldest)
    for (12) {
      each as $i {
        var $ts {
          value = $now
            |transform_timestamp:"-" ~ $i ~ " months"
        }
      
        var $key {
          value = $ts|format_timestamp:"Y-m"
        }
      
        var $label {
          value = $ts|format_timestamp:"M Y"
        }
      
        array.push $graph_labels {
          value = $label
        }
      
        array.push $month_keys {
          value = $key
        }
      
        var.update $stats_map {
          value = $stats_map
            |set:$key:{placed: 0, fulfilled: 0, cancelled: 0}
        }
      }
    }
  
    // 2. Query Orders
    var $query_start_date {
      value = $now|transform_timestamp:"-12 months"
    }
  
    db.query order {
      where = $db.order.tenant_id == $current_tenant && $db.order.placed_at >= $query_start_date
      eval = {
        placed_at         : $db.order.placed_at
        fulfillment_status: $db.order.fulfillment_status
        status_internal   : $db.order.status_internal
      }
    
      return = {type: "list"}
    } as $orders
  
    // 3. Aggregate Orders
    foreach ($orders) {
      each as $order {
        var $key {
          value = $order.placed_at|format_timestamp:"Y-m"
        }
      
        conditional {
          if ($stats_map|has:$key) {
            var $entry {
              value = $stats_map|get:$key
            }
          
            // Increment Placed
            var.update $entry {
              value = $entry|set:"placed":$entry.placed + 1
            }
          
            // Increment Fulfilled
            conditional {
              if (($order.fulfillment_status|to_lower) == "fulfilled") {
                var.update $entry {
                  value = $entry
                    |set:"fulfilled":$entry.fulfilled + 1
                }
              }
            }
          
            // Increment Cancelled
            conditional {
              if (($order.status_internal|to_lower) == "cancelled") {
                var.update $entry {
                  value = $entry
                    |set:"cancelled":$entry.cancelled + 1
                }
              }
            }
          
            var.update $stats_map {
              value = $stats_map|set:$key:$entry
            }
          }
        }
      }
    }
  
    // 4. Build Graph Data Arrays
    var $data_placed {
      value = []
    }
  
    var $data_fulfilled {
      value = []
    }
  
    var $data_cancelled {
      value = []
    }
  
    foreach ($month_keys) {
      each as $key {
        var $entry {
          value = $stats_map|get:$key
        }
      
        array.push $data_placed {
          value = $entry.placed
        }
      
        array.push $data_fulfilled {
          value = $entry.fulfilled
        }
      
        array.push $data_cancelled {
          value = $entry.cancelled
        }
      }
    }
  
    // 5. Product Sales (Last Month)
    var $one_month_ago {
      value = $now|transform_timestamp:"-1 month"
    }
  
    db.query order_line {
      join = {
        order: {
          table: "order"
          where: $db.order_line.order_id == $db.order.id
        }
      }
    
      where = $db.order.tenant_id == $current_tenant && $db.order.placed_at >= $one_month_ago
      return = {type: "list"}
    } as $recent_lines
  
    var $product_map {
      value = {}
    }
  
    foreach ($recent_lines) {
      each as $line {
        var $p_name {
          value = $line.title
        }
      
        var $qty {
          value = $line.quantity_ordered
        }
      
        conditional {
          if ($product_map|has:$p_name) {
            var.update $product_map {
              value = $product_map
                |set:$p_name:($product_map|get:$p_name + $qty)
            }
          }
        
          else {
            var.update $product_map {
              value = $product_map|set:$p_name:$qty
            }
          }
        }
      }
    }
  
    var $product_labels {
      value = $product_map|keys
    }
  
    var $product_sales_data {
      value = $product_map|values
    }
  
    // 6. Final Response
    var $response {
      value = {
        labels       : $graph_labels
        datasets     : [
          {
            label          : "Placed Orders"
            backgroundColor: "rgb(54, 162, 235)"
            data           : $data_placed
          }
          {
            label          : "Fulfilled Orders"
            backgroundColor: "rgb(75, 192, 192)"
            data           : $data_fulfilled
          }
          {
            label          : "Cancelled Orders"
            backgroundColor: "rgb(255, 99, 132)"
            data           : $data_cancelled
          }
        ]
        product_sales: {
          labels: $product_labels
          data  : $product_sales_data
        }
      }
    }
  }

  response = $response[""]
}