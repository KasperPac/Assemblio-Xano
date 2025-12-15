// Add location record
query location verb=POST {
  api_group = "api_v1"

  input {
    dblink {
      table = "location"
    }
  }

  stack {
    db.add location {
      data = {created_at: "now"}
    } as $location
  }

  response = $location
}