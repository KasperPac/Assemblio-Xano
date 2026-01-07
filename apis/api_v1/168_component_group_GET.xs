// Query all component_group records
query component_group verb=GET {
  api_group = "api_v1"

  input {
  }

  stack {
    db.query component_group {
      return = {type: "list"}
    } as $component_group
  }

  response = $component_group
}