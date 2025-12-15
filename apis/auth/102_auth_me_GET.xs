// Get the record belonging to the authentication token
query "auth/me" verb=GET {
  api_group = "auth"
  auth = "user"

  input {
  }

  stack {
    db.get user {
      field_name = "id"
      field_value = $auth.id
      output = [
        "id"
        "created_at"
        "name"
        "email"
        "account_id"
        "role"
        "password_reset"
        "full_name"
        "updated_at"
      ]
    } as $user
  }

  response = $user
}