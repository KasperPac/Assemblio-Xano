// Delete stocktake_session record.
query "stocktake_session/{stocktake_session_id}" verb=DELETE {
  api_group = "api_v1"

  input {
    int stocktake_session_id? filters=min:1
  }

  stack {
    db.del stocktake_session {
      field_name = "id"
      field_value = $input.stocktake_session_id
    }
  }

  response = null
}