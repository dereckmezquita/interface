
<!-- README.md is generated from README.Rmd. Please edit that file -->

# interface: Bringing Structure and Safety to R

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![Travis build
status](https://travis-ci.org/dereckmezquita/kucoin.svg?branch=master)](https://travis-ci.org/dereckmezquita/kucoin)
<!-- badges: end -->

## Overview

The `interface` package brings the power of interfaces and runtime type
checking to R, offering a robust solution for data structure validation
and enhancing code reliability. In the dynamic world of R programming,
where data structures can be fluid, `interface` provides a safety net,
ensuring that your data conforms to expected structures and types.

### Why `interface`?

1.  **Data Integrity**: Ensure your data structures are consistent and
    valid throughout your analysis pipeline.
2.  **Early Error Detection**: Catch type mismatches and structural
    issues at runtime, preventing silent errors that could compromise
    your results.
3.  **Self-Documenting Code**: Interfaces serve as clear contracts,
    making your code more readable and self-explanatory.
4.  **Flexible Validation**: From simple type checks to complex custom
    validations, `interface` adapts to your needs.
5.  **Performance Control**: Toggle validation on/off as needed,
    balancing safety and performance.

## Installation

You can install the development version of interface from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
remotes::install_github("dereckmezquita/interface")
```

## Quick Start

``` r
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
#> [1] "John Doe"
```

``` r
print(john_data$scores)
#>   subject score
#> 1    Math    95
#> 2 Science    88
```

``` r

# This will raise an error, preventing silent issues
try(john_data$age <- "thirty")
#> Error in `$<-.validated_list`(`*tmp*`, age, value = "thirty") : 
#>   Property 'age' does not match the expected type specification
```

## Detailed Usage

### Basic Interface Definition

Interfaces in R provide a clear contract for data structures:

``` r
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
#> Object implementing SimpleDataset interface:
#>   id: 1 
#>   value: 10.5 
#>   category: 1 
#> Validation on access: Enabled
```

### Custom Validation Functions

For more complex validations, use custom functions:

``` r
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
#> Object implementing UserProfile interface:
#>   username: john_doe 
#>   email: john@example.com 
#>   age: 25 
#> Validation on access: Enabled
```

``` r

# This will raise an error due to invalid email
try(implement(UserProfile,
    username = "jane_doe",
    email = "not_an_email",
    age = 30
))
#> Error in validate_object(obj, interface) : 
#>   Property 'email' does not match the expected type specification
```

### Nested Interfaces

Compose complex data structures with nested interfaces:

``` r
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
#> [1] "Data City"
```

### Flexible Validation Control

Toggle validation for performance optimisation:

``` r
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
```

## Benefits in Real-world Scenarios

### Data Pipeline Integrity

Ensure consistent data structures throughout your analysis pipeline:

``` r
# Define interfaces for each stage of your pipeline
RawData <- interface("RawData",
    timestamp = "POSIXct",
    measurements = "list"
)

ProcessedData <- interface("ProcessedData",
    timestamp = "POSIXct",
    average = "numeric",
    stddev = "numeric"
)

AnalysisResult <- interface("AnalysisResult",
    data = ProcessedData,
    model_fit = "list",
    r_squared = "numeric"
)

# Your pipeline functions
process_data <- function(raw_data) {
    # Processing logic here
    implement(ProcessedData,
        timestamp = raw_data$timestamp,
        average = mean(unlist(raw_data$measurements)),
        stddev = sd(unlist(raw_data$measurements))
    )
}

analyze_data <- function(processed_data) {
    # Analysis logic here
    implement(AnalysisResult,
        data = processed_data,
        model_fit = list(coefficients = c(intercept = 0.5, slope = 1.2)),
        r_squared = 0.85
    )
}

# Run the pipeline
raw_data <- implement(RawData,
    timestamp = Sys.time(),
    measurements = list(10, 15, 20, 18, 22)
)

processed <- process_data(raw_data)
result <- analyze_data(processed)

print(result)
#> Object implementing AnalysisResult interface:
#>   data: <validated_list>
#>   model_fit: <list>
#>   r_squared: 0.85 
#> Validation on access: Enabled
```

This example demonstrates how `interface` can ensure data integrity
throughout a multi-stage analysis pipeline, catching any structural or
type inconsistencies early in the process.

## Conclusion

The `interface` package brings a new level of structure and safety to R
programming. By providing clear contracts for data structures and
runtime type checking, it helps prevent common errors, improves code
readability, and ensures data integrity throughout your projects.

Whether you’re working on small scripts or large-scale data analysis
pipelines, `interface` offers the flexibility and robustness to enhance
your R code. Start using `interface` today to write safer, more reliable
R code!

## Contributing

Contributions to `interface` are welcome! Please refer to the
[Contribution Guidelines](CONTRIBUTING.md) for more information.

## License

This project is licensed under the MIT License - see the
[LICENSE.md](LICENSE.md) file for details.
