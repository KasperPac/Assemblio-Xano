query dashboard_summary verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    // 1. Total Components
    db.query component {
      where = $db.component.tenant_id == $ctx_tenant.self.message.tenant_id
      return = {type: "count"}
    } as $total_components
  
    // 2. Total Products with Active BOM
    db.query product_bom {
      where = $db.product_bom.tenant_id == $ctx_tenant.self.message.tenant_id && $db.product_bom.is_active
      return = {type: "count"}
    } as $total_products_with_bom
  
    // 3. Total Open Orders
    db.query order {
      where = $db.order.tenant_id == $ctx_tenant.self.message.tenant_id && ($db.order.status_internal == "NEW" || $db.order.status_internal == "IN_PROGRESS" || $db.order.status_internal == "allocated")
      return = {type: "count"}
    } as $total_open_orders
  
    // 4. Low Stock Components
    db.query component {
      join = {
        inventory_balance: {
          table: "inventory_balance"
          where: $db.inventory_balance.component_id == $db.component.id
        }
      }
    
      where = $db.component.tenant_id == $ctx_tenant.self.message.tenant_id && ($db.inventory_balance.on_hand_qty <= $db.component.reorder_point && $db.inventory_balance.on_hand_qty > -1)
      return = {type: "count"}
    } as $low_stock_components_count
  
    // 4. Low Stock Components
    db.query component {
      join = {
        inventory_balance: {
          table: "inventory_balance"
          where: $db.inventory_balance.component_id == $db.component.id
        }
      }
    
      where = $db.component.tenant_id == $ctx_tenant.self.message.tenant_id && $db.inventory_balance.on_hand_qty < 0
      return = {type: "count"}
    } as $negative_stock_components_count
  
    // 5. Alert: Products Missing BOM
    // Query shopify_variant directly and check for missing active BOMs
    db.query shopify_variant {
      join = {
        product_bom: {
          table: "product_bom"
          type : "left"
          where: $db.shopify_variant.id == $db.product_bom.shopify_variant_id && $db.product_bom.is_active
        }
      }
    
      where = $db.shopify_variant.tenant_id == $ctx_tenant.self.message.tenant_id && $db.product_bom.id == null
      return = {type: "count"}
    } as $products_missing_bom_count
  
    // 6. Calculate Inventory Values (On Hand & In Production)
    // Query inventory_balance and pull in component cost via eval
    db.query inventory_balance {
      join = {
        component: {
          table: "component"
          where: $db.inventory_balance.component_id == $db.component.id
        }
      }
    
      where = $db.inventory_balance.tenant_id == $ctx_tenant.self.message.tenant_id
      eval = {cost_per_unit: $db.component.cost_per_unit}
      return = {type: "list"}
    } as $inventory_list
  
    var $stock_on_hand_value {
      value = 0
    }
  
    var $stock_in_prod_value {
      value = 0
    }
  
    foreach ($inventory_list) {
      each as $item {
        // On Hand Value = Cost Per Unit * On Hand Qty
        // Using first_notnull to handle potential nulls instead of default
        var $item_on_hand_val {
          value = ($item.cost_per_unit|first_notnull:0) * ($item.on_hand_qty|first_notnull:0)
        }
      
        math.add $stock_on_hand_value {
          value = $item_on_hand_val
        }
      
        // In Prod Value = Cost Per Unit * In Progress Qty
        var $item_in_prod_val {
          value = ($item.cost_per_unit|first_notnull:0) * ($item.in_progress_qty|first_notnull:0)
        }
      
        math.add $stock_in_prod_value {
          value = $item_in_prod_val
        }
      }
    }
  
    // Construct Alerts Array
    var $alerts {
      value = []
    }
  
    conditional {
      if ($low_stock_components_count > 0) {
        array.push $alerts {
          value = {
            Type    : "Low_Stock"
            Title   : "Low Stock Alert"
            Message : ($low_stock_components_count|to_text) ~ " Components are below reorder point"
            Severity: "Warning"
          }
        }
      }
    }
  
    conditional {
      if ($products_missing_bom_count > 0) {
        array.push $alerts {
          value = {
            Type    : "Missing_BOM"
            Title   : "Missing BOM Alert"
            Message : ($products_missing_bom_count|to_text) ~ " Variants are missing a BOM"
            Severity: "Warning"
          }
        }
      }
    }
  
    conditional {
      if ($negative_stock_components_count > 0) {
        array.push $alerts {
          value = {
            Type    : "Negative_Stock"
            Title   : "Negative Stock Alert"
            Message : ($negative_stock_components_count|to_text) ~ " Components are below 0 on hand"
            Severity: "Error"
          }
        }
      }
    }
  }

  response = {
    total_components          : $total_components
    total_products_with_bom   : $total_products_with_bom
    total_open_orders         : $total_open_orders
    low_stock_components_count: $low_stock_components_count
    stock_on_hand_value       : $stock_on_hand_value
    stock_in_prod_value       : $stock_in_prod_value
    alerts                    : $alerts
  }
}