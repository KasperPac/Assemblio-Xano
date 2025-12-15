addon component {
  input {
    int component_id? {
      table = "component"
    }
  }

  stack {
    db.query component {
      where = $db.component.id == $input.component_id
      return = {type: "list"}
    }
  }
}