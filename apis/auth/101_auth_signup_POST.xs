// Signup and retrieve an authentication token
query "auth/signup" verb=POST {
  api_group = "auth"

  input {
    text name?
    email email? filters=lower|trim
    password password?
    text full_name?
  }

  stack {
    db.get user {
      field_name = "email"
      field_value = $input.email
    } as $user
  
    precondition ($user == null) {
      error_type = "accessdenied"
      error = "This account is already in use."
    }
  
    db.add user {
      data = {
        created_at: "now"
        name      : $input.name
        email     : $input.email
        password  : $input.password
        full_name : $input.full_name
        updated_at: "now"
      }
    } as $user
  
    security.create_auth_token {
      table = "user"
      extras = {}
      expiration = 86400
      id = $user.id
    } as $authToken
  }

  response = {authToken: $authToken}
}