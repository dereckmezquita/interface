# Define the Interface class
Interface <- function(interface_name, properties) {
  structure(list(interface_name = interface_name, properties = properties), class = "Interface")
}

# Function to create an interface
interface <- function(interface_name, ...) {
  Interface(interface_name, list(...))
}

# Helper function to check if a value matches a type specification
check_type <- function(value, type_spec) {
  if (identical(type_spec, "ANY")) {
    return(TRUE)
  } else if (inherits(type_spec, "Interface")) {
    return(check_interface(value, type_spec))
  } else if (is.character(type_spec)) {
    return(inherits(value, type_spec))
  } else if (is.function(type_spec)) {
    return(type_spec(value))
  } else {
    stop("Unsupported type specification")
  }
}

# Helper function to check if a value implements an interface
check_interface <- function(value, interface) {
  if (!is.list(value)) return(FALSE)
  all(names(interface$properties) %in% names(value)) &&
    all(mapply(check_type, value[names(interface$properties)], interface$properties))
}

# Function to create an object that implements an interface
implement <- function(interface, ...) {
  obj <- list(...)

  # Check if all required properties are present
  missing_props <- setdiff(names(interface$properties), names(obj))
  if (length(missing_props) > 0) {
    stop(paste("Missing properties:", paste(missing_props, collapse = ", ")))
  }
  
  # Check types of properties
  type_errors <- character()
  for (prop in names(interface$properties)) {
    expected_type <- interface$properties[[prop]]
    actual_value <- obj[[prop]]
    
    if (!check_type(actual_value, expected_type)) {
      type_errors <- c(
        type_errors,
        sprintf("Property '%s' does not match the expected type specification", prop)
      )
    }
  }

  if (length(type_errors) > 0) {
    stop(paste("Type mismatch errors:", paste(type_errors, collapse = "\n"), sep = "\n"))
  }

  # Return the object as a simple list
  structure(obj, class = c(paste0(interface$interface_name, "Implementation"), "list"))
}

# Example usage
# Define interfaces
Person <- interface("Person",
  name = "character",
  age = "numeric",
  email = "character"
)

# Define an interface that uses another interface and includes an "any" type
Employee <- interface("Employee",
  person = Person,
  job_title = "character",
  salary = "numeric",
  tasks = "list",
  additional_info = "ANY"  # This can be any type
)

# Create objects implementing the interfaces
john <- implement(Person,
  name = "John Doe",
  age = 30,
  email = "john@example.com"
)

jane <- implement(Employee,
  person = john,
  job_title = "Manager",
  salary = 50000,
  tasks = list("Task 1", "Task 2"),
  additional_info = data.frame(skill = c("Leadership", "Communication"), level = c(9, 8))
)

class(jane)
is.list(jane)

# Example with custom validation function
positiveNumber <- function(x) {
  return(is.numeric(x) && x > 0)
}

Account <- interface("Account",
  id = "character",
  balance = positiveNumber,
  metadata = "ANY"  # This can be any type
)

my_account <- implement(Account,
  id = "ACC123",
  balance = 1000,
  metadata = list(created_at = Sys.time(), last_transaction = "2023-07-01")
)

# Accessing properties
print(john$name)  # Should print "John Doe"
print(jane$person$name)  # Should print "John Doe"
print(jane$additional_info)  # Should print the data frame
print(my_account$balance)  # Should print 1000
print(my_account$metadata)  # Should print the list

# This would raise an error with type mismatches
try(implement(Person,
  name = 123,  # Should be character
  age = "thirty",  # Should be numeric
  email = TRUE  # Should be character
))