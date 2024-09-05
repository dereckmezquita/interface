#' Define an interface
#'
#' @description
#' An interface defines a structure with specified properties and their types or validation functions. 
#' This is useful for ensuring that objects adhere to a particular format and type constraints.
#'
#' @param ... Named arguments defining the properties and their types or validation functions.
#' @param validate_on_access Logical, whether to validate properties on access (default: FALSE).
#' @param extends A list of interfaces that this interface extends.
#' @return A function of class 'interface' that creates objects implementing the defined interface.
#'         The returned function takes named arguments corresponding to the interface properties
#'         and returns an object of class 'interface_object'.
#' @examples
#' # Define an interface for a person
#' Person <- interface(
#'   name = character,
#'   age = numeric,
#'   email = character
#' )
#'
#' # Create an object that implements the Person interface
#' john <- Person(
#'   name = "John Doe",
#'   age = 30,
#'   email = "john@example.com"
#' )
#'
#' # Using enum in an interface
#' Colors <- enum("red", "green", "blue")
#' ColoredShape <- interface(
#'   shape = character,
#'   color = Colors
#' )
#'
#' my_shape <- ColoredShape(shape = "circle", color = "red")
#'
#' # In-place enum declaration
#' Car <- interface(
#'   make = character,
#'   model = character,
#'   color = enum("red", "green", "blue")
#' )
#'
#' my_car <- Car(make = "Toyota", model = "Corolla", color = "red")
#' @export
interface <- function(..., validate_on_access = FALSE, extends = list()) {
    properties <- list(...)

    # Process in-place enum declarations
    for (name in names(properties)) {
        if (inherits(properties[[name]], "enum_generator")) {
            properties[[name]] <- properties[[name]]
        }
    }

    # Merge properties from extended interfaces
    all_properties <- properties
    for (ext in extends) {
        if (!inherits(ext, "interface")) {
            stop(sprintf("Invalid extends argument: %s is not an interface", deparse(substitute(ext))), call. = FALSE)
        }
        ext_properties <- attr(ext, "properties")
        all_properties <- c(all_properties, ext_properties[setdiff(names(ext_properties), names(all_properties))])
    }

    creator <- function(...) {
        values <- list(...)
        obj <- new.env(parent = emptyenv())

        errors <- character()

        for (name in names(all_properties)) {
            if (!name %in% names(values)) {
                errors <- c(errors, sprintf("Missing required property: %s", name))
                next
            }

            value <- values[[name]]
            validator <- all_properties[[name]]

            if (inherits(validator, "enum_generator")) {
                tried <- tryCatch({
                    new_value <- validator(value)
                    list(success = TRUE, value = new_value)
                }, error = function(e) {
                    list(
                        success = FALSE,
                        value = NULL,
                        error = sprintf("Invalid enum value for property '%s': %s", name, e$message)
                    )
                })

                if (!tried$success) {
                    errors <- c(errors, tried$error)
                    next
                }

                value <- tried$value
            }

            error <- validate_property(name, value, validator)
            if (!is.null(error)) {
                errors <- c(errors, error)
            } else {
                obj[[name]] <- value
            }
        }

        if (length(errors) > 0) {
            error_message <- paste(
                "Errors occurred during interface creation:",
                paste(errors, collapse = "\n  - "),
                sep = "\n  - "
            )
            stop(error_message, call. = FALSE)
        }

        return(structure(
            obj,
            class = c("interface_object", "environment"),
            properties = all_properties,
            validate_on_access = validate_on_access
        ))
    }

    return(structure(
        creator,
        class = "interface",
        properties = all_properties,
        validate_on_access = validate_on_access,
        extends = extends
    ))
}

#' Get a property from an interface object
#'
#' @param x An interface object
#' @param name The name of the property to get
#' @return The value of the specified property. The class of the returned value
#'         depends on the property's type as defined in the interface.
#' @export
`$.interface_object` <- function(x, name) {
    if (!(name %in% names(attributes(x)$properties))) {
        stop(sprintf("Property '%s' does not exist", name), call. = FALSE)
    }

    value <- get(name, envir = x, inherits = FALSE)

    if (attr(x, "validate_on_access")) {
        validate_property(name, value, attributes(x)$properties[[name]])
    }

    return(value)
}

#' Set a property in an interface object
#'
#' @param x An interface object
#' @param name The name of the property to set
#' @param value The new value for the property
#' @return The modified interface object, invisibly.
#' @export
`$<-.interface_object` <- function(x, name, value) {
    if (!(name %in% names(attributes(x)$properties))) {
        stop(sprintf("Property '%s' does not exist", name), call. = FALSE)
    }

    error <- validate_property(name, value, attributes(x)$properties[[name]])
    if (!is.null(error)) {
        stop(error, call. = FALSE)
    }

    assign(name, value, envir = x)
    return(x)
}

#' Print method for interface objects
#'
#' @param x An object implementing an interface
#' @param ... Additional arguments (not used)
#' @return No return value, called for side effects.
#'         Prints a human-readable representation of the interface object to the console.
#' @export
print.interface_object <- function(x, ...) {
    cat("Object implementing interface:\n")
    for (name in names(attributes(x)$properties)) {
        cat(sprintf("  %s: %s\n", name, format(x[[name]])))
    }
    cat(sprintf(
        "Validation on access: %s\n", ifelse(attr(x, "validate_on_access"), "Enabled", "Disabled"
    )))
}