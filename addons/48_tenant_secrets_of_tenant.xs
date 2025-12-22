addon tenant_secrets_of_tenant {
  input {
    int tenant_id? {
      table = "tenant"
    }
  }

  stack {
    db.query tenant_secrets {
      where = $db.tenant_secrets.tenant_id == $input.tenant_id
      return = {type: "single"}
    }
  }
}