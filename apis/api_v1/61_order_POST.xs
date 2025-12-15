// Add order record
query order verb=POST {
  api_group = "api_v1"

  input {
    dblink {
      table = "order"
    }
  }

  stack {
    db.add order {
      data = {created_at: "now"}
    } as $order
  }

  response = $order
}