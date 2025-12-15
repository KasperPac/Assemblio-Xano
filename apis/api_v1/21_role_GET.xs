// Query all role records
query role verb=GET {
  api_group = "api_v1"

  input {
  }

  stack {
    db.query role {
      return = {type: "list"}
    } as $role
  }

  response = $role
}