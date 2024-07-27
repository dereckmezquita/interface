#' Create an interface
#'
#' @param ... Named arguments defining the interface properties and their types
#' @param validate_on_access Logical, whether to validate on access (default: TRUE)
#' @param extends List of interfaces that this interface extends
#' @return A function that creates objects implementing the interface
#' @export
interface <- function(..., validate_on_access = FALSE, extends = list()) {
  properties <- list(...)
  
  # Merge properties from extended interfaces
  all_properties <- properties
  for (ext in extends) {
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
      
      error <- validate_property(name, value, validator)
      if (!is.null(error)) {
        errors <- c(errors, error)
      } else {
        obj[[name]] <- value
      }
    }

    if (length(errors) > 0) {
      error_message <- paste("Errors occurred during interface creation:", 
                             paste(errors, collapse = "\n  - "), 
                             sep = "\n  - ")
      stop(error_message, call. = FALSE)
    }
    
    structure(obj,
              class = c("interface_object", "environment"),
              properties = all_properties,
              validate_on_access = validate_on_access)
  }
  
  structure(creator,
            class = "interface",
            properties = all_properties,
            validate_on_access = validate_on_access,
            extends = extends)
}

#' Validate a property
#'
#' @param name The name of the property
#' @param value The value to validate
#' @param validator The validator function or specification
#' @return NULL if valid, otherwise a character string describing the error
validate_property <- function(name, value, validator) {
  if (inherits(validator, "interface")) {
    if (!inherits(value, "interface_object") || !identical(attr(value, "properties"), attr(validator, "properties"))) {
      return(sprintf("Property '%s' must be an object implementing the specified interface", name))
    }
  } else if (identical(validator, character) || identical(validator, "character")) {
    if (!is.character(value)) {
      return(sprintf("Property '%s' must be a character string", name))
    }
  } else if (identical(validator, numeric) || identical(validator, "numeric")) {
    if (!is.numeric(value)) {
      return(sprintf("Property '%s' must be a numeric value", name))
    }
  } else if (identical(validator, logical) || identical(validator, "logical")) {
    if (!is.logical(value)) {
      return(sprintf("Property '%s' must be a logical value", name))
    }
  } else if (identical(validator, data.frame) || identical(validator, "data.frame")) {
    if (!is.data.frame(value)) {
      return(sprintf("Property '%s' must be a data.frame", name))
    }
  } else if (identical(validator, data.table::data.table) || identical(validator, "data.table")) {
    if (!inherits(value, "data.table")) {
      return(sprintf("Property '%s' must be a data.table", name))
    }
  } else if (identical(validator, matrix) || identical(validator, "matrix")) {
    if (!is.matrix(value)) {
      return(sprintf("Property '%s' must be a matrix", name))
    }
  } else if (is.function(validator)) {
    if (!validator(value)) {
      return(sprintf("Invalid value for property '%s'", name))
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
  
  value
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

  error <- validate_property(name, value, attributes(x)$properties[[name]])
  if (!is.null(error)) {
    stop(error, call. = FALSE)
  }

  assign(name, value, envir = x)
  x
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
  cat(sprintf("Validation on access: %s\n", 
              ifelse(attr(x, "validate_on_access"), "Enabled", "Disabled")))
}