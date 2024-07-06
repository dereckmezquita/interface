library("interface")

Person <- interface("Person",
    name = "character",
    age = "numeric",
    email = "character",
    validate_on_access = TRUE
)

john <- implement(Person,
    name = "John Doe",
    age = 30,
    email = "john@example.com"
)

print(john)
