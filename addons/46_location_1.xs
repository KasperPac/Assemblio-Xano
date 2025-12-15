addon location_1 {
  input {
    int location_id? {
      table = "location"
    }
  }

  stack {
    db.query location {
      where = $db.location.id == $input.location_id
      return = {type: "single"}
    }
  }
}