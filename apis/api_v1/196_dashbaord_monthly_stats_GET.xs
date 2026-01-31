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
        status_internal   : $db.order.status_internal
      }
    
      return = {type: "list"}
    } as $orders
  
    var $stats_map {
      value = {}
    }
  
    var $month_keys {
      value = []
    }
  
    var $labels {
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
      
        var $label {
          value = $ts|format_timestamp:"M Y"
        }
      
        array.push $month_keys {
          value = $key
        }
      
        array.push $labels {
          value = $label
        }
      
        var.update $stats_map {
          value = $stats_map
            |set:$key:```
              {
                placed_orders: 0,
                fulfilled_orders: 0,
                cancelled_orders: 0
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
          
            // Check for fulfillment status
            conditional {
              if ($order.fulfillment_status == "fulfilled") {
                var.update $entry {
                  value = $entry
                    |set:"fulfilled_orders":$entry.fulfilled_orders + 1
                }
              }
            }
          
            // Check for cancellation status
            conditional {
              if ($order.status_internal == "cancelled") {
                var.update $entry {
                  value = $entry
                    |set:"cancelled_orders":$entry.cancelled_orders + 1
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
          value = $entry.placed_orders
        }
      
        array.push $data_fulfilled {
          value = $entry.fulfilled_orders
        }
      
        array.push $data_cancelled {
          value = $entry.cancelled_orders
        }
      }
    }
  
    var $chart_data {
      value = {
        labels  : $labels
        datasets: [
          {
            label: "Placed Orders",
            backgroundColor: "rgb(54, 162, 235)",
            data: $data_placed
          },
          {
            label: "Fulfilled Orders",
            backgroundColor: "rgb(75, 192, 192)",
            data: $data_fulfilled
          },
          {
            label: "Cancelled Orders",
            backgroundColor: "rgb(255, 99, 132)",
            data: $data_cancelled
          }
        ]
      }
    }
  }

  response = $chart_data
}