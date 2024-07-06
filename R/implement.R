#' Implement an Interface
#'
#' @param interface An Interface object
#' @param ... Properties to implement the interface
#' @param validate_on_access Logical, whether to validate on access
#'
#' @return An object implementing the interface
#' @export
implement <- function(interface, ..., validate_on_access = NULL) {
    obj <- list(...)

    # Check if all required properties are present
    missing_props <- setdiff(names(interface$properties), names(obj))
    if (length(missing_props) > 0) {
        stop(paste("Missing properties:", paste(missing_props, collapse = ", ")))
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

    # Only add validated_list if required
    if (validate_on_access) {
        classes <- c("validated_list", classes)
    }

    # Return the object as a simple list with appropriate class and attributes
    structure(
        obj,
        class = classes,
        interface = interface,
        validate_on_access = if (validate_on_access) TRUE else NULL
    )
}

#' @export
`$.validated_list` <- custom_accessor
