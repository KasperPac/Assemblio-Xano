// Delete location record.
query "location/{location_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int location_id? filters=min:1
  }

  stack {
    db.del location {
      field_name = "id"
      field_value = $input.location_id
    }
  }

  response = null
}