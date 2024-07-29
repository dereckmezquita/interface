modify_user_function <- function(user_fun) {
  body(user_fun) <- bquote({
    all(.(body(user_fun)))
  })
  return(user_fun)
}

# Example user functions
example_fun1 <- function(value) value > 0
example_fun2 <- function(x) x %% 2 == 0
example_fun3 <- function(y) y >= 10 & y <= 20

# Modify the functions
modified_fun1 <- modify_user_function(example_fun1)
modified_fun2 <- modify_user_function(example_fun2)
modified_fun3 <- modify_user_function(example_fun3)

# unmodified functions; returns logical vectors
print(example_fun1(c(-1, 0, 1, 2)))
print(example_fun2(c(2, 4, 6, 8)))
print(example_fun3(c(5, 15, 25)))

# Test the modified functions
print(modified_fun1(c(-1, 0, 1, 2)))  # FALSE
print(modified_fun2(c(2, 4, 6, 8)))   # TRUE
print(modified_fun3(c(5, 15, 25)))    # FALSE

# They still work with single values too
print(modified_fun1(5))  # TRUE
print(modified_fun2(3))  # FALSE
print(modified_fun3(15)) # TRUE
