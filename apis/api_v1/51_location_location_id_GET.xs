// Get location record
query "location/{location_id}" verb=GET {
  api_group = "api_v1"

  input {
    int location_id? filters=min:1
  }

  stack {
    db.get location {
      field_name = "id"
      field_value = $input.location_id
    } as $location
  
    precondition ($location != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $location
}