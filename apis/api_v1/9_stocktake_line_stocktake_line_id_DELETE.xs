// Delete stocktake_line record.
query "stocktake_line/{stocktake_line_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int stocktake_line_id? filters=min:1
  }

  stack {
    db.del stocktake_line {
      field_name = "id"
      field_value = $input.stocktake_line_id
    }
  }

  response = null
}