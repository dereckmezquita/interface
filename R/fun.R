#' Create a typed function
#'
#' @description
#' Defines a function with specified parameter types and return type. Ensures that the function's arguments and return value adhere to the specified types.
#'
#' @param ... Named arguments defining the function parameters and their types, including 'return' for the expected return type(s) and 'impl' for the function implementation.
#' @return A function of class 'typed_function' that enforces type constraints on its parameters and return value.
#'         The returned function has the same signature as the implementation function provided in the 'impl' argument.
#' @details
#' The `fun` function allows you to define a function with strict type checking for its parameters and return value. 
#' This ensures that the function receives arguments of the correct types and returns a value of the expected type.
#' The 'return' and 'impl' arguments should be included in the ... parameter list.
#'
#' @examples
#' # Define a typed function that adds two numbers
#' add_numbers <- fun(
#'   x = numeric,
#'   y = numeric,
#'   return = numeric,
#'   impl = function(x, y) {
#'     return(x + y)
#'   }
#' )
#'
#' # Valid call
#' print(add_numbers(1, 2))  # [1] 3
#'
#' # Invalid call (throws error)
#' try(add_numbers("a", 2))
#'
#' # Define a typed function with multiple return types
#' concat_or_add <- fun(
#'   x = c(numeric, character),
#'   y = numeric,
#'   return = c(numeric, character),
#'   impl = function(x, y) {
#'     if (is.numeric(x)) {
#'       return(x + y)
#'     } else {
#'       return(paste(x, y))
#'     }
#'   }
#' )
#'
#' # Valid calls
#' print(concat_or_add(1, 2))     # [1] 3
#' print(concat_or_add("a", 2))   # [1] "a 2"
#' @export
fun <- function(...) {
    args <- list(...)
    return_type <- args$return
    impl <- args$impl

    # Remove 'return' and 'impl' from args
    args$return <- NULL
    args$impl <- NULL

    if (is.null(return_type) || is.null(impl)) {
        stop("Both 'return' and 'impl' must be specified", call. = FALSE)
    }

    typed_fun <- function(...) {
        call_args <- list(...)

        # Validate input arguments
        for (arg_name in names(args)) {
            if (arg_name %in% names(call_args)) {
                arg_value <- call_args[[arg_name]]
                arg_type <- args[[arg_name]]

                error <- validate_property(arg_name, arg_value, arg_type)
                if (!is.null(error)) {
                    stop(error, call. = FALSE)
                }
            } else if (length(call_args) >= which(names(args) == arg_name)) {
                # If the argument wasn't named, but a value was provided in the correct position
                arg_value <- call_args[[which(names(args) == arg_name)]]
                arg_type <- args[[arg_name]]

                error <- validate_property(arg_name, arg_value, arg_type)
                if (!is.null(error)) {
                    stop(error, call. = FALSE)
                }
            } else {
                stop(sprintf("Missing required argument: %s", arg_name), call. = FALSE)
            }
        }

        # Call the implementation
        result <- do.call(impl, call_args)

        # Validate return value
        error <- validate_property("return", result, return_type)
        if (!is.null(error)) {
            stop(error, call. = FALSE)
        }

        result
    }

    # Create the structure explicitly
    return(structure(
        typed_fun,
        class = c("typed_function", "function"),
        args = args,
        return = return_type,
        impl = impl
    ))
}

#' Print method for typed functions
#'
#' @description
#' Provides a custom print method for typed functions, displaying their parameter types and return type.
#'
#' @param x A typed function.
#' @param ... Additional arguments (not used).
#' @return No return value, called for side effects.
#'         Prints a human-readable representation of the typed function to the console,
#'         showing the argument types and return type.
#' @export
print.typed_function <- function(x, ...) {
    cat("Typed function:\n")
    cat("Arguments:\n")
    for (name in names(attr(x, "args"))) {
        cat(sprintf("  %s: %s\n", name, format(attr(x, "args")[[name]])))
    }
    cat(sprintf("Return type: %s\n", format(attr(x, "return"))))
}