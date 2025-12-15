addon order_line_of_order {
  input {
    int order_id? {
      table = "order"
    }
  }

  stack {
    db.query order_line {
      where = $db.order_line.order_id == $input.order_id
      return = {type: "list"}
    }
  }
}