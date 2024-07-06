# `interface` [v0.1.0](https://github.com/dereckmezquita/interface/milestone/1) (in development)

## 1. Support for typed functions

### Description

Allow for defining functions with typed arguments and return values. This would require a mechanism for extending base R types.

### Implementation Ideas

```r
function2 <- interface("function",
    arg1 = "numeric",
    arg2 = "character",
    return = "numeric"
)

# Implement the function
f2 <- implement(function2, function(arg1, arg2) {
    return(arg1 + nchar(arg2))
})
```

## 2. Support for generics with runtime enforcement

### Description

Allow for defining generic interface, this would allow one to enforce the types across `data.frame` columns for example.

### Implementation Ideas

```r
# Define a interface with n character columns and m numeric columns
Df <- interface("data.frame",
    name = "character",
    height = "numeric",
    age = "numeric"
)

# Implement the interface
df1 <- implement(Df,
    data.frame(
        name = c("John", "Jane"),
        height = c(5.8, 6.0),
        age = c(30, 25)
    )
)

# This should raise an error
df1$age <- c("30", "25")
```

## 3. Allow for generics with either or types

### Description

Much in the same way that `TypeScript` allows for `Union Types`, we can allow for `Union Types` in the `interface` package.

### Implementation Ideas

```r
CharNumList <- interface("list",
    value = c("character", "numeric")
)

# Implement the interface
list1 <- implement(CharNumList, list("John", 30))

Df <- interface("data.frame",
    name = "character",
    height = c("numeric", "character"),
    age = "numeric"
)
```

## 4. Implement Atomic Types

### Description

Create a new way to define atomic types, similar to `TypeScript`'s type aliases. This will allow users to define types for single values instead of lists i.e. the difference between `type` and `interface` in `TypeScript`.

```ts
type Cohort = "alpha" | "beta" | "gamma";

interface Person {
    name: string;
    age: number;
    cohort: Cohort;
}
```

In this way the user would even have the flexibility to check the length of their atomic type.

### Implementation Ideas

- Create a new function, `type()`, that defines atomic types; instead of returning a list these return vectors (since all atomic types are vectors in R).
- Modify the `check_type()` function to handle these new atomic types.
- Update the `implement()` function to return atomic values when appropriate.

### Example Usage

```r
Cohort <- type("Cohort", c("alpha", "beta", "gamma"))

# by default the validate function only checks for membership
cohort1 <- implement(Cohort, "alpha")

# custom function for type checking
Age <- type("Age", function(x) {
    return(is.numeric(x) && x >= 0 && x <= 120 && length(x) == 1)
})

# Use the atomic type
john_age <- implement(Age, 30)
print(john_age) # Should print a vector of length 1

# This should raise an error
try(implement(Age, 150))
```

### Integration with Existing Codebase

- Add a new file `R/type.R` to contain the `type()` function and related helpers.
- Modify `R/implement.R` to handle atomic types differently from interfaces.
- Update `R/helpers.R` to include type checking for atomic types.
- Add new print functions in `R/print.R` to handle atomic types.

## 5. Extend Interfaces and Existing R Types

### Description

Allow interfaces to extend other interfaces or existing R types, similar to inheritance in object-oriented programming.

### Implementation Ideas

- Modify the `interface()` function to accept a `extends` parameter.
- Update the `check_interface()` function to check properties from extended interfaces or types.
- Implement a mechanism to resolve property conflicts in case of multiple extensions.

### Example Usage

```r
# Extend an existing interface
Person <- interface("Person",
    name = "character",
    age = "numeric"
)

Employee <- interface("Employee",
    extends = Person,
    job_title = "character",
    salary = "numeric"
)

john <- implement(Employee,
    name = "John Doe",
    age = 30,
    job_title = "Developer",
    salary = 75000
)

# TODO: this needs more work
# Extend an existing R type
EnhancedDataFrame <- interface("EnhancedDataFrame",
    extends = "data.frame",
    metadata = "list"
)

my_df <- implement(EnhancedDataFrame,
    data.frame(x = 1:3, y = c("a", "b", "c")),
    metadata = list(created_at = Sys.time())
)
```

### Integration with Existing Codebase

- Modify `R/interface.R` to handle the `extends` parameter.
- Update `R/helpers.R` to include extended property checking in `check_interface()`.
- Add new test cases in `tests/testthat/test-interface.R` for extension functionality.

## 6. Add Method Signatures to Interfaces

### Description

Allow interfaces to specify method signatures, not just properties.

### Implementation Ideas

- Extend the `interface()` function to accept method signatures.
- Implement a mechanism to check if an object implements the required methods.

### Example Usage

```r
Drawable <- interface("Drawable",
    methods = list(
        draw = function() NULL
    )
)

Circle <- interface("Circle",
    extends = Drawable,
    radius = "numeric",
    methods = list(
        area = function() NULL
    )
)

my_circle <- implement(Circle,
    radius = 5,
    draw = function() {
        return(cat("Drawing a circle\n"))
    },
    area = function() {
        return(pi * self$radius ^ 2)
    }
)

my_circle$draw()
print(my_circle$area())
```

### Integration with Existing Codebase

- Modify `R/interface.R` to handle method signatures.
- Update `R/implement.R` to check and implement methods.
- Add new test cases in `tests/testthat/test-interface.R` for method functionality.
