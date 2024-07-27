#' Define an interface
#'
#' @description
#' An interface defines a structure with specified properties and their types or validation functions. 
#' This is useful for ensuring that objects adhere to a particular format and type constraints.
#'
#' @param ... Named arguments defining the properties and their types or validators.
#' @param validate_on_access Logical, whether to validate properties on access (default: FALSE).
#' @param extends List of interfaces to extend (default: empty list).
#' @return A function to create objects that implement the defined interface.
#' @export
interface <- function(..., validate_on_access = FALSE, extends = list()) {
    properties <- list(...)

    # Process in-place declarations
    for (name in names(properties)) {
        if (is.function(properties[[name]]) && identical(properties[[name]], enum)) {
            # Handle in-place enum declarations
            properties[[name]] <- do.call(enum, list())
        } else if (is.function(properties[[name]]) && identical(properties[[name]], interface)) {
            # Handle in-place nested interface declarations
            properties[[name]] <- do.call(interface, list())
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

            if (inherits(validator, "enum_type")) {
                error <- tryCatch({
                    obj[[name]] <- validator(value)
                    NULL
                }, error = function(e) {
                    return(sprintf("Invalid value for property '%s': %s", name, e$message))
                })
            } else {
                error <- validate_property(name, value, validator)
                if (is.null(error)) {
                    obj[[name]] <- value
                }
            }

            if (!is.null(error)) {
                errors <- c(errors, error)
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
#' @export
`$<-.interface_object` <- function(x, name, value) {
    if (!(name %in% names(attributes(x)$properties))) {
        stop(sprintf("Property '%s' does not exist", name), call. = FALSE)
    }

    validator <- attributes(x)$properties[[name]]

    if (inherits(validator, "enum_type")) {
        error <- tryCatch({
            x[[name]] <- validator(value)
            NULL
        }, error = function(e) {
            return(sprintf("Invalid value for property '%s': %s", name, e$message))
        })
    } else {
        error <- validate_property(name, value, validator)
    }

    if (!is.null(error)) {
        stop(error, call. = FALSE)
    }

    if (is.null(error)) {
        assign(name, value, envir = x)
    }
    return(x)
}

#' Print method for interface objects
#'
#' @param x An object implementing an interface
#' @param ... Additional arguments (not used)
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