box::use(interface[interface, implement])

# Define an interface for a data structure
PersonData <- interface("PersonData",
    name = "character",
    age = "numeric",
    email = "character",
    scores = "data.frame"
)

# Implement the interface
john_data <- implement(PersonData,
    name = "John Doe",
    age = 30,
    email = "john@example.com",
    scores = data.frame(subject = c("Math", "Science"), score = c(95, 88))
)

# Access data safely
print(john_data$name)

john_data$age <- "thirty"

## ---------------------------
# Define a basic interface
SimpleDataset <- interface("SimpleDataset",
    id = "integer",
    value = "numeric",
    category = "factor"
)

# Implement the interface
valid_data <- implement(SimpleDataset,
    id = 1L,
    value = 10.5,
    category = factor("A", levels = c("A", "B", "C"))
)

print(valid_data)

## ---------------------------
# Custom validation function
is_valid_email <- function(x) {
    grepl("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", x)
}

# Interface with custom validation
UserProfile <- interface("UserProfile",
    username = "character",
    email = is_valid_email,
    age = function(x) is.numeric(x) && x >= 18
)

# Implement with valid data
valid_user <- implement(UserProfile,
    username = "john_doe",
    email = "john@example.com",
    age = 25
)

print(valid_user)

## ---------------------------
# nested interfaces
Address <- interface("Address",
    street = "character",
    city = "character",
    postal_code = "character"
)

Employee <- interface("Employee",
    name = "character",
    position = "character",
    address = Address
)

employee_data <- implement(Employee,
    name = "Alice Johnson",
    position = "Data Scientist",
    address = implement(Address,
        street = "123 Tech Street",
        city = "Data City",
        postal_code = "12345"
    )
)

print(employee_data$address$city)

## ---------------------------
# Flexible Validation Control
LargeDataset <- interface("LargeDataset",
    data = "data.frame",
    metadata = "list",
    validate_on_access = FALSE # Disable validation for performance
)

big_data <- implement(LargeDataset,
    data = data.frame(x = 1:1000000, y = runif(1000000)),
    metadata = list(source = "simulation", date = Sys.Date())
)

# No validation on access for better performance
big_data$data[1, "x"] <- "should be numeric but no error raised"
