// Retrieves a paginated list of inventory items where the on-hand quantity is below the reorder threshold.
query "reports/low-stock" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    // Optional location ID to filter the results.
    int location_id?
  
    // Multiplier for the reorder point (default 1.0).
    decimal threshold_multiplier?=1
  
    // Number of items per page.
    int limit?=20
  
    // Number of items to skip.
    int offset?
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    var $page {
      value = ($input.offset / $input.limit) + 1
    }
  
    db.query inventory_balance {
      join = {
        component: {
          table: "component"
          where: $db.inventory_balance.component_id == $db.component.id
        }
        location : {
          table: "location"
          type : "left"
          where: $db.inventory_balance.location_id == $db.location.id
        }
      }
    
      where = $db.inventory_balance.tenant_id == $ctx_tenant.self.message.tenant_id && $db.inventory_balance.location_id ==? $input.location_id && $db.inventory_balance.on_hand_qty <= $db.component.reorder_point
      eval = {
        sku           : $db.component.sku
        name          : $db.component.name
        location_scope: $db.location.name
        on_hand_qty   : $db.inventory_balance.on_hand_qty
        reorder_point : $db.component.reorder_point
      }
    
      return = {
        type  : "list"
        paging: {page: $page|floor, per_page: $input.limit}
      }
    } as $low_stock_items
  }

  response = $low_stock_items
  tags = ["reports"]
}