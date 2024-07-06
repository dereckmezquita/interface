# Define a macro-like function that will process the typed function definition
function2 <- function(func) {
    func_info <- extract_function_info(func)

    wrapped_func <- function(...) {
        args <- list(...)

        # Check argument types
        mapply(function(arg, name, type) {
            if (!check_type(arg, type)) {
                stop(sprintf("Argument '%s' does not match the expected type: %s", name, type))
            }
        }, args, names(func_info$args), func_info$args)

        # Call the original function
        result <- do.call(func_info$body, args)

        # Check return type if specified
        if (!is.null(func_info$return_type) && !check_type(result, func_info$return_type)) {
            stop(sprintf("Return value does not match the expected type: %s", func_info$return_type))
        }

        return(result)
    }

    return(wrapped_func)
}

# Helper function to extract function information
extract_function_info <- function(func) {
    func_text <- deparse(func)

    # Extract argument types
    args_pattern <- "^function\\((.*?)\\)"
    args_match <- regexec(args_pattern, func_text[1])
    args_text <- regmatches(func_text[1], args_match)[[1]][2]
    args_list <- strsplit(args_text, ",")[[1]]
    args <- setNames(lapply(args_list, function(arg) {
        parts <- strsplit(trimws(arg), "=")[[1]]
        trimws(parts[2])
    }), sapply(args_list, function(arg) trimws(strsplit(arg, "=")[[1]][1])))

    # Extract function body
    body_text <- paste(func_text[-1], collapse = "\n")
    body_expr <- parse(text = body_text)

    # Extract return type if specified
    return_type <- NULL
    if (grepl("^\\s*return\\(", body_text)) {
        return_match <- regexec("return\\((.*?)\\)", body_text)
        return_text <- regmatches(body_text, return_match)[[1]][2]
        if (grepl("::", return_text)) {
            return_parts <- strsplit(return_text, "::")[[1]]
            return_type <- trimws(return_parts[2])
        }
    }

    list(args = args, body = body_expr, return_type = return_type)
}

# Usage
check_name_shorter_than <- function2(\(name = "character", maxLength = "numeric") {
    if (nchar(name) > maxLength) {
        stop("Name is too long")
    }
    return(TRUE)
})

# Test the function
check_name_shorter_than("John", 5) # Should return TRUE
try(check_name_shorter_than("Alexander", 5)) # Should throw an error
try(check_name_shorter_than(123, 5)) # Should throw a type error
