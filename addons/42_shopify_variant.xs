addon shopify_variant {
  input {
    int shopify_variant_id? {
      table = "shopify_variant"
    }
  }

  stack {
    db.query shopify_variant {
      where = $db.shopify_variant.id == $input.shopify_variant_id
      return = {type: "single"}
    }
  }
}