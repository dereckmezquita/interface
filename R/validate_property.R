#' Validate a property against a given type or validation function
#'
#' @description
#' Validates a property to ensure it matches the expected type or satisfies the given validation function.
#'
#' @param name The name of the property being validated.
#' @param value The value of the property.
#' @param validator The expected type or a custom validation function.
#' @return NULL if the validation passes, otherwise an error message.
#'
validate_property <- function(name, value, validator) {
    if (is.list(validator) && !is.function(validator)) {
        # Multiple allowed types
        for (v in validator) {
            error <- validate_property(name, value, v)
            if (is.null(error)) return(NULL)
        }
        return(sprintf("Property '%s' does not match any of the allowed types", name))
    } else if (inherits(validator, "interface")) {
        if (!inherits(value, "interface_object") || !identical(attr(value, "properties"), attr(validator, "properties"))) {
            return(sprintf("Property '%s' must be an object implementing the specified interface", name))
        }
    } else if (inherits(validator, "enum_generator")) {
        if (!inherits(value, "enum") || !value$value %in% attr(validator, "values")) {
            return(sprintf("Property '%s' must be one of the enum values: %s", name, paste(attr(validator, "values"), collapse = ", ")))
        }
    } else if (is.function(validator)) {
        if (identical(validator, character)) {
            if (!is.character(value)) {
                return(sprintf("Property '%s' must be of type character", name))
            }
        } else if (identical(validator, numeric)) {
            if (!is.numeric(value)) {
                return(sprintf("Property '%s' must be of type numeric", name))
            }
        } else if (identical(validator, logical)) {
            if (!is.logical(value)) {
                return(sprintf("Property '%s' must be of type logical", name))
            }
        } else if (identical(validator, integer)) {
            if (!is.integer(value)) {
                return(sprintf("Property '%s' must be of type integer", name))
            }
        } else if (identical(validator, double)) {
            if (!is.double(value)) {
                return(sprintf("Property '%s' must be of type double", name))
            }
        } else if (identical(validator, complex)) {
            if (!is.complex(value)) {
                return(sprintf("Property '%s' must be of type complex", name))
            }
        } else if (identical(validator, data.table::data.table)) {
            if (!data.table::is.data.table(value)) {
                return(sprintf("Property '%s' must be a data.table", name))
            }
        } else {
            # Custom validator function
            validation_result <- validator(value)
            if (!isTRUE(validation_result)) {
                return(sprintf("Invalid value for property '%s': %s", name, as.character(validation_result)))
            }
        }
    } else if (is.character(validator)) {
        if (!inherits(value, validator)) {
            return(sprintf("Property '%s' must be of type %s, but got %s", name, validator, class(value)[1]))
        }
    } else {
        return(sprintf("Invalid validator for property '%s'", name))
    }

    return(NULL)
}