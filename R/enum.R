#' Create an enumerated type
#'
#' @description
#' Creates an enumerated type with a fixed set of possible values.
#'
#' @param ... The possible values for the enumerated type.
#' @return A function that creates enum objects of the defined type.
#' @export
#'
#' @examples
#' Colors <- enum("red", "green", "blue")
#' my_color <- Colors("red")
#' print(my_color)
enum <- function(...) {
  values <- c(...)
  
  new <- function(value) {
    if (!value %in% values) {
      stop(sprintf("Invalid value. Must be one of: %s", paste(values, collapse = ", ")))
    }
    value <- list(value = value)
    class(value) <- "enum"
    attr(value, "values") <- values
    value
  }
  
  class(new) <- "enum_generator"
  attr(new, "values") <- values
  new
}

#' Print method for enum objects
#'
#' @param x An enum object
#' @param ... Additional arguments (not used)
#' @export
print.enum <- function(x, ...) {
  cat("Enum:", x$value, "\n")
}

#' Equality comparison for enum objects
#'
#' @param e1 First enum object
#' @param e2 Second enum object or value
#' @export
`==.enum` <- function(e1, e2) {
  if (inherits(e2, "enum")) {
    e1$value == e2$value
  } else {
    e1$value == e2
  }
}

#' Get value from enum object
#'
#' @param x An enum object
#' @param name The name of the field to access (should be "value")
#' @export
`$.enum` <- function(x, name) {
  if (name == "value") {
    x[["value"]]
  } else {
    stop("Invalid field for enum")
  }
}

#' Set value of enum object
#'
#' @param x An enum object
#' @param name The name of the field to set (should be "value")
#' @param value The new value to set
#' @export
`$<-.enum` <- function(x, name, value) {
  if (name != "value") {
    stop("Cannot add new fields to an enum")
  }
  if (!value %in% attr(x, "values")) {
    stop(sprintf("Invalid value. Must be one of: %s", paste(attr(x, "values"), collapse = ", ")))
  }
  x[["value"]] <- value
  x
}

#' Print method for enum generators
#'
#' @param x An enum generator function
#' @param ... Additional arguments (not used)
#' @export
print.enum_generator <- function(x, ...) {
  cat("Enum generator:", paste(attr(x, "values"), collapse = ", "), "\n")
}