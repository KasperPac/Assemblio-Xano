addon product_bom {
  input {
    int product_bom_id? {
      table = "product_bom"
    }
  }

  stack {
    db.query product_bom {
      where = $db.product_bom.id == $input.product_bom_id
      return = {type: "single"}
    }
  }
}