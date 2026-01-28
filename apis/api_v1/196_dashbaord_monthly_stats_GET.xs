query "dashbaord/monthly_stats" verb=GET {
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
  
    var $start_date {
      value = "now"|transform_timestamp:"-12 months"
    }
  
    db.query order {
      where = $db.order.tenant_id == $current_tenant && $db.order.placed_at >= $start_date
      eval = {
        placed_at         : $db.order.placed_at
        fulfillment_status: $db.order.fulfillment_status
      }
    
      return = {type: "list"}
    } as $orders
  
    var $stats_map {
      value = {}
    }
  
    var $month_keys {
      value = []
    }
  
    for (12) {
      each as $i {
        var $months_ago {
          value = 11 - $i
        }
      
        var $ts {
          value = "now"
            |transform_timestamp:"-" ~ $months_ago ~ " months"
        }
      
        var $key {
          value = $ts|format_timestamp:"Y-m"
        }
      
        array.push $month_keys {
          value = $key
        }
      
        var.update $stats_map {
          value = $stats_map
            |set:$key:```
              {
                month: $key,
                start_date: $ts,
                placed_orders: 0,
                fulfilled_orders: 0
              }
              ```
        }
      }
    }
  
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
          
            var.update $entry {
              value = $entry
                |set:"placed_orders":$entry.placed_orders + 1
            }
          
            conditional {
              if ($order.fulfillment_status == "fulfilled") {
                var.update $entry {
                  value = $entry
                    |set:"fulfilled_orders":$entry.fulfilled_orders + 1
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
  
    var $labels {
      value = []
    }
  
    var $placed_data {
      value = []
    }
  
    var $fulfilled_data {
      value = []
    }
  
    foreach ($month_keys) {
      each as $key {
        var $entry {
          value = $stats_map|get:$key
        }
      
        array.push $labels {
          value = $entry.start_date|format_timestamp:"M Y"
        }
      
        array.push $placed_data {
          value = $entry.placed_orders
        }
      
        array.push $fulfilled_data {
          value = $entry.fulfilled_orders
        }
      }
    }
  
    var $datasets {
      value = [
        {
          label: "Placed Orders",
          backgroundColor: "rgb(255, 99, 132)",
          data: $placed_data
        },
        {
          label: "Fulfilled Orders",
          backgroundColor: "rgb(54, 162, 235)",
          data: $fulfilled_data
        }
      ]
    }
  
    var $chart_response {
      value = {labels: $labels, datasets: $datasets}
    }
  }

  response = $chart_response
}