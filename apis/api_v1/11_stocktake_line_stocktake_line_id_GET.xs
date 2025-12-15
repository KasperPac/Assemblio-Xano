// Get stocktake_line record
query "stocktake_line/{stocktake_line_id}" verb=GET {
  api_group = "api_v1"

  input {
    int stocktake_line_id? filters=min:1
  }

  stack {
    db.get stocktake_line {
      field_name = "id"
      field_value = $input.stocktake_line_id
    } as $stocktake_line
  
    precondition ($stocktake_line != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $stocktake_line
}