// Edit stocktake_line record
query "stocktake_line/{stocktake_line_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int stocktake_line_id? filters=min:1
    dblink {
      table = "stocktake_line"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch stocktake_line {
      field_name = "id"
      field_value = $input.stocktake_line_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $stocktake_line
  }

  response = $stocktake_line
}