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
    classes <- c(class_name, "list")
    attrs <- list(interface = interface)

    # Only add validation if required
    if (validate_on_access) {
        classes <- c("validated_list", classes)
        attrs$validate_on_access <- TRUE
    }

    # Return the object as a simple list with appropriate class and attributes
    return(structure(
        obj,
        class = classes, 
        interface = interface,
        validate_on_access = if(validate_on_access) TRUE else NULL
    ))
}
