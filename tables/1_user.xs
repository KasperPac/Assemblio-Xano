// Stores user information and allows the user to authenticate  against
table user {
  auth = true

  schema {
    int id
    timestamp created_at?=now
    text name filters=trim
    text full_name?
    email? email filters=trim|lower
    password? password filters=min:8|minAlpha:1|minDigit:1
  
    // Reference to the company the user belongs to.
    int account_id? {
      table = "account"
    }
  
    image? Avatar?
    object password_reset? {
      schema {
        password token?
        timestamp? expiration?
        bool used?
      }
    }
  
    timestamp? Last_Login?
    timestamp updated_at?
    int role? {
      table = "role"
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
    {type: "btree|unique", field: [{name: "email", op: "asc"}]}
  ]

  tags = ["xano:quick-start"]
}