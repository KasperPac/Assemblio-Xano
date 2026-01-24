query "deleted/bom" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query product_bom {
      where = $db.product_bom.tenant_id == $ctx_tenant.self.message.tenant_id && $db.product_bom.deleted
      return = {type: "list"}
    } as $product_bom1
  }

  response = $ctx_tenant
}