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
  
    // New Metric: Product Sales Last Month
    var $last_month_start {
      value = "now"|transform_timestamp:"-1 months"
    }
  
    db.query order_line {
      join = {
        order: {
          table: "order"
          where: $db.order_line.order_id == $db.order.id
        }
      }
    
      where = $db.order.tenant_id == $current_tenant && $db.order.placed_at >= $last_month_start
      eval = {
        title   : $db.order_line.title
        quantity: $db.order_line.quantity_ordered
      }
    
      return = {type: "list"}
    } as $sold_products
  
    // Group by title to handle aggregation safely without dot notation issues
    array.group_by ($sold_products) {
      by = $this.title
    } as $grouped_sales
  
    var $sales_entries {
      value = $grouped_sales|entries
    }
  
    var $product_stats_list {
      value = []
    }
  
    foreach ($sales_entries) {
      each as $entry {
        var $p_name {
          value = $entry.key
        }
      
        // Handle potential null/empty keys
        conditional {
          if ($p_name == "null" || $p_name == "") {
            var.update $p_name {
              value = "Unknown Product"
            }
          }
        }
      
        // Extract quantities using array.map statement to ensure $this scope
        array.map ($entry.value) {
          by = $this.quantity
        } as $product_quantities
      
        // Sum the quantities for this product
        var $total_qty {
          value = $product_quantities|sum
        }
      
        array.push $product_stats_list {
          value = {name: $p_name, qty: $total_qty}
        }
      }
    }
  
    // Sort by quantity descending and slice top 5
    var $top_products {
      value = $product_stats_list
        |sort:"qty":"decimal":false
        |slice:0:5
    }
  
    var $product_labels {
      value = []
    }
  
    var $product_sales_datasets {
      value = []
    }
  
    foreach ($top_products) {
      each as $prod {
        array.push $product_labels {
          value = $prod.name
        }
      
        array.push $product_sales_datasets {
          value = {
            label          : $prod.name
            backgroundColor: "rgb(255, 99, 132)"
            data           : [
                  $prod.qty
                ]
          }
        }
      }
    }
  
    var.update $chart_data {
      value = $chart_data
        |set:"product_sales_data":$product_sales_datasets
        |set:"product_labels":$product_labels
    }
  }

  response = $chart_data
}