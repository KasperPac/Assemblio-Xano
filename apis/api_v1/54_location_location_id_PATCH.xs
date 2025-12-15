// Edit location record
query "location/{location_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int location_id? filters=min:1
    dblink {
      table = "location"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch location {
      field_name = "id"
      field_value = $input.location_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $location
  }

  response = $location
}