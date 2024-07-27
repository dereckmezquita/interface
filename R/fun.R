#' Create a typed function
#'
#' @param args A list of argument names and their expected types
#' @param return The expected return type(s)
#' @param impl The function implementation
#' @return A typed function
#' @export
fun <- function(args, return, impl) {
  force(args)
  force(return)
  force(impl)

  typed_fun <- function(...) {
    call_args <- list(...)
    
    # Validate input arguments
    for (arg_name in names(args)) {
      if (!(arg_name %in% names(call_args))) {
        stop(sprintf("Missing required argument: %s", arg_name), call. = FALSE)
      }
      
      arg_value <- call_args[[arg_name]]
      arg_type <- args[[arg_name]]
      
      error <- validate_property(arg_name, arg_value, arg_type)
      if (!is.null(error)) {
        stop(error, call. = FALSE)
      }
    }
    
    # Call the implementation
    result <- do.call(impl, call_args)
    
    # Validate return value
    error <- validate_property("return", result, return)
    if (!is.null(error)) {
      stop(error, call. = FALSE)
    }
    
    result
  }
  
  structure(typed_fun,
            class = c("typed_function", "function"),
            args = args,
            return = return,
            impl = impl)
}

#' Print method for typed functions
#'
#' @param x A typed function
#' @param ... Additional arguments (not used)
#' @export
print.typed_function <- function(x, ...) {
  cat("Typed function:\n")
  cat("Arguments:\n")
  for (name in names(attr(x, "args"))) {
    cat(sprintf("  %s: %s\n", name, format(attr(x, "args")[[name]])))
  }
  cat(sprintf("Return type: %s\n", format(attr(x, "return"))))
}