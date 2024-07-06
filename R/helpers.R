# Helper function to check if a value matches a type specification
check_type <- function(value, type_spec) {
    if (identical(type_spec, "ANY")) {
        return(TRUE)
    } else if (inherits(type_spec, "Interface")) {
        return(check_interface(value, type_spec))
    } else if (is.character(type_spec)) {
        if (type_spec %in% c("numeric", "integer", "logical", "character", "list")) {
            return(inherits(value, type_spec))
        } else {
            stop(sprintf("Unsupported character type specification: %s", type_spec))
        }
    } else if (is.function(type_spec)) {
        tryCatch(
            {
                result <- type_spec(value)
                if (!is.logical(result) || length(result) != 1) {
                    stop("Custom type check function must return a single logical value")
                }
                return(result)
            },
            error = function(e) {
                stop(sprintf("Error in custom type check function: %s", e$message))
            }
        )
    } else {
        stop(sprintf("Unsupported type specification: %s", class(type_spec)[1]))
    }
}

# Helper function to check if a value implements an interface
check_interface <- function(value, interface) {
    if (!is.list(value)) {
        return(FALSE)
    }
    all(names(interface$properties) %in% names(value)) &&
        all(mapply(check_type, value[names(interface$properties)], interface$properties))
}

# Validation function
validate_object <- function(obj, interface) {
    for (prop in names(interface$properties)) {
        expected_type <- interface$properties[[prop]]
        actual_value <- obj[[prop]]

        if (!check_type(actual_value, expected_type)) {
            stop(sprintf("Property '%s' does not match the expected type specification", prop))
        }
    }
    return(TRUE)
}

# Custom accessor function
custom_accessor <- function(x, i) {
    validate_object(x, attr(x, "interface"))
    x[[i]]
}
