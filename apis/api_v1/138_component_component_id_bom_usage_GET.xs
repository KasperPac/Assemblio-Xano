// Retrieves a list of products and variants that use a specific component, filtered by the current tenant.
query "component/{component_id}/bom-usage" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    // The ID of the component to search for
    int component_id
  }

  stack {
    function.run resolve_tenant as $tenant_id
    db.query product_bom_component {
      where = $db.product_bom_component.component_id == $input.component_id && "" == ""
      return = {type: "list"}
      addon = [
        {
          name : "product_bom"
          input: {product_bom_id: $output.product_bom_id}
          addon: [
            {
              name : "shopify_variant"
              input: {shopify_variant_id: $output.shopify_variant_id}
              addon: [
                {
                  name : "shopify_product"
                  input: {shopify_product_id: $output.shopify_product_id}
                  as   : "_shopify_product"
                }
              ]
              as   : "_shopify_variant"
            }
          ]
          as   : "_product_bom_of_shopify_variant"
        }
      ]
    } as $usage_list
  }

  response = $usage_list
}