# Define the Interface class
Interface <- function(interface_name, properties, validate_on_access = FALSE) {
    return(structure(list(
        interface_name = interface_name,
        properties = properties,
        validate_on_access = validate_on_access
    ), class = "Interface"))
}

# Function to create an interface
interface <- function(interface_name, ..., validate_on_access = FALSE) {
    properties <- list(...)
    return(Interface(interface_name, properties, validate_on_access))
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
    if (!is.list(value)) {
        return(FALSE)
    }
    return(
        all(names(interface$properties) %in% names(value)) &&
        all(mapply(check_type, value[names(interface$properties)], interface$properties))
    )
}

# Validation function
validate_object <- function(obj, interface) {
    print("Validating object")
    for (prop in names(interface$properties)) {
        expected_type <- interface$properties[[prop]]
        actual_value <- obj[[prop]]
        
        if (!check_type(actual_value, expected_type)) {
            stop(sprintf("Property '%s' does not match the expected type specification", prop))
        }
    }
    return(TRUE)
}

# Custom accessor function
custom_accessor <- function(x, i) {
    if (isTRUE(attr(x, "validate_on_access"))) {
        return(validate_object(x, attr(x, "interface")))
    }
    return(x[[i]])
}

# Function to create an object that implements an interface
implement <- function(interface, ..., validate_on_access = NULL) {
    obj <- list(...)

    # Check if all required properties are present
    missing_props <- setdiff(names(interface$properties), names(obj))
    if (length(missing_props) > 0) {
        stop(paste("Missing properties:", paste(missing_props, collapse = ", ")))
    }
    
    # Initial validation
    validate_object(obj, interface)

    # Determine validate_on_access value
    if (is.null(validate_on_access)) {
        validate_on_access <- interface$validate_on_access
    }

    # Return the object as a simple list with custom class and attributes
    return(structure(
        obj,
        class = c(paste0(interface$interface_name, "Implementation"), "validated_list", "list"),
        interface = interface,
        validate_on_access = validate_on_access
    ))
}

# Define custom `$` method for our objects
`$.validated_list` <- custom_accessor

# Example usage
# Define interfaces
Person <- interface("Person",
    name = "character",
    age = "numeric",
    email = "character",
    validate_on_access = TRUE  # Set default validation for Person
)

# Define an interface that uses another interface and includes an "any" type
Employee <- interface("Employee",
    person = Person,
    job_title = "character",
    salary = "numeric",
    tasks = "list",
    additional_info = "ANY",  # This can be any type
    validate_on_access = FALSE  # Set default validation for Employee
)

# Create objects implementing the interfaces
john <- implement(Person,
    name = "John Doe",
    age = 30,
    email = "john@example.com"
    # validate_on_access is not specified, so it will use the interface default (TRUE)
)

jane <- implement(Employee,
    person = john,
    job_title = "Manager",
    salary = 50000,
    tasks = list("Task 1", "Task 2"),
    additional_info = data.frame(skill = c("Leadership", "Communication"), level = c(9, 8)),
    validate_on_access = TRUE  # Override the interface default
)

# Accessing properties (this will trigger validation for john, but not for jane)
print(john$name)  # Should print "John Doe" and trigger validation
print(jane$job_title)  # Should print "Manager" and trigger validation (due to override)

# Try to modify the object in a way that violates the interface
john$age <- "thirty"  # This should not cause an immediate error

# But when we try to access any property, it will trigger validation and raise an error
try(print(john$name))

# Create an object explicitly without validation on access
my_account <- implement(Account,
    id = "ACC123",
    balance = 1000,
    metadata = list(created_at = Sys.time(), last_transaction = "2023-07-01"),
    validate_on_access = FALSE
)

# This won't trigger validation
my_account$balance <- "Invalid"
print(my_account$balance)  # This will print "Invalid" without raising an error