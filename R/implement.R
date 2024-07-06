#' Implement an Interface
#'
#' @param interface An Interface object
#' @param ... Properties to implement the interface
#' @param validate_on_access Logical, whether to validate on access
#' @param allow_extra Logical, whether to allow extra properties not defined in the interface
#'
#' @return An object implementing the interface
#' @export
implement <- function(interface, ..., validate_on_access = TRUE, allow_extra = FALSE) {
    obj <- list(...)

    # Check if all required properties are present and not NULL
    missing_props <- setdiff(names(interface$properties), names(obj))
    null_props <- names(obj)[vapply(obj, is.null, logical(1))]
    if (length(missing_props) > 0 || length(null_props) > 0) {
        stop(paste(
            "Missing or NULL properties:",
            paste(c(missing_props, null_props), collapse = ", ")
        ))
    }

    # Remove extra properties if not allowed
    if (!allow_extra) {
        extra_props <- setdiff(names(obj), names(interface$properties))
        if (length(extra_props) > 0) {
            obj <- obj[names(interface$properties)]
            warning(paste("Removed extra properties:", paste(extra_props, collapse = ", ")))
        }
    }

    # Initial validation
    validate_object(obj, interface)

    # Determine validate_on_access value
    if (is.null(validate_on_access)) {
        validate_on_access <- interface$validate_on_access
    }

    # Prepare class and attributes
    class_name <- paste0(interface$interface_name, "Implementation")
    classes <- c("validated_list", class_name, "InterfaceImplementation")

    # Return the object with appropriate class and attributes
    return(structure(
        obj,
        class = classes,
        interface = interface,
        validate_on_access = validate_on_access,
        allow_extra = allow_extra
    ))
}

#' Custom accessor for validated_list objects
#'
#' @param x The validated_list object
#' @param i The name of the property to access
#'
#' @return The value of the property
#' @export
`$.validated_list` <- function(x, i) {
    if (isTRUE(attr(x, "validate_on_access"))) {
        validate_object(x, attr(x, "interface"))
    }
    return(x[[i]])
}

#' Custom assignment for validated_list objects
#'
#' @param x The validated_list object
#' @param i The name of the property to assign
#' @param value The value to assign
#'
#' @return The updated validated_list object
#' @export
`$<-.validated_list` <- function(x, i, value) {
    interface <- attr(x, "interface")
    if (i %in% names(interface$properties)) {
        expected_type <- interface$properties[[i]]
        if (!check_type(value, expected_type)) {
            stop(sprintf("Property '%s' does not match the expected type specification", i))
        }
    } else if (!isTRUE(attr(x, "allow_extra"))) {
        stop(sprintf("Cannot add new property '%s' to the object", i))
    }
    x[[i]] <- value
    return(x)
}
