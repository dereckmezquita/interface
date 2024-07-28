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

print.enum <- function(x, ...) {
  cat("Enum:", x$value, "\n")
}

`==.enum` <- function(e1, e2) {
  if (inherits(e2, "enum")) {
    e1$value == e2$value
  } else {
    e1$value == e2
  }
}

`$.enum` <- function(x, name) {
  if (name == "value") {
    x[["value"]]
  } else {
    stop("Invalid field for enum")
  }
}

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

print.enum_generator <- function(x, ...) {
  cat("Enum generator:", paste(attr(x, "values"), collapse = ", "), "\n")
}

# Usage
Colours <- enum("red", "blue", "yellow")

# Create valid enum value
col1 <- Colours("red")
print(col1)
class(col1)

# Update value using standard assignment
col1$value <- "blue"
print(col1)

# Try to assign an invalid value
tryCatch(
  col1$value <- "green",
  error = function(e) cat("Error:", conditionMessage(e), "\n")
)

# Comparison
col2 <- Colours("yellow")
cat("col1 == col2:", col1 == col2, "\n")
cat("col1 == 'blue':", col1 == "blue", "\n")

# Print the enum generator
print(Colours)
