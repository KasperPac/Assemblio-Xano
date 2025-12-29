query "user/current_tenant" verb=PATCH {
  api_group = "api_v1"
  auth = "user"

  input {
    int tenant_id?
  }

  stack {
    db.edit user {
      field_name = "id"
      field_value = $auth.id
      data = {current_tenant: $input.tenant_id}
    }
  }

  response = $""
}