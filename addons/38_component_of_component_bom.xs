addon component_of_component_bom {
  input {
    int component_id? {
      table = "component"
    }
  
    int tenant_id? {
      table = "tenant"
    }
  }

  stack {
    db.query component {
      where = $db.component.id == $input.component_id && $db.component.tenant_id == $input.tenant_id
      return = {type: "list"}
    }
  }
}