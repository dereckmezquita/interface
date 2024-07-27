#' Create an enumeration type
#'
#' @description
#' Creates an enumeration type with a fixed set of allowed values.
#'
#' @param ... The allowed values for this enum type.
#' @return A function that creates and validates values of this enum type.
#' @export
#'
#' @examples
#' Colors <- enum("red", "green", "blue")
#' my_color <- Colors("red")  # Valid
#' print(my_color)  # [1] "red"
#' try(Colors("yellow"))  # Error: Invalid value. Allowed values are: red, green, blue
enum <- function(...) {
  allowed_values <- c(...)
  
  validator <- function(x) {
    if (length(x) != 1) {
      stop("Value must be a single element")
    }
    if (!(x %in% allowed_values)) {
      stop(sprintf("Invalid value. Allowed values are: %s", paste(allowed_values, collapse = ", ")))
    }
    structure(x, class = c("enum", "character"))
  }
  
  structure(validator, class = "enum_type", allowed_values = allowed_values)
}

#' Print method for enum values
#'
#' @param x An enum value
#' @param ... Additional arguments (not used)
#' @export
print.enum <- function(x, ...) {
  cat(sprintf("Enum value: %s\n", x))
}
