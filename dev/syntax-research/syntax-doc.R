box::use(interface[interface, fun, type.frame, u, enum, type.list])

Colour <- enum("red", "green", "blue")
my_colour <- Colour("red")
try(Colour("yellow")) # Error: 'yellow' is not a valid value for Colour

# interface allows for arguments defining properties and types on a list object
# interface reserves some properties for internal use, such as `validate_on_access` and `extends`
# `validate_on_access` is a boolean that determines whether to validate the data on access
# `extends` is a list of interfaces that the current interface extends

# define an interface
Person <- interface(
    name = character,
    age = numeric,
    email = character
)

# implement the interface
john <- Person(
    name = "John Doe",
    age = 30,
    email = "john@example.com"
)

# access data safely
print(john_data$name)
#> [1] "John Doe"

print(john_data$scores)
#>   subject score
#> 1    Math    95
#> 2 Science    88

# This will raise an error, preventing silent issues
try(john_data$age <- "thirty")
#> Error in `$<-.validated_list`(`*tmp*`, age, value = "thirty") : 
#>   Property 'age' does not match the expected type specification

# Define a basic interface
Address <- interface(
    street = character,
    city = character,
    postal_code = character
)

# Implement the interface
home <- Address(
    street = "123 Main St",
    city = "Small town",
    postal_code = "12345"
)

print(home)
#> Object implementing Address interface:
#>   street: 123 Main St
#>   city: Small town
#>   postal_code: 12345
#> Validation on access: Enabled

# extending an interface and using nested interfaces
Student <- interface(
    extends = u(Address, Person),
    student_id = character,
    scores = data.frame,
    # here we show declaring nested interface in place
    scholarship = interface(
        amount = numeric,
        status = logical
    )
)

john_student <- Student(
    name = "John Doe",
    age = 30,
    email = "john@example.com",
    street = "123 Main St",
    city = "Small town",
    postal_code = "12345",
    student_id = "123456",
    scores = data.frame(
        subject = c("Math", "Science"),
        score = c(95, 88)
    ),
    scholarship = list(
        amount = 5000,
        status = TRUE
    )
)

# custom validation functions
is_valid_email <- function(x) {
    grepl("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", x)
}

# Interface with custom validation
UserProfile <- interface(
    username = character,
    email = is_valid_email,
    age = function(x) is.numeric(x) && x >= 18
)

# Implement with valid data
valid_user <- UserProfile(
    username = "john_doe",
    email = "john@example.com",
    age = 25
)

print(valid_user)
#> Object implementing UserProfile interface:
#>   username: john_doe 
#>   email: john@example.com 
#>   age: 25 
#> Validation on access: Enabled

# This will raise an error due to invalid email
try(UserProfile(
    username = "jane_doe",
    email = "not_an_email",
    age = "30"
))
#> Errors in validate_object(obj, interface) : 
#>   Property 'email' does not match the expected type specification
#>   Property 'age' does not match the expected type specification


# Toggle validation for performance optimisation:
Location <- interface(
    latitude = numeric,
    longitude = numeric
)

# error not thrown if validation is disabled
loc <- Location(
    latitude = "37.7749",
    longitude = -122.4194,
    validate_on_access = FALSE
)

# can turn off validation for all future objects
Location2 <- interface(
    latitude = numeric,
    longitude = numeric,
    validate_on_access = FALSE
)

loc2 <- Location2(
    latitude = "37.7749",
    longitude = -122.4194
)

# functions
typed_fun <- fun(
    args = list(
        x = numeric,
        y = numeric
    ),
    return = numeric,
    impl = function(x, y) {
        return(x + y)
    }
)

# at run time if the user inputs or a output is not of the expected type, an error will be raised
try(typed_fun("a", 2))
#> Error in typed_fun("a", 2) : Argument 'x' does not match the expected type: numeric

try(typed_fun(1, 2))
# [1] 3

# allow for multiple return types
typed_fun2 <- fun(
    args = list(
        x = u(numeric, character),
        y = numeric
    ),
    return = u(numeric, character),
    impl = function(x, y) {
        if (is.numeric(x)) {
            return(x + y)
        } else {
            return(paste(x, y))
        }
    }
)

try(typed_fun2(1, 2))
# [1] 3

try(typed_fun2("a", 2))
# [1] "a 2"

# allow for passing generics in interfaces like typescript does with interface ApiResponse<T>
# Generics
# Define a generic interface
ApiResponse <- function(T) {
    interface(
        data = T,
        status = numeric,
        message = character
    )
}

# use the generic directly
api_obj <- ApiResponse(logical)(
    data = TRUE,
    status = 200,
    message = "Data retrieved successfully"
)

print(api_obj)
#> Object implementing ApiResponse interface:
#>   data: TRUE
#>   status: 200
#>   message: Data retrieved successfully

# Use the generic interface with a specific type
UserResponse <- ApiResponse(Person)

# Implement the generic interface
user_response <- UserResponse(
    data = Person(
        name = "John Doe",
        age = 30,
        email = "john@example.com"
    ),
    status = 200,
    message = "User retrieved successfully"
)

print(user_response$data$username)
#> [1] "john_doe"

# functions with generics
GenericApiResponse <- function(T) {
    fun(
        args = list(
            data = T,
            status = numeric,
            message = character
        ),
        return = T,
        impl = function(data, status, message) {
            return(data)
        }
    )
}

# use the generic function
response <- GenericApiResponse(numeric)(
    data = 100,
    status = 200,
    message = "Data retrieved successfully"
)

## ------------------------------------------------
# dataframe and other typed objects
# Base type.frame function
PersonFrame <- type.frame(
    frame = data.frame, # can use any 2 dimensional data structure
    col_types = list(
        id = integer,
        name = character,
        age = numeric,
        is_student = logical
    ),
    max_cols = 5
)

# Additional arguments
PersonFrame <- type.frame(
    frame = data.frame,
    col_types = list(
        id = integer,
        name = character,
        age = numeric,
        is_student = logical,
        email = function(x) grepl("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", x)
    ),
    freeze_n_cols = TRUE, # does not allow adding or removing columns
    row_validator = function(row) row$age >= 18 && row$is_student, # allows for custom row validation
    allow_na = FALSE, # does not allow NA values
    on_violation = c("error", "warning", "silent") # action to take on violation
)

# Usage remains the same
df <- PersonFrame(
    id = 1:3,
    name = c("Alice", "Bob", "Charlie"),
    age = c(25, 30, 35),
    is_student = c(TRUE, FALSE, TRUE)
)

print(df)

# helper for typed lists
IntList <- type.list(
    list_type = integer,
    max_length = 5
)

# other arguments
IntList <- type.list(
    list_type = integer,
    max_length = 5,
    allow_na = FALSE,
    on_violation = c("error", "warning", "silent"),
    validate_on_access = TRUE
)
