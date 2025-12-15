// Edit stocktake_session record
query "stocktake_session/{stocktake_session_id}" verb=PATCH {
  api_group = "api_v1"

  input {
    int stocktake_session_id? filters=min:1
    dblink {
      table = "stocktake_session"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch stocktake_session {
      field_name = "id"
      field_value = $input.stocktake_session_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $stocktake_session
  }

  response = $stocktake_session
}