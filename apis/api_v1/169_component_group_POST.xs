// Add component_group record
query component_group verb=POST {
  api_group = "api_v1"

  input {
    dblink {
      table = "component_group"
    }
  }

  stack {
    db.add component_group {
      data = {created_at: "now"}
    } as $component_group
  }

  response = $component_group
}