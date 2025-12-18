// Retrieves the line items for a specific purchase order, ensuring tenant isolation.
query "purchase_order/lines" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    // The ID of the purchase order to retrieve lines for.
    int order_id
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    var $tenant_id {
      value = $ctx_tenant.self.message.tenant_id
    }
  
    // Verify the purchase order exists and belongs to the user's tenant
    db.query purchase_order {
      where = $db.purchase_order.id == $input.order_id && $db.purchase_order.tenant == $tenant_id
      return = {type: "single"}
    } as $purchase_order
  
    // Ensure the order was found before proceeding
    precondition ($purchase_order != null) {
      error_type = "inputerror"
      error = "Purchase order not found or access denied."
    }
  
    // Retrieve all lines associated with this purchase order
    db.query purchase_order_line {
      where = $db.purchase_order_line.purchase_order == $input.order_id && $db.purchase_order_line.tenant == $tenant_id
      return = {type: "list"}
      addon = [
        {
          name : "component"
          input: {component_id: $output.component}
          as   : "_component"
        }
      ]
    } as $lines
  }

  response = $lines
}