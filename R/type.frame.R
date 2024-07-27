#' Create a typed data frame
#'
#' @param frame The base data structure (e.g., data.frame, data.table)
#' @param col_types A list of column types and validators
#' @param freeze_n_cols Logical, whether to freeze the number of columns (default: FALSE)
#' @param row_validator A function to validate each row (optional)
#' @param allow_na Logical, whether to allow NA values (default: TRUE)
#' @param on_violation Action to take on violation: "error", "warning", or "silent" (default: "error")
#' @return A function that creates typed data frames
#' @export
type.frame <- function(frame, col_types, freeze_n_cols = FALSE, 
                       row_validator = NULL, allow_na = TRUE, 
                       on_violation = c("error", "warning", "silent")) {
  on_violation <- match.arg(on_violation)
  
  creator <- function(...) {
    df <- frame(...)
    
    # Validate column types
    for (col_name in names(col_types)) {
      if (!(col_name %in% names(df))) {
        stop(sprintf("Required column '%s' is missing", col_name))
      }
      
      col_data <- df[[col_name]]
      col_type <- col_types[[col_name]]
      
      error <- validate_property(col_name, col_data, col_type)
      if (!is.null(error)) {
        handle_violation(error, on_violation)
      }
    }
    
    # Check for NA values
    if (!allow_na && any(is.na(df))) {
      handle_violation("NA values are not allowed", on_violation)
    }
    
    # Validate rows
    if (!is.null(row_validator)) {
      invalid_rows <- which(!apply(df, 1, row_validator))
      if (length(invalid_rows) > 0) {
        handle_violation(sprintf("Invalid rows: %s", paste(invalid_rows, collapse = ", ")), on_violation)
      }
    }
    
    # Create the typed data frame
    typed_df <- structure(df,
                          class = c("typed_frame", class(df)),
                          col_types = col_types,
                          freeze_n_cols = freeze_n_cols,
                          row_validator = row_validator,
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

#' Modify a typed data frame
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