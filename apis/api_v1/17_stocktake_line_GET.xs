// Query all stocktake_line records
query stocktake_line verb=GET {
  api_group = "api_v1"

  input {
  }

  stack {
    db.query stocktake_line {
      return = {type: "list"}
    } as $stocktake_line
  }

  response = $stocktake_line
}