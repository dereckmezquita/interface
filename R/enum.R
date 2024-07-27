#' Create an enumeration type
#'
#' @description
#' Creates an enumeration type with a fixed set of allowed values.
#'
#' @param ... The allowed values for this enum type.
#' @return A function that creates and validates values of this enum type.
#' @export
enum <- function(...) {
  allowed_values <- c(...)
  
  validator <- function(x) {
    if (length(x) != 1) {
      stop("Value must be a single element")
    }
    if (!(x %in% allowed_values)) {
      stop(sprintf("Invalid value. Allowed values are: %s", paste(allowed_values, collapse = ", ")))
    }
    structure(x, class = c("enum", "character"), allowed_values = allowed_values)
  }
  
  structure(validator, class = "enum_type", allowed_values = allowed_values)
}

#' Print method for enum values
#'
#' @param x An enum value
#' @param ... Additional arguments (not used)
#' @export
print.enum <- function(x, ...) {
  cat(sprintf("Enum: %s\n", x))
}

#' Format method for enum types
#'
#' @param x An enum type
#' @param ... Additional arguments (not used)
#' @export
format.enum_type <- function(x, ...) {
  sprintf("enum(%s)", paste(attr(x, "allowed_values"), collapse = ", "))
}

#' Assignment method for enum values
#'
#' @param x An enum value
#' @param value The new value to set
#' @export
`<-.enum` <- function(x, value) {
  allowed_values <- attr(x, "allowed_values")
  if (!(value %in% allowed_values)) {
    stop(sprintf("Invalid value. Allowed values are: %s", paste(allowed_values, collapse = ", ")))
  }
  structure(value, class = c("enum", "character"), allowed_values = allowed_values)
}