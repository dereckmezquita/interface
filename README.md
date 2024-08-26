
<!-- README.md is generated from README.Rmd. Please edit that file -->

# interface

<!-- badges: start -->

[![R-CMD-check](https://github.com/dereckmezquita/interface/workflows/R-CMD-check/badge.svg)](https://github.com/dereckmezquita/interface/actions)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/interface)](https://CRAN.R-project.org/package=interface)
[![GitHub
version](https://img.shields.io/github/r-package/v/dereckmezquita/interface?label=GitHub)](https://github.com/dereckmezquita/interface)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Downloads](https://cranlogs.r-pkg.org/badges/interface)](https://cran.r-project.org/package=interface)
<!-- badges: end -->

The `interface` package provides a system for defining and implementing
interfaces in R, with runtime type checking, bringing some of the
benefits of statically-typed languages to R with zero dependencies.

`interface` provides:

1.  **Interfaces**: Define and implement interfaces with type checking.
    Interfaces can be extended and nested.
2.  **Typed Functions**: Define functions with strict type constraints.
3.  **Typed Frames**: Choose between a `data.frame` or `data.table` with
    column type constraints and row validation.
4.  **Enums**: Define and use enumerated types for stricter type safety.

## Installation

To install the package, use the following command:

``` r
# Install the package from the source
remotes::install_github("dereckmezquita/interface")
```

## Getting started

Import the package functions.

``` r
box::use(interface[ interface, type.frame, fun, enum ])
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
#> Object implementing interface:
#>   name: John Doe
#>   age: 30
#>   email: john@example.com
#> Validation on access: Disabled

# interfaces are lists
print(john$name)
#> [1] "John Doe"

# Modify the object
john$age <- 10
print(john$age)
#> [1] 10

# Invalid assignment (throws error)
try(john$age <- "thirty")
#> Error : Property 'age' must be of type numeric
```

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
#> Object implementing interface:
#>   student_id: 123456
#>   scores: Math
#>    scores: Science
#>    scores: 95
#>    scores: 88
#>   scholarship: <environment: 0x11b9bccd0>
#>   street: 123 Main St
#>   city: Small town
#>   postal_code: 12345
#>   name: John Doe
#>   age: 30
#>   email: john@example.com
#> Validation on access: Disabled
```

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
#> Object implementing interface:
#>   username: john_doe
#>   email: john@example.com
#>   age: 25
#> Validation on access: Disabled

# Invalid implementation (throws error)
try(UserProfile(
    username = "jane_doe",
    email = "not_an_email",
    age = "30"
))
#> Error : Errors occurred during interface creation:
#>   - Invalid value for property 'email': FALSE
#>   - Invalid value for property 'age': FALSE
```

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
#> [1] 3
try(typed_fun("a", 2))  # Invalid call
#> Error : Property 'x' must be of type numeric
```

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
#> [1] 3
print(typed_fun2("a", 2))  # [1] "a 2"
#> [1] "a 2"
```

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
#> [1mTyped Data Frame Summary:[0m
#> Base Frame Type: data.frame
#> Dimensions: 3 rows x 4 columns
#> 
#> [1mColumn Specifications:[0m
#>   id         : integer
#>   name       : character
#>   age        : numeric
#>   is_student : logical
#> 
#> [1mFrame Properties:[0m
#>   Freeze columns : Yes
#>   Allow NA       : Yes
#>   On violation   : error
#> 
#> [1mData Preview:[0m
#>   id    name age is_student
#> 1  1   Alice  25       TRUE
#> 2  2     Bob  30      FALSE
#> 3  3 Charlie  35       TRUE

# Invalid modification (throws error)
try(persons$id <- letters[1:3])
#> Error in `$<-.typed_frame`(`*tmp*`, id, value = c("a", "b", "c")) : 
#>   object 'col_name' not found
```

Additional options for data frame validation:

``` r
PersonFrame <- type.frame(
    frame = data.frame,
    col_types = list(
        id = integer,
        name = character,
        age = numeric,
        is_student = logical,
        gender = enum("M", "F"),
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
    gender = c("F", "M", "M"),
    email = c("alice@test.com", "bob_no_valid@test.com", "charlie@example.com")
)

print(df)
#> [1mTyped Data Frame Summary:[0m
#> Base Frame Type: data.frame
#> Dimensions: 3 rows x 6 columns
#> 
#> [1mColumn Specifications:[0m
#>   id         : integer
#>   name       : character
#>   age        : numeric
#>   is_student : logical
#>   gender     : Enum(M, F)
#>   email      : custom function
#> 
#> [1mFrame Properties:[0m
#>   Freeze columns : No
#>   Allow NA       : No
#>   On violation   : error
#> 
#> [1mData Preview:[0m
#>   id name age is_student gender email
#> 1  1 TRUE   1       TRUE   TRUE  TRUE
#> 2  1 TRUE   1       TRUE   TRUE  TRUE
#> 3  1 TRUE   1       TRUE   TRUE  TRUE
summary(df)
#>        id        name                age    is_student    
#>  Min.   :1   Length:3           Min.   :1   Mode:logical  
#>  1st Qu.:1   Class :character   1st Qu.:1   TRUE:3        
#>  Median :1   Mode  :character   Median :1                 
#>  Mean   :1                      Mean   :1                 
#>  3rd Qu.:1                      3rd Qu.:1                 
#>  Max.   :1                      Max.   :1                 
#>  gender.Length  gender.Class  gender.Mode    email          
#>  1        -none-   logical                Length:3          
#>  1        -none-   logical                Class :character  
#>  1        -none-   logical                Mode  :character  
#>                                                             
#>                                                             
#> 

# Invalid row addition (throws error)
try(rbind(df, data.frame(
    id = 4,
    name = "David",
    age = 50,
    is_student = TRUE,
    email = "d@test.com"
)))
#> Error in rbind(deparse.level, ...) : Number of columns must match
```

### Enums

Define enums for categorical variables; these are safe to use to protect
a value from being modified to invalid options. The `enum` function
creates a generator which is then used to create the enum object. This
can be used standalone or as part of an interface.

``` r
Colour <- enum("red", "green", "blue")

# Create an enum object
colour <- Colour("red")
print(colour)
#> Enum: red

colour$value <- "green"
print(colour)
#> Enum: green

# Invalid modification (throws error)
try(colour$value <- "yellow")
#> Error in `$<-.enum`(`*tmp*`, value, value = "yellow") : 
#>   Invalid value. Must be one of: red, green, blue

# Use in an interface
Car <- interface(
    make = enum("Toyota", "Ford", "Chevrolet"),
    model = character,
    colour = Colour
)

# Implement the interface
car1 <- Car(
    make = "Toyota",
    model = "Corolla",
    colour = "red"
)

print(car1)
#> Object implementing interface:
#>   make: Toyota
#>   model: Corolla
#>   colour: red
#> Validation on access: Disabled

# Invalid implementation (throws error)
try(Car(
    make = "Honda",
    model = "Civic",
    colour = "yellow"
))
#> Error : Errors occurred during interface creation:
#>   - Invalid enum value for property 'make': Invalid value. Must be one of: Toyota, Ford, Chevrolet
#>   - Invalid enum value for property 'colour': Invalid value. Must be one of: red, green, blue

# Invalid modification (throws error)
try(car1$colour$value <- "yellow")
#> Error in `$<-.enum`(`*tmp*`, value, value = "yellow") : 
#>   Invalid value. Must be one of: red, green, blue
try(car1$make$value <- "Honda")
#> Error in `$<-.enum`(`*tmp*`, value, value = "Honda") : 
#>   Invalid value. Must be one of: Toyota, Ford, Chevrolet
```

## Conclusion

The `interface` package provides powerful tools for ensuring type safety
and validation in R. By defining interfaces, typed functions, and typed
data frames, you can create robust and reliable data structures and
functions with strict type constraints. For more details, refer to the
package documentation.

## License

This package is licensed under the MIT License.

## Citation

If you use this package in your research or work, please cite it as:

Mezquita, D. (2024). interface: A Runtime Type System for R. R package
version 0.1.0. <https://github.com/dereckmezquita/interface>
