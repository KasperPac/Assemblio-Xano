addon role {
  input {
    int role_id? {
      table = "role"
    }
  }

  stack {
    db.query role {
      where = $db.role.id == $input.role_id
      return = {type: "single"}
    }
  }
}