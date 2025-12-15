// Delete role record.
query "role/{role_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int role_id? filters=min:1
  }

  stack {
    db.del role {
      field_name = "id"
      field_value = $input.role_id
    }
  }

  response = null
}