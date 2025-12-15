query "stocktake-sessions/{session_id}" verb=GET {
  api_group = "api_v1"
  auth = "user"

  input {
    // The ID of the stocktake session to retrieve
    int session_id
  }

  stack {
    // Retrieve the stocktake session record
    db.get stocktake_session {
      field_name = "id"
      field_value = $input.session_id
    } as $stocktake_session
  
    // Retrieve all lines associated with this session with component details
    db.query stocktake_line {
      join = {
        component: {
          table: "component"
          where: $db.stocktake_line.component_id == $db.component.id
        }
      }
    
      where = $db.stocktake_line.stocktake_session_id == $input.session_id
      sort = {stocktake_line.id: "asc"}
      eval = {
        sku            : $db.component.sku
        name           : $db.component.name
        unit_of_measure: $db.component.unit_of_measure
      }
    
      return = {type: "list"}
    } as $stocktake_lines
  
    // Initialize summary variables
    var $count_adjusted {
      value = 0
    }
  
    var $count_no_variance {
      value = 0
    }
  
    var $count_variance {
      value = 0
    }
  
    var $total_variance_qty {
      value = 0
    }
  
    // Iterate through lines to calculate statistics
    foreach ($stocktake_lines) {
      each as $line {
        // Check for adjusted status
        conditional {
          if ($line.status == "ADJUSTED") {
            var.update $count_adjusted {
              value = $count_adjusted + 1
            }
          }
        }
      
        // Check variance
        conditional {
          if ($line.counted_qty == $line.expected_qty) {
            var.update $count_no_variance {
              value = $count_no_variance + 1
            }
          }
        
          else {
            var.update $count_variance {
              value = $count_variance + 1
            }
          }
        }
      
        // Update running total of variance
        var.update $total_variance_qty {
          value = $total_variance_qty + $line.variance_qty
        }
      }
    }
  
    // Update the session object with the calculated summaries
    var.update $stocktake_session {
      value = $stocktake_session
        |set:"summary_adjusted":$count_adjusted
        |set:"summary_no_variance":$count_no_variance
        |set:"summary_with_variance":$count_variance
        |set:"summary_total_variance":$total_variance_qty
        |set:"lines":$stocktake_lines
    }
  }

  response = $stocktake_session
}