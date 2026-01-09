table suppliers {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int tenant_id? {
      table = "tenant"
    }
  
    text code? filters=trim
    text name? filters=trim
    text address_line1? filters=trim
    text address_line2? filters=trim
    text city? filters=trim
    text state? filters=trim
    text postcode? filters=trim
    text country? filters=trim
    text contact_person? filters=trim
    email contact_email? filters=trim|lower
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}