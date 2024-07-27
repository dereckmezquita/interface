test_that("interface creation works", {
    Person <- interface("Person",
        name = "character",
        age = "numeric",
        email = "character",
        validate_on_access = TRUE
    )

    expect_s3_class(Person, "Interface")
    expect_equal(Person$interface_name, "Person")
    expect_equal(Person$properties, list(name = "character", age = "numeric", email = "character"))
    expect_true(Person$validate_on_access)
})

test_that("interface with custom validator works", {
    positive_number <- function(x) is.numeric(x) && x > 0

    Account <- interface("Account",
        id = "character",
        balance = positive_number
    )

    expect_s3_class(Account, "Interface")
    expect_true(is.function(Account$properties$balance))
})
