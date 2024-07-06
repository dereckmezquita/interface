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
    validate_object(x, attr(x, "interface"))
    return(x[[i]])
}

# Custom print method for implemented interface objects
print.InterfaceImplementation <- function(x, ...) {
    interface <- attr(x, "interface")
    cat("Object implementing", interface$interface_name, "interface:\n")
    for (prop in names(x)) {
        cat(sprintf("  %s: ", prop))
        if (is.atomic(x[[prop]]) && length(x[[prop]]) == 1) {
            cat(x[[prop]], "\n")
        } else if (inherits(x[[prop]], "InterfaceImplementation")) {
            cat("<", class(x[[prop]])[1], ">\n", sep = "")
        } else {
            cat("<", class(x[[prop]])[1], ">\n", sep = "")
        }
    }
    cat(
        "Validation on access:",
        if (isTRUE(attr(x, "validate_on_access"))) "Enabled" else "Disabled",
        "\n"
    )
    invisible(x)
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

    # Prepare class and attributes
    class_name <- paste0(interface$interface_name, "Implementation")
    classes <- c(class_name, "InterfaceImplementation", "list")

    # Only add validated_list if required
    if (validate_on_access) {
        classes <- c("validated_list", classes)
    }

    # Return the object as a simple list with appropriate class and attributes
    return(structure(
        obj,
        class = classes,
        interface = interface,
        validate_on_access = if (validate_on_access) TRUE else NULL
    ))
}

# Define custom `$` method only for validated lists
`$.validated_list` <- custom_accessor

# Custom print method for Interface objects
print.Interface <- function(x, ...) {
    cat("Interface:", x$interface_name, "\n")
    cat("Properties:\n")
    for (prop in names(x$properties)) {
        prop_type <- x$properties[[prop]]
        if (inherits(prop_type, "Interface")) {
            cat(sprintf("  %s: <Interface %s>\n", prop, prop_type$interface_name))
        } else if (is.function(prop_type)) {
            cat(sprintf("  %s: <Custom Validator>\n", prop))
        } else {
            cat(sprintf("  %s: %s\n", prop, prop_type))
        }
    }
    cat("Default validation on access:", if (x$validate_on_access) "Enabled" else "Disabled", "\n")
    invisible(x)
}

# You might also want to add a summary method for more concise output
summary.Interface <- function(object, ...) {
    cat("Interface:", object$interface_name, "\n")
    cat("Number of properties:", length(object$properties), "\n")
    cat("Default validation on access:", if (object$validate_on_access) "Enabled" else "Disabled", "\n")
    invisible(object)
}

# Example usage
# Define interfaces
Person <- interface("Person",
    name = "character",
    age = "numeric",
    email = "character",
    validate_on_access = TRUE # Set default validation for Person
)

# Define an interface that uses another interface and includes an "any" type
Employee <- interface("Employee",
    person = Person,
    job_title = "character",
    salary = "numeric",
    tasks = "list",
    additional_info = "ANY",
    validate_on_access = FALSE # Set default validation for Employee
)

# Create objects implementing the interfaces
john <- implement(Person,
    name = "John Doe",
    age = 30,
    email = "john@example.com"
)

summary(Person)
summary(john)

jane <- implement(Employee,
    person = john,
    job_title = "Manager",
    salary = 50000,
    tasks = list("Task 1", "Task 2"),
    additional_info = data.frame(skill = c("Leadership", "Communication"), level = c(9, 8))
)

# Accessing properties
print(john$name) # Should print "John Doe" and trigger validation
print(jane$job_title) # Should print "Manager" without validation

# Modify the object in a way that violates the interface
john$age <- "thirty" # This should not cause an immediate error

# This will trigger validation and raise an error
try(print(john$name))

# Create an object explicitly without validation
no_validate_person <- implement(Person,
    name = "Alice",
    age = 25,
    email = "alice@example.com",
    validate_on_access = FALSE
)

# This won't trigger validation
no_validate_person$age <- "twenty-five"
print(no_validate_person$age) # This will print "twenty-five" without raising an error
