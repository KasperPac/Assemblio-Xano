addon shopify_product {
  input {
    int shopify_product_id? {
      table = "shopify_product"
    }
  }

  stack {
    db.query shopify_product {
      where = $db.shopify_product.id == $input.shopify_product_id
      return = {type: "single"}
    }
  }
}