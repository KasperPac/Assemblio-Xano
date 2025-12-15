// Delete user_tenant_role record.
query "user_tenant_role/{user_tenant_role_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int user_tenant_role_id? filters=min:1
  }

  stack {
    db.del user_tenant_role {
      field_name = "id"
      field_value = $input.user_tenant_role_id
    }
  }

  response = null
}