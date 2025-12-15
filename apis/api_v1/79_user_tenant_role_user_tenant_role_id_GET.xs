// Get user_tenant_role record
query "user_tenant_role/{user_tenant_role_id}" verb=GET {
  api_group = "api_v1"

  input {
    int user_tenant_role_id? filters=min:1
  }

  stack {
    db.get user_tenant_role {
      field_name = "id"
      field_value = $input.user_tenant_role_id
    } as $user_tenant_role
  
    precondition ($user_tenant_role != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $user_tenant_role
}