addon inventory_balance_of_component {
  input {
    int component_id? {
      table = "component"
    }
  }

  stack {
    db.query inventory_balance {
      where = $db.inventory_balance.component_id == $input.component_id
      return = {type: "single"}
    }
  }
}