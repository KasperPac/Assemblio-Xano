// Add role record
query role verb=POST {
  api_group = "api_v1"

  input {
    dblink {
      table = "role"
    }
  }

  stack {
    db.add role {
      data = {created_at: "now"}
    } as $role
  }

  response = $role
}