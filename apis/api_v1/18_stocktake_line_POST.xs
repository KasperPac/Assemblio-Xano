// Add stocktake_line record
query stocktake_line verb=POST {
  api_group = "api_v1"

  input {
    dblink {
      table = "stocktake_line"
    }
  }

  stack {
    db.add stocktake_line {
      data = {created_at: "now"}
    } as $stocktake_line
  }

  response = $stocktake_line
}