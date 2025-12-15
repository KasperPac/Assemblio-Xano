addon has_active_bom {
  input {
    int shopify_variant_id? {
      table = "shopify_variant"
    }
  }

  stack {
    db.query product_bom {
      where = $db.product_bom.shopify_variant_id == $input.shopify_variant_id
      return = {type: "exists"}
    }
  }
}