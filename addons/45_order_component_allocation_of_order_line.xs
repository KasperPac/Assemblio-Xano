addon order_component_allocation_of_order_line {
  input {
    int order_line_id? {
      table = "order_line"
    }
  }

  stack {
    db.query order_component_allocation {
      where = $db.order_component_allocation.order_line_id == $input.order_line_id
      return = {type: "list"}
    }
  }
}