
<!-- README.md is generated from README.Rmd. Please edit that file -->

# interface

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![Travis build
status](https://travis-ci.org/dereckmezquita/kucoin.svg?branch=master)](https://travis-ci.org/dereckmezquita/kucoin)
<!-- badges: end -->

The `interface` package provides a system for defining and implementing
interfaces in R, with runtime type checking, bringing some of the
benefits of statically-typed languages to R.

## Installation

To install the package, use the following command:

``` r
# Install the package from the source
remotes::install_github("dereckmezquita/interface")
```

## Getting started

Import the package functions.

``` r
box::use(interface[ interface, type.frame, fun ])
```

Define an interface and implement it:

``` r
# Define an interface
Person <- interface(
    name = character,
    age = numeric,
    email = character
)

# Implement the interface
john <- Person(
    name = "John Doe",
    age = 30,
    email = "john@example.com"
)

print(john)
```

    #> Object implementing interface:
    #>   name: John Doe
    #>   age: 30
    #>   email: john@example.com
    #> Validation on access: Disabled

``` r
# interfaces are lists
print(john$name)
```

    #> [1] "John Doe"

``` r
# Modify the object
john$age <- 10
print(john$age)
```

    #> [1] 10

``` r
# Invalid assignment (throws error)
try(john$age <- "thirty")
```

    #> Error : Property 'age' must be of type numeric

### Extending Interfaces and Nested Interfaces

Create nested and extended interfaces:

``` r
# Define nested interfaces
Address <- interface(
    street = character,
    city = character,
    postal_code = character
)

Scholarship <- interface(
    amount = numeric,
    status = logical
)

# Extend interfaces
Student <- interface(
    extends = c(Address, Person),
    student_id = character,
    scores = data.table::data.table,
    scholarship = Scholarship
)

# Implement the extended interface
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

print(john_student)
```

    #> Object implementing interface:
    #>   student_id: 123456
    #>   scores: Math
    #>    scores: Science
    #>    scores: 95
    #>    scores: 88
    #>   scholarship: <environment: 0x1320acea0>
    #>   street: 123 Main St
    #>   city: Small town
    #>   postal_code: 12345
    #>   name: John Doe
    #>   age: 30
    #>   email: john@example.com
    #> Validation on access: Disabled

### Custom Validation Functions

Interfaces can have custom validation functions:

``` r
is_valid_email <- function(x) {
    grepl("[a-z|0-9]+\\@[a-z|0-9]+\\.[a-z|0-9]+", x)
}

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
```

    #> Object implementing interface:
    #>   username: john_doe
    #>   email: john@example.com
    #>   age: 25
    #> Validation on access: Disabled

``` r
# Invalid implementation (throws error)
try(UserProfile(
    username = "jane_doe",
    email = "not_an_email",
    age = "30"
))
```

    #> Error : Errors occurred during interface creation:
    #>   - Invalid value(s) for property 'email' at index(es): 1
    #>   - Invalid value(s) for property 'age' at index(es): 1

### Typed Functions

Define functions with strict type constraints:

``` r
typed_fun <- fun(
    x = numeric,
    y = numeric,
    return = numeric,
    impl = function(x, y) {
        return(x + y)
    }
)

print(typed_fun(1, 2))  # [1] 3
```

    #> [1] 3

``` r
try(typed_fun("a", 2))  # Invalid call
```

    #> Error : Property 'x' must be of type numeric

Functions with multiple possible return types:

``` r
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

print(typed_fun2(1, 2))  # [1] 3
```

    #> [1] 3

``` r
print(typed_fun2("a", 2))  # [1] "a 2"
```

    #> [1] "a 2"

### Typed Data Frames and Data Tables

Create data frames with column type constraints and row validation:

``` r
PersonFrame <- type.frame(
    frame = data.frame, 
    col_types = list(
        id = integer,
        name = character,
        age = numeric,
        is_student = logical
    )
)

# Create a data frame
persons <- PersonFrame(
    id = 1:3,
    name = c("Alice", "Bob", "Charlie"),
    age = c(25, 30, 35),
    is_student = c(TRUE, FALSE, TRUE)
)

print(persons)
```

    #> Typed data frame with the following properties:
    #> Number of rows: 3
    #> Number of columns: 4
    #> Column types:
    #>   id: function (length = 0L) 
    #>    id: .Internal(vector("integer", length))
    #>   name: function (length = 0L) 
    #>    name: .Internal(vector("character", length))
    #>   age: function (length = 0L) 
    #>    age: .Internal(vector("double", length))
    #>   is_student: function (length = 0L) 
    #>    is_student: .Internal(vector("logical", length))
    #> Freeze columns: Yes
    #> Allow NA: Yes
    #> On violation: error
    #> 
    #> Data:
    #>   id    name age is_student
    #> 1  1   Alice  25       TRUE
    #> 2  2     Bob  30      FALSE
    #> 3  3 Charlie  35       TRUE

``` r
# Invalid modification (throws error)
try(persons$id <- letters[1:3])
```

    #> Error : Property 'id' must be of type integer

Additional options for data frame validation:

``` r
PersonFrame <- type.frame(
    frame = data.frame,
    col_types = list(
        id = integer,
        name = character,
        age = numeric,
        is_student = logical,
        email = function(x) all(grepl("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", x))
    ),
    freeze_n_cols = FALSE,
    row_callback = function(row) {
        if (row$age >= 40) {
            return(sprintf("Age must be less than 40 (got %d)", row$age))
        }
        if (row$name == "Yanice") {
            return("Name cannot be 'Yanice'")
        }
        return(TRUE)
    },
    allow_na = FALSE,
    on_violation = "error"
)

df <- PersonFrame(
    id = 1:3,
    name = c("Alice", "Bob", "Charlie"),
    age = c(25, 35, 35),
    is_student = c(TRUE, FALSE, TRUE),
    email = c("alice@test.com", "bob_no_valid@test.com", "charlie@example.com")
)

print(df)
```

    #> Typed data frame with the following properties:
    #> Number of rows: 3
    #> Number of columns: 5
    #> Column types:
    #>   id: function (length = 0L) 
    #>    id: .Internal(vector("integer", length))
    #>   name: function (length = 0L) 
    #>    name: .Internal(vector("character", length))
    #>   age: function (length = 0L) 
    #>    age: .Internal(vector("double", length))
    #>   is_student: function (length = 0L) 
    #>    is_student: .Internal(vector("logical", length))
    #>   email: function (x) 
    #>    email: all(grepl("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", 
    #>    email:     x))
    #> Freeze columns: No
    #> Allow NA: No
    #> On violation: error
    #> 
    #> Data:
    #>   id    name age is_student                 email
    #> 1  1   Alice  25       TRUE        alice@test.com
    #> 2  2     Bob  35      FALSE bob_no_valid@test.com
    #> 3  3 Charlie  35       TRUE   charlie@example.com

``` r
summary(df)
```

    #> Typed data frame summary:
    #> Number of rows: 3
    #> Number of columns: 5
    #> Column types:
    #>   id: function (length = 0L) 
    #>    id: .Internal(vector("integer", length))
    #>   name: function (length = 0L) 
    #>    name: .Internal(vector("character", length))
    #>   age: function (length = 0L) 
    #>    age: .Internal(vector("double", length))
    #>   is_student: function (length = 0L) 
    #>    is_student: .Internal(vector("logical", length))
    #>   email: function (x) 
    #>    email: all(grepl("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", 
    #>    email:     x))
    #> Freeze columns: No
    #> Allow NA: No
    #> On violation: error
    #> Validation status:
    #>   All rows passed validation.

``` r
# Invalid row addition (throws error)
try(rbind(df, data.frame(
    id = 4,
    name = "David",
    age = 50,
    is_student = TRUE,
    email = "d@test.com"
)))
```

    #> Error in rbind(deparse.level, ...) : 
    #>   Row 1 failed validation: Age must be less than 40 (got 50)

## Conclusion

The `interface` package provides powerful tools for ensuring type safety
and validation in R. By defining interfaces, typed functions, and typed
data frames, you can create robust and reliable data structures and
functions with strict type constraints. For more details, refer to the
package documentation.
