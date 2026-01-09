query purchase_orders verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query purchase_order {
      join = {
        suppliers: {
          table: "suppliers"
          type : "left"
          where: $db.purchase_order.suppliers_id == $db.suppliers.id
        }
      }
    
      where = $db.purchase_order.tenant == $ctx_tenant.self.message.tenant_id
      eval = {supplier_name: $db.suppliers.name}
      return = {type: "list"}
    } as $purchase_order1
  }

  response = {purchase_orders: $purchase_order1}
}