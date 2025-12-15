// Query all tenant records
query tenant verb=GET {
  api_group = "api_v1"

  input {
  }

  stack {
    db.query tenant {
      return = {type: "list"}
    } as $tenant
  }

  response = $tenant
}