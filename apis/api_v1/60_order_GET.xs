// Returns a paginated list of orders with internal and Shopify statuses.
query order verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    // Search by order number or customer name
    text search? filters=trim
  
    // Filter by internal status
    text status_internal? filters=trim
  
    // Filter by component status (OK, SHORT)
    text component_status? filters=trim
  
    // Filter by placed_at from
    timestamp date_from?
  
    // Filter by placed_at to
    timestamp date_to?
  
    // Page number
    int page?=1 filters=min:1
  
    // Items per page
    int per_page?=20 filters=min:1|max:100
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query order {
      where = $db.order.tenant_id == $ctx_tenant.self.message.tenant_id && ($db.order.status_internal ==? $input.status_internal) && ($db.order.placed_at >=? $input.date_from) && ($db.order.placed_at <=? $input.date_to) && ($input.search == null || $db.order.order_number includes $input.search || $db.order.customer_name includes $input.search)
      sort = {placed_at: "desc"}
      return = {
        type  : "list"
        paging: {page: $input.page, per_page: $input.per_page}
      }
    } as $orders
  
    var $enriched_items {
      value = []
    }
  
    foreach ($orders.items) {
      each as $item {
        db.query order_component_allocation {
          join = {
            order_line: {
              table: "order_line"
              where: $db.order_component_allocation.order_line_id == $db.order_line.id
            }
          }
        
          where = $db.order_line.order_id == $item.id && $db.order_component_allocation.quantity_allocated < $db.order_component_allocation.quantity_required
          return = {type: "exists"}
        } as $has_shortage
      
        var $status {
          value = $has_shortage ? "SHORT" : "OK"
        }
      
        var.update $item {
          value = $item|set:"component_status":$status
        }
      
        array.push $enriched_items {
          value = $item
        }
      }
    }
  
    var.update $orders.items {
      value = $enriched_items
    }
  
    conditional {
      if ($input.component_status != null) {
        var.update $orders.items {
          value = $orders.items
            |filter:($this.component_status == $input.component_status)
        }
      }
    }
  }

  response = $orders
}