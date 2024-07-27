library(rlang)

# Helper function to check types
check_type <- function(value, type) {
  switch(as.character(type),
    "numeric" = is.numeric(value),
    "character" = is.character(value),
    "logical" = is.logical(value),
    "ANY" = TRUE,
    FALSE
  )
}

# Define the function2 macro
function2 <- function(func_expr, return_type) {
  func_expr <- enexpr(func_expr)
  return_type <- enexpr(return_type)
  
  # Extract function arguments and body
  func_args <- func_expr[[2]]
  func_body <- func_expr[[3]]
  
  # Process arguments
  arg_list <- as.list(func_args)[-1]  # Remove 'function' symbol
  processed_args <- lapply(arg_list, function(arg) {
    if (is.call(arg) && identical(arg[[1]], as.name(":"))) {
      name <- as.character(arg[[2]])
      type <- as.character(arg[[3]])
      default <- if (length(arg) > 3) arg[[4]] else NULL
      list(name = name, type = type, default = default)
    } else if (is.name(arg)) {
      list(name = as.character(arg), type = "ANY", default = NULL)
    } else {
      stop("Invalid argument specification")
    }
  })
  
  arg_names <- sapply(processed_args, `[[`, "name")
  arg_types <- sapply(processed_args, `[[`, "type")
  arg_defaults <- lapply(processed_args, `[[`, "default")
  
  # Create the original function
  orig_func <- eval(call("function", as.pairlist(setNames(arg_defaults, arg_names)), func_body))
  
  # Wrap the function with type checking
  wrapped_func <- function(...) {
    args <- list(...)
    
    # Check argument types
    mapply(function(arg, name, type) {
      if (!check_type(arg, type)) {
        stop(sprintf("Argument '%s' does not match the expected type: %s", name, type))
      }
    }, args, arg_names, arg_types)
    
    # Call the original function
    result <- do.call(orig_func, args)
    
    # Check return type
    if (!check_type(result, return_type)) {
      stop(sprintf("Return value does not match the expected type: %s", return_type))
    }
    
    return(result)
  }
  
  # Set the formals of the wrapped function to match the original function
  formals(wrapped_func) <- formals(orig_func)
  
  return(wrapped_func)
}

# Usage
can_play_basketball <- function2(function(age: numeric, height: numeric = 150) {
  if (age < 18) {
    return(FALSE)
  }
  if (height < 150) {
    return(FALSE)
  }
  return(TRUE)
}, logical)

# Test the function
print(can_play_basketball(20, 180))  # Should return TRUE
print(can_play_basketball(20))  # Should use default height of 150
try(print(can_play_basketball(15, 160)))  # Should return FALSE
try(print(can_play_basketball("20", 180)))  # Should throw a type error
