source("./R/interface.R")
source("./R/validate_property.R")

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

print(john)

# access data safely
print(john$name)
#> [1] "John Doe"

# should not throw an error; we show later on how to declare a type of a specific length
john$age <- c(10, 11)

# This will raise an error, preventing silent issues
try(john$age <- "thirty")
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

Scholarship <- interface(
    amount = numeric,
    status = logical
)

# extending an interface and using nested interfaces
Student <- interface(
    extends = c(Address, Person),
    student_id = character,
    scores = data.table::data.table,
    # here we show declaring nested interface in place
    scholarship = Scholarship
)

john_student <- Student(
    name = "John Doe",
    age = 30,
    email = "john@example.com",
    street = "123 Main St",
    city = "Small town",
    postal_code = "12345",
    student_id = "123456",
    scores = data.table::data.table(
        subject = c("Math", "Science"),
        score = c(95, 88)
    ),
    scholarship = Scholarship(
        amount = 5000,
        status = TRUE
    )
)

john_student$scores

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
    longitude = numeric,
    validate_on_access = FALSE
)

loc <- Location(
    latitude = 37.7749,
    longitude = -122.4194
)

# does not run the validate function when validated_on_access FALSE
loc$latitude

## ----------------------------------------
## ----------------------------------------
source("./R/fun.R")

# functions
typed_fun <- fun(
    x = numeric,
    y = numeric,
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

print(user_response$data$name)
#> [1] "John Doe"

# functions with generics
GenericApiResponse <- function(T) {
    fun(
        data = T,
        status = numeric,
        message = character,
        return = character,
        impl = function(data, status, message) {
            return(paste(message, "with status", status, "and data", data))
        }
    )
}

# use the generic function
res <- GenericApiResponse(numeric)(
    data = 100,
    status = 200,
    message = "Data retrieved successfully"
)

res

## ------------------------------------------------
source("./R/type.frame.R")
source("./R/validate_property.R")

# dataframe and other typed objects
# Base type.frame function
PersonFrame <- type.frame(
    frame = data.frame, # can use any 2 dimensional data structure
    col_types = list(
        id = integer,
        name = character,
        age = numeric,
        is_student = logical
    )
)

persons <- PersonFrame(
    id = 1:3,
    name = c("Alice", "Bob", "Charlie"),
    age = c(25, 30, 35),
    is_student = c(TRUE, FALSE, TRUE)
)

try(persons$id <- letters[1:3]) # Error: 'id' is a required column
try(persons$yeet <- letters[1:3]) # no error since 'yeet' is not a required column

class(persons)

# Additional arguments
PersonFrame <- type.frame(
    frame = data.frame,
    col_types = list(
        id = integer,
        name = character,
        age = numeric,
        is_student = logical,
        email = function(x) all(grepl("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", x))
    ),
    freeze_n_cols = FALSE, # does not allow adding or removing columns
    row_callback = function(row) {
        if (row$age >= 40) {
            return(sprintf("Age must be less than 40 (got %d)", row$age))
        }
        if (row$name == "Yanice") {
            return("Name cannot be 'Yanice'")
        }
        return(TRUE)
    }, # allows for custom row validation
    allow_na = FALSE, # does not allow NA values
    on_violation = "error" # action to take on violation
)

# Usage
df <- PersonFrame(
    id = 1:3,
    name = c("Alice", "Bob", "Charlie"),
    age = c(25, 35, 35),
    is_student = c(TRUE, FALSE, TRUE),
    email = c("alice@test.com", "bob_no_valid@test.com", "charlie@example.com")
)

print(df)
summary(df)

df[1, "age"] <- 55 # correctly throws error

# add a new row; should throw error because over age of 40
rbind(df, data.frame(
    id = 4,
    name = "David",
    age = 500,
    is_student = TRUE,
    email = "d@test.com"
))

cbind(df, list(yeet = 1:3))

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

# ----------------------------------------------
# Enums
# Load necessary files
source("R/enum.R")
source("R/interface.R")
source("R/validate_property.R")

# Create an enum
Colors <- enum("red", "green", "blue")

col1 <- Colors("red")

col1$value <- "blue"

# This will raise an error
try(col1$value <- "yellow")

# Use the enum in an interface
ColoredShape <- interface(
  shape = character,
  color = Colors
)

# Create an object using the interface
my_shape <- ColoredShape(shape = "circle", color = Colors("red"))

# Access and modify properties
print(my_shape$color)
my_shape$color$value <- "blue"

# This will raise an error
try(my_shape$color$value <- "yellow")

# in place enum
Car <- interface(
  make = character,
  model = character,
  color = enum("red", "green", "blue")
)

my_car <- Car(
  make = "Toyota",
  model = "Corolla",
  color = "red"
)

print(my_car)

my_car$color$value <- "blue"

# This will raise an error
try(my_car$color$value <- "yellow")
