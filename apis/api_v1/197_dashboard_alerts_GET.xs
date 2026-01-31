query "dashboard/alerts" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // Low Stock Components
    db.query component {
      join = {
        inventory_balance: {
          table: "inventory_balance"
          where: $db.inventory_balance.component_id == $db.component.id
        }
        suppliers        : {
          table: "suppliers"
          type : "left"
          where: $db.suppliers.name == $db.component.preferred_supplier
        }
      }
    
      where = $db.component.tenant_id == $ctx_tenant.self.message.tenant_id && $db.inventory_balance.on_hand_qty <= $db.component.reorder_point
      eval = {
        sku        : $db.component.sku
        on_hand_qty: $db.inventory_balance.on_hand_qty
        in_prod_qty: $db.inventory_balance.in_progress_qty
        reorder_qty: $db.component.reorder_point
        supplier   : $db.suppliers.name
      }
    
      return = {type: "list"}
    } as $low_stock_components
  }

  response = {Low_Stock_Comp: $low_stock_components}
}