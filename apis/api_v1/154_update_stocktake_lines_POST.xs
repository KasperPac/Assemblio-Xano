// Batch updates stocktake lines with counted quantities. Iterates through provided items and updates those marked as ADJUSTED.
query update_stocktake_lines verb=POST {
  api_group = "api_v1"
  auth = "user"

  input {
    // Array of line item objects containing id, counted_qty, status, and note.
    json[] line_items
  }

  stack {
    foreach ($input.line_items) {
      each as $line_item {
        conditional {
          if ($line_item.status == "ADJUSTED") {
            db.get stocktake_line {
              field_name = "id"
              field_value = $line_item.id
            } as $current_line
          
            var $variance_qty {
              value = $line_item.counted_qty - $current_line.expected_qty
            }
          
            db.edit stocktake_line {
              field_name = "id"
              field_value = $line_item.id
              data = {
                counted_qty : $line_item.counted_qty
                variance_qty: $variance_qty
                status      : $line_item.status
                note        : $line_item.note
                updated_at  : "now"
              }
            } as $updated_line
          }
        }
      }
    }
  }

  response = {
    success: true
    message: "Stocktake lines processed successfully."
  }
}