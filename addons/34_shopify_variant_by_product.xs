addon shopify_variant_by_product {
  input {
    int tenant_id? {
      table = "tenant"
    }
  
    int shopify_product_id? {
      table = "shopify_product"
    }
  }

  stack {
    db.query shopify_variant {
      where = $db.shopify_variant.tenant_id == $input.tenant_id && $db.shopify_variant.shopify_product_id == $input.shopify_product_id
      return = {type: "list"}
    }
  }
}