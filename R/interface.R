#' Create an Interface
#'
#' @param interface_name A character string naming the interface
#' @param ... Property definitions for the interface
#' @param validate_on_access Logical, whether to validate on access by default
#'
#' @return An Interface object
#' @export
interface <- function(interface_name, ..., validate_on_access = FALSE) {
    properties <- list(...)
    return(structure(list(
        interface_name = interface_name,
        properties = properties,
        validate_on_access = validate_on_access
    ), class = "Interface"))
}

#' Internal function to create an Interface object
#'
#' @param interface_name A character string naming the interface
#' @param properties A list of property definitions
#' @param validate_on_access Logical, whether to validate on access by default
#'
#' @return An Interface object
#' @keywords internal
Interface <- function(interface_name, properties, validate_on_access = FALSE) {
    return(structure(list(
        interface_name = interface_name,
        properties = properties,
        validate_on_access = validate_on_access
    ), class = "Interface"))
}
