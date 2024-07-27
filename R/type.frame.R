#' Create a typed data frame
#'
#' @param frame The base data structure (e.g., data.frame, data.table)
#' @param col_types A list of column types and validators
#' @param freeze_n_cols Logical, whether to freeze the number of columns (default: TRUE)
#' @param row_callback A function to validate and process each row (optional)
#' @param allow_na Logical, whether to allow NA values (default: TRUE)
#' @param on_violation Action to take on violation: "error", "warning", or "silent" (default: "error")
#' @return A function that creates typed data frames
#' @export
type.frame <- function(frame, col_types, freeze_n_cols = TRUE, 
                       row_callback = NULL, allow_na = TRUE, 
                       on_violation = c("error", "warning", "silent")) {
  on_violation <- match.arg(on_violation)
  
  creator <- function(...) {
    df <- frame(...)
    errors <- list()
    
    # Validate column types
    for (col_name in names(col_types)) {
      if (!(col_name %in% names(df))) {
        errors <- c(errors, sprintf("Required column '%s' is missing", col_name))
      } else {
        col_data <- df[[col_name]]
        col_type <- col_types[[col_name]]
        
        error <- validate_property(col_name, col_data, col_type)
        if (!is.null(error)) {
          errors <- c(errors, error)
        }
      }
    }
    
    # Check for NA values
    if (!allow_na && any(is.na(df))) {
      na_cols <- names(df)[apply(df, 2, function(x) any(is.na(x)))]
      errors <- c(errors, sprintf("NA values found in column(s): %s", paste(na_cols, collapse = ", ")))
    }
    
    # Process rows with callback
    if (!is.null(row_callback)) {
      for (i in seq_len(nrow(df))) {
        row <- df[i, , drop = FALSE]
        tryCatch({
          result <- row_callback(row)
          if (!isTRUE(result)) {
            errors <- c(errors, sprintf("Row %d failed validation: %s", i, as.character(result)))
          }
        }, error = function(e) {
          errors <- c(errors, sprintf("Error processing row %d: %s", i, e$message))
        })
      }
    }
    
    # Handle all collected errors
    if (length(errors) > 0) {
      error_message <- paste("Validation errors:", paste(errors, collapse = "\n  "), sep = "\n  ")
      handle_violation(error_message, on_violation)
    }
    
    # Create the typed data frame
    typed_df <- structure(df,
                          class = c("typed_frame", class(df)),
                          col_types = col_types,
                          freeze_n_cols = freeze_n_cols,
                          row_callback = row_callback,
                          allow_na = allow_na,
                          on_violation = on_violation)
    
    return(typed_df)
  }
  
  return(creator)
}

#' Handle violations based on the specified action
#'
#' @param message The error message
#' @param action The action to take: "error", "warning", or "silent"
handle_violation <- function(message, action) {
  switch(action,
         "error" = stop(message, call. = FALSE),
         "warning" = warning(message, call. = FALSE),
         "silent" = invisible(NULL))
}

#' Modify a typed data frame using [ ]
#'
#' @param x A typed data frame
#' @param i Row index
#' @param j Column index or name
#' @param value The new value to assign
#' @return The modified typed data frame
#' @export
`[<-.typed_frame` <- function(x, i, j, value) {
  # Check if adding new columns is allowed
  if (attr(x, "freeze_n_cols") && !all(j %in% names(x))) {
    stop("Adding new columns is not allowed when freeze_n_cols is TRUE")
  }
  
  # Perform the assignment
  x <- NextMethod()
  
  # Re-validate the modified data
  for (col_name in names(attr(x, "col_types"))) {
    if (col_name %in% j) {
      col_data <- x[[col_name]]
      col_type <- attr(x, "col_types")[[col_name]]
      
      error <- validate_property(col_name, col_data, col_type)
      if (!is.null(error)) {
        handle_violation(error, attr(x, "on_violation"))
      }
    }
  }
  
  # Check for NA values
  if (!attr(x, "allow_na") && any(is.na(x))) {
    handle_violation("NA values are not allowed", attr(x, "on_violation"))
  }
  
  # Validate rows
  if (!is.null(attr(x, "row_validator"))) {
    invalid_rows <- which(!apply(x, 1, attr(x, "row_validator")))
    if (length(invalid_rows) > 0) {
      handle_violation(sprintf("Invalid rows: %s", paste(invalid_rows, collapse = ", ")), attr(x, "on_violation"))
    }
  }

  # Process new or modified rows with callback
  if (!is.null(attr(x, "row_callback"))) {
    affected_rows <- unique(i)
    for (row_index in affected_rows) {
      row <- x[row_index, , drop = FALSE]
      result <- attr(x, "row_callback")(row)
      if (!isTRUE(result)) {
        handle_violation(sprintf("Row %d failed validation: %s", row_index, as.character(result)), attr(x, "on_violation"))
      }
    }
  }
  
  return(x)
}

#' Modify a typed data frame using $
#'
#' @param x A typed data frame
#' @param name The name of the column to modify or add
#' @param value The new value to assign
#' @return The modified typed data frame
#' @export
`$<-.typed_frame` <- function(x, name, value) {
  # Check if adding new columns is allowed
  if (attr(x, "freeze_n_cols") && !(name %in% names(x))) {
    stop("Adding new columns is not allowed when freeze_n_cols is TRUE")
  }
  
  # Perform the assignment
  x <- NextMethod()
  
  # Re-validate the modified data
  if (name %in% names(attr(x, "col_types"))) {
    col_type <- attr(x, "col_types")[[name]]
    
    error <- validate_property(name, value, col_type)
    if (!is.null(error)) {
      handle_violation(error, attr(x, "on_violation"))
    }
  }
  
  # Check for NA values
  if (!attr(x, "allow_na") && any(is.na(x))) {
    handle_violation("NA values are not allowed", attr(x, "on_violation"))
  }
  
  # Validate rows
  if (!is.null(attr(x, "row_validator"))) {
    invalid_rows <- which(!apply(x, 1, attr(x, "row_validator")))
    if (length(invalid_rows) > 0) {
      handle_violation(sprintf("Invalid rows: %s", paste(invalid_rows, collapse = ", ")), attr(x, "on_violation"))
    }
  }

  # Process all rows with callback if column modification occurs
  if (!is.null(attr(x, "row_callback"))) {
    for (i in seq_len(nrow(x))) {
      row <- x[i, , drop = FALSE]
      result <- attr(x, "row_callback")(row)
      if (!isTRUE(result)) {
        handle_violation(sprintf("Row %d failed validation after column modification: %s", i, as.character(result)), attr(x, "on_violation"))
      }
    }
  }
  
  return(x)
}

#' Print method for typed data frames
#'
#' @param x A typed data frame
#' @param ... Additional arguments passed to print
#' @export
print.typed_frame <- function(x, ...) {
  cat("Typed data frame with the following properties:\n")
  cat(sprintf("Number of rows: %d\n", nrow(x)))
  cat(sprintf("Number of columns: %d\n", ncol(x)))
  cat("Column types:\n")
  for (name in names(attr(x, "col_types"))) {
    cat(sprintf("  %s: %s\n", name, format(attr(x, "col_types")[[name]])))
  }
  cat(sprintf("Freeze columns: %s\n", ifelse(attr(x, "freeze_n_cols"), "Yes", "No")))
  cat(sprintf("Allow NA: %s\n", ifelse(attr(x, "allow_na"), "Yes", "No")))
  cat(sprintf("On violation: %s\n", attr(x, "on_violation")))
  cat("\nData:\n")
  NextMethod()
}