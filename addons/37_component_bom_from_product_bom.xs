addon component_bom_from_product_bom {
  input {
    int product_bom_id? {
      table = "product_bom"
    }
  }

  stack {
    db.query product_bom_component {
      where = $db.product_bom_component.product_bom_id == $input.product_bom_id
      return = {type: "list"}
    }
  }
}