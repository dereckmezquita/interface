box::use(interface[interface, fun, generic])

# Define an interface for a data structure
PersonData <- interface(
    name = "character",
    age = "numeric",
    email = "character",
    scores = "data.frame"
)

# Implement the interface
john_data <- PersonData(,
    name = "John Doe",
    age = 30,
    email = "john@example.com",
    scores = data.frame(subject = c("Math", "Science"), score = c(95, 88))
)

# Access data safely
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
SimpleDataset <- interface(
    id = "integer",
    value = "numeric",
    category = "factor"
)

# Implement the interface
valid_data <- SimpleDataset(
    id = 1L,
    value = 10.5,
    category = factor("A", levels = c("A", "B", "C"))
)

print(valid_data)
#> Object implementing SimpleDataset interface:
#>   id: 1 
#>   value: 10.5 
#>   category: 1 
#> Validation on access: Enabled

### Custom Validation Functions

# Custom validation function
is_valid_email <- function(x) {
    grepl("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", x)
}

# Interface with custom validation
UserProfile <- interface(
    username = "character",
    email = is_valid_email,
    age = function(x) is.numeric(x) && x >= 18
)

# Implement with valid data
valid_user <- UserProfile(,
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
    age = 30
))
#> Error in validate_object(obj, interface) : 
#>   Property 'email' does not match the expected type specification

# nested interfaces
Address <- interface(
    street = "character",
    city = "character",
    postal_code = "character"
)

Employee <- interface(
    name = "character",
    position = "character",
    address = Address
)

employee_data <- Employee(,
    name = "Alice Johnson",
    position = "Data Scientist",
    address = Address(
        street = "123 Tech Street",
        city = "Data City",
        postal_code = "12345"
    )
)

print(employee_data$address$city)
#> [1] "Data City"


# Toggle validation for performance optimisation:

LargeDataset <- interface(
    data = "data.frame",
    metadata = "list",
    validate_on_access = FALSE # Disable validation for performance
)

big_data <- implement(LargeDataset,
    data = data.frame(x = 1:1000, y = runif(1000)),
    metadata = list(source = "simulation", date = Sys.Date())
)

# No validation on access for better performance
big_data$data[1, "x"] <- "should be numeric but no error raised"


# functions
typed_fun <- fun(
    args = list(
        x = "numeric",
        y = "numeric"
    ),
    return = "numeric",
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
        x = c("numeric", "character"),
        y = "numeric"
    ),
    return = c("numeric", "character"),
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
ApiResponse <- generic(function(T) {
    interface(
        data = T,
        status = "numeric",
        message = "character"
    )
})

# Use the generic interface with a specific type
UserResponse <- ApiResponse(UserProfile)

# Implement the generic interface
user_response <- UserResponse(
    data = UserProfile(
        username = "john_doe",
        email = "john@example.com",
        age = 25
    ),
    status = 200,
    message = "User retrieved successfully"
)

print(user_response$data$username)
#> [1] "john_doe"

# Another example with a different type
NumberResponse <- ApiResponse("numeric")

number_response <- NumberResponse(
    data = 42,
    status = 200,
    message = "Number retrieved successfully"
)

print(number_response$data)
#> [1] 42

# Generic typed function
map_data <- generic(function(T, U) {
    fun(
        args = list(
            data = T,
            mapper = fun(args = list(x = T), return = U)
        ),
        return = U,
        impl = function(data, mapper) {
            mapper(data)
        }
    )
})

# Use the generic function with specific types
double_number <- map_data("numeric", "numeric")(
    data = 21,
    mapper = function(x) x * 2
)

print(double_number)
#> [1] 42

# Using generics with previously defined interfaces
EmployeeResponse <- ApiResponse(Employee)

employee_response <- EmployeeResponse(
    data = employee_data,  # Using the previously defined employee_data
    status = 200,
    message = "Employee data retrieved successfully"
)

print(employee_response$data$address$city)
#> [1] "Data City"
