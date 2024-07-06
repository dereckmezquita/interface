test_that("implement works with valid input", {
    Person <- interface("Person",
        name = "character",
        age = "numeric",
        email = "character"
    )

    john <- implement(Person,
        name = "John Doe",
        age = 30,
        email = "john@example.com"
    )

    expect_s3_class(john, "PersonImplementation")
    expect_s3_class(john, "InterfaceImplementation")
    expect_equal(john$name, "John Doe")
    expect_equal(john$age, 30)
    expect_equal(john$email, "john@example.com")
})

test_that("implement fails with invalid input", {
    Person <- interface("Person",
        name = "character",
        age = "numeric",
        email = "character"
    )

    expect_error(implement(Person,
        name = "John Doe",
        age = "thirty",
        email = "john@example.com"
    ), "Property 'age' does not match the expected type specification")

    expect_error(implement(Person,
        name = "John Doe",
        age = 30
    ), "Missing properties: email")
})

test_that("validation on access works", {
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

    john$age <- "thirty"
    expect_error(john$name, "Property 'age' does not match the expected type specification")
})
