# interface

`interface` provides a system for defining and implementing `interfaces` in R, with optional runtime type checking.

## Installation

```r
remotes::install_github("dereckmezquita/interface")
```

## Example

This is a basic example which shows you how to solve a common problem:

```r
box::use(interface[ interface, implement ])

# Define an interface
Person <- interface("Person",
    name = "character",
    age = "numeric",
    email = "character"
)

# Implement the interface
john <- implement(Person,
    name = "John Doe",
    age = 30,
    email = "john@example.com"
)

# Access properties
# data is type-checked at runtime when accessing properties
print(john$name)  # "John Doe"
print(john$age)   # 30

# This will raise an error due to type mismatch
try(john$age <- "thirty")

# you can turn off type checking
Dog <- interface("Dog",
    name = "character",
    age = "numeric",
    breed = "character",
    validate_on_access = FALSE
)

# Implement the interface
fido <- implement(Dog,
    name = "Fido",
    age = 5,
    breed = "Golden Retriever"
)

# data is not type checked; reduces overhead
fido$age <- "five" # no error
```

You can use more complex types for properties, such as `list`, `data.frame`, or even other interfaces you have defined yourself.

```r
Address <- interface("Address",
    street = "character",
    city = "character",
    state = "character",
    zip = "numeric"
)

# Define an interface
Person <- interface("Person",
    name = "character",
    age = "numeric",
    email = "character",
    address = Address
)

# Implement the interface
john <- implement(Person,
    name = "John Doe",
    age = 30,
    email = "example@example.com",
    address = implement(Address,
        street = "123 Main St",
        city = "Anytown",
        state = "NY",
        zip = 12345
    )
)
```

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details