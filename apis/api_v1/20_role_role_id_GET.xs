// Get role record
query "role/{role_id}" verb=GET {
  api_group = "api_v1"

  input {
    int role_id? filters=min:1
  }

  stack {
    db.get role {
      field_name = "id"
      field_value = $input.role_id
    } as $role
  
    precondition ($role != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $role
}