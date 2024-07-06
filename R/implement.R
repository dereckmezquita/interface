#' Implement an Interface
#'
#' @param interface An Interface object
#' @param ... Properties to implement the interface
#' @param validate_on_access Logical, whether to validate on access
#'
#' @return An object implementing the interface
#' @export
implement <- function(interface, ..., validate_on_access = NULL, allow_extra = FALSE) {
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
    classes <- c(class_name, "InterfaceImplementation", "list")

    if (validate_on_access) {
        classes <- c("validated_list", classes)
    }

    # Return the object with appropriate class and attributes
    return(structure(
        obj,
        class = classes,
        interface = interface,
        validate_on_access = if (validate_on_access) TRUE else NULL,
        allow_extra = allow_extra
    ))
}

#' @export
`$.validated_list` <- custom_accessor
