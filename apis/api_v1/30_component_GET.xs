query component verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    text search? filters=trim
    text location_id? filters=trim
    bool low_stock?
    bool active?
    int limit?
    int page?
    bool? no_stock?
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $func1
  
    conditional {
      if ($input.low_stock) {
        db.query component {
          join = {
            inventory_balance: {
              table: "inventory_balance"
              where: $db.component.id == $db.inventory_balance.component_id
            }
            component_group  : {
              table: "component_group"
              where: $db.component.component_group_id == $db.component_group.id
            }
          }
        
          where = ($db.component.sku includes? $input.search || $db.component.name includes? $input.search || $db.component.description includes? $input.search) && $db.component.default_location_id ==? $input.location_id && $db.component.tenant_id == $func1.self.message.tenant_id && $db.inventory_balance.on_hand_qty <= $db.component.reorder_point && $db.component.deleted != true
          additional_where = $input.search
          eval = {group: $db.component_group.Name}
          return = {
            type  : "list"
            paging: {page: $input.page, per_page: 25, totals: true}
          }
        
          addon = [
            {
              name : "inventory_balance_of_component"
              input: {component_id: $output.id}
              addon: [
                {
                  name : "location"
                  input: {location_id: $output.location_id}
                  as   : "_location"
                }
              ]
              as   : "items.balance"
            }
          ]
        } as $component
      }
    
      elseif ($input.no_stock) {
        db.query component {
          join = {
            inventory_balance: {
              table: "inventory_balance"
              where: $db.component.id == $db.inventory_balance.component_id
            }
          }
        
          where = $db.component.tenant_id == $func1.self.message.tenant_id && $db.component.default_location_id ==? $input.location_id && ($db.component.sku includes? $input.search || $db.component.name includes? $input.search || $db.component.description includes? $input.search) && $db.inventory_balance.on_hand_qty <= 0 && $db.component.deleted != true
          additional_where = $input.search
          return = {type: "list", paging: {page: $input.page, per_page: 25}}
          addon = [
            {
              name : "inventory_balance_of_component"
              input: {component_id: $output.id}
              addon: [
                {
                  name : "location"
                  input: {location_id: $output.location_id}
                  as   : "_location"
                }
              ]
              as   : "items.balance"
            }
          ]
        } as $component
      }
    
      elseif ($input.no_stock == false && $input.low_stock == false) {
        db.query component {
          join = {
            inventory_balance: {
              table: "inventory_balance"
              type : "left"
              where: $db.component.id == $db.inventory_balance.component_id
            }
            component_group  : {
              table: "component_group"
              type : "left"
              where: $db.component.component_group_id == $db.component_group.id
            }
          }
        
          where = $db.component.tenant_id == $func1.self.message.tenant_id && $db.component.default_location_id ==? $input.location_id && ($db.component.sku includes? $input.search || $db.component.name includes? $input.search || $db.component.description includes? $input.search) && $db.component.deleted != true
          additional_where = $input.search
          eval = {group: $db.component_group.Name}
          return = {
            type  : "list"
            paging: {page: $input.page, per_page: 25, totals: true}
          }
        
          addon = [
            {
              name : "inventory_balance_of_component"
              input: {component_id: $output.id}
              addon: [
                {
                  name : "location"
                  input: {location_id: $output.location_id}
                  as   : "_location"
                }
              ]
              as   : "items.balance"
            }
          ]
        } as $component
      }
    }
  }

  response = {component: $component}
}