#' Print method for InterfaceImplementation objects
#'
#' @param x The InterfaceImplementation object to print
#' @param ... Additional arguments passed to print
#'
#' @return Invisibly returns the object
#' @export
print.InterfaceImplementation <- function(x, ...) {
    interface <- attr(x, "interface")
    cat("Object implementing", interface$interface_name, "interface:\n")
    for (prop in names(x)) {
        cat(sprintf("  %s: ", prop))
        if (is.atomic(x[[prop]]) && length(x[[prop]]) == 1) {
            cat(x[[prop]], "\n")
        } else if (inherits(x[[prop]], "InterfaceImplementation")) {
            cat("<", class(x[[prop]])[1], ">\n", sep = "")
        } else {
            cat("<", class(x[[prop]])[1], ">\n", sep = "")
        }
    }
    cat(
        "Validation on access:",
        if (isTRUE(attr(x, "validate_on_access"))) "Enabled" else "Disabled",
        "\n"
    )
    invisible(x)
}

#' Print method for Interface objects
#'
#' @param x The Interface object to print
#' @param ... Additional arguments passed to print
#'
#' @return Invisibly returns the object
#' @export
print.Interface <- function(x, ...) {
    cat("Interface:", x$interface_name, "\n")
    cat("Properties:\n")
    for (prop in names(x$properties)) {
        prop_type <- x$properties[[prop]]
        if (inherits(prop_type, "Interface")) {
            cat(sprintf("  %s: <Interface %s>\n", prop, prop_type$interface_name))
        } else if (is.function(prop_type)) {
            cat(sprintf("  %s: <Custom Validator>\n", prop))
        } else {
            cat(sprintf("  %s: %s\n", prop, prop_type))
        }
    }
    cat("Default validation on access:", if (x$validate_on_access) "Enabled" else "Disabled", "\n")
    invisible(x)
}

#' Summary method for Interface objects
#'
#' @param object The Interface object to summarize
#' @param ... Additional arguments passed to summary
#'
#' @return Invisibly returns the object
#' @export
summary.Interface <- function(object, ...) {
    cat("Interface:", object$interface_name, "\n")
    cat("Number of properties:", length(object$properties), "\n")
    cat("Default validation on access:", if (object$validate_on_access) "Enabled" else "Disabled", "\n")
    invisible(object)
}
