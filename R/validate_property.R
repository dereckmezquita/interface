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
      validation_result <- vapply(value, validator, logical(1))
      if (!all(validation_result)) {
        invalid_indices <- which(!validation_result)
        return(sprintf("Invalid value(s) for property '%s' at index(es): %s", name, paste(invalid_indices, collapse = ", ")))
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

#' Validate a property
#'
#' @param name The name of the property
#' @param value The value to validate
#' @param validator The validator function or specification
#' @return NULL if valid, otherwise a character string describing the error
validate_property_old <- function(name, value, validator) {
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
