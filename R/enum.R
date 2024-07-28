#' Create an enumerated type
#'
#' @description
#' Creates an enumerated type with a fixed set of possible values. This function returns an enum generator,
#' which can be used to create enum objects with values restricted to the specified set.
#'
#' @param ... The possible values for the enumerated type. These should be unique character strings.
#' @return A function (enum generator) that creates enum objects of the defined type.
#' @export
#'
#' @examples
#' # Create an enum type for colors
#' Colors <- enum("red", "green", "blue")
#'
#' # Create enum objects
#' my_color <- Colors("red")
#' print(my_color)  # Output: Enum: red
#'
#' # Trying to create an enum with an invalid value will raise an error
#' try(Colors("yellow"))
#'
#' # Enums can be used in interfaces
#' ColoredShape <- interface(
#'   shape = character,
#'   color = Colors
#' )
#'
#' my_shape <- ColoredShape(shape = "circle", color = "red")
#'
#' # Modifying enum values
#' my_shape$color$value <- "blue"  # This is valid
#' try(my_shape$color$value <- "yellow")  # This will raise an error
#'
#' @seealso \code{\link{interface}} for using enums in interfaces
enum <- function(...) {
    values <- c(...)
    
    new <- function(value) {
        if (!value %in% values) {
            stop(sprintf("Invalid value. Must be one of: %s", paste(values, collapse = ", ")))
        }
        return(structure(
            list(value = value),
            class = "enum",
            values = values
        ))
    }
    
    class(new) <- c("enum_generator", "function")
    attr(new, "values") <- values
    return(new)
}

#' Print method for enum objects
#'
#' @description
#' Prints a human-readable representation of an enum object.
#'
#' @param x An enum object
#' @param ... Additional arguments (not used)
#' @export
#'
#' @examples
#' Colors <- enum("red", "green", "blue")
#' my_color <- Colors("red")
#' print(my_color)  # Output: Enum: red
print.enum <- function(x, ...) {
    cat("Enum:", x$value, "\n")
}

#' Equality comparison for enum objects
#'
#' @description
#' Compares two enum objects or an enum object with a character value.
#'
#' @param e1 First enum object
#' @param e2 Second enum object or a character value
#' @return Logical value indicating whether the two objects are equal
#' @export
#'
#' @examples
#' Colors <- enum("red", "green", "blue")
#' color1 <- Colors("red")
#' color2 <- Colors("blue")
#' color1 == color2  # FALSE
#' color1 == Colors("red")  # TRUE
#' color1 == "red"  # TRUE
`==.enum` <- function(e1, e2) {
    if (inherits(e2, "enum")) {
        e1$value == e2$value
    } else {
        e1$value == e2
    }
}

#' Get value from enum object
#'
#' @description
#' Retrieves the value of an enum object.
#'
#' @param x An enum object
#' @param name The name of the field to access (should be "value")
#' @return The value of the enum object
#' @export
#'
#' @examples
#' Colors <- enum("red", "green", "blue")
#' my_color <- Colors("red")
#' my_color$value  # "red"
`$.enum` <- function(x, name) {
    if (name == "value") {
        x[["value"]]
    } else {
        stop("Invalid field for enum")
    }
}

#' Set value of enum object
#'
#' @description
#' Sets the value of an enum object. The new value must be one of the valid enum values.
#'
#' @param x An enum object
#' @param name The name of the field to set (should be "value")
#' @param value The new value to set
#' @return The updated enum object
#' @export
#'
#' @examples
#' Colors <- enum("red", "green", "blue")
#' my_color <- Colors("red")
#' my_color$value <- "blue"  # Valid assignment
#' try(my_color$value <- "yellow")  # This will raise an error
`$<-.enum` <- function(x, name, value) {
    if (name != "value") {
        stop("Cannot add new fields to an enum")
    }
    if (!value %in% attr(x, "values")) {
        stop(sprintf("Invalid value. Must be one of: %s", paste(attr(x, "values"), collapse = ", ")))
    }
    x[["value"]] <- value
    return(x)
}

#' Print method for enum generators
#'
#' @description
#' Prints a human-readable representation of an enum generator, showing all possible values.
#'
#' @param x An enum generator function
#' @param ... Additional arguments (not used)
#' @export
#'
#' @examples
#' Colors <- enum("red", "green", "blue")
#' print(Colors)  # Output: Enum generator: red, green, blue
print.enum_generator <- function(x, ...) {
    cat("Enum generator:", paste(attr(x, "values"), collapse = ", "), "\n")
}
