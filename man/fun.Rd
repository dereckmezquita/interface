% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fun.R
\name{fun}
\alias{fun}
\title{Create a typed function}
\usage{
fun(...)
}
\arguments{
\item{...}{Named arguments defining the function parameters and their types, including 'return' for the expected return type(s) and 'impl' for the function implementation.}
}
\value{
A function of class 'typed_function' that enforces type constraints on its parameters and return value.
        The returned function has the same signature as the implementation function provided in the 'impl' argument.
}
\description{
Defines a function with specified parameter types and return type. Ensures that the function's arguments and return value adhere to the specified types.
}
\details{
The `fun` function allows you to define a function with strict type checking for its parameters and return value. 
This ensures that the function receives arguments of the correct types and returns a value of the expected type.
The 'return' and 'impl' arguments should be included in the ... parameter list.
}
\examples{
# Define a typed function that adds two numbers
add_numbers <- fun(
  x = numeric,
  y = numeric,
  return = numeric,
  impl = function(x, y) {
    return(x + y)
  }
)

# Valid call
print(add_numbers(1, 2))  # [1] 3

# Invalid call (throws error)
try(add_numbers("a", 2))

# Define a typed function with multiple return types
concat_or_add <- fun(
  x = c(numeric, character),
  y = numeric,
  return = c(numeric, character),
  impl = function(x, y) {
    if (is.numeric(x)) {
      return(x + y)
    } else {
      return(paste(x, y))
    }
  }
)

# Valid calls
print(concat_or_add(1, 2))     # [1] 3
print(concat_or_add("a", 2))   # [1] "a 2"
}
