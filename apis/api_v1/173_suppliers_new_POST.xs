query "suppliers/new" verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    text code? filters=trim
    text name? filters=trim
    text address_line1? filters=trim
    text address_line2? filters=trim
    text city? filters=trim
    text state? filters=trim
    text postcode? filters=trim
    text country? filters=trim
    text contact_person? filters=trim
    email contact_email? filters=trim|lower
    text contact_phone? filters=trim
  }

  stack {
    function.run resolve_tenant {
      input = {user_id: $auth.id}
    } as $ctx_tenant
  
    db.query suppliers {
      where = $db.suppliers.tenant_id == $ctx_tenant.self.message.tenant_id && $input.code == $db.suppliers.code
      return = {type: "list"}
    } as $suppliers
  
    precondition ($suppliers == null) {
      error = "Supplier code already exists"
    }
  
    db.add suppliers {
      data = {
        created_at    : "now"
        tenant_id     : $ctx_tenant.self.message.tenant_id
        code          : $input.code
        name          : $input.name
        address_line1 : $input.address_line1
        address_line2 : $input.address_line2
        city          : $input.city
        state         : $input.state
        postcode      : $input.postcode
        country       : $input.country
        contact_person: $input.contact_person
        contact_email : $input.contact_email
        contact_phone : $input.contact_phone
        is_active     : true
      }
    } as $suppliers1
  }

  response = $ctx_tenant
}