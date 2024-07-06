# Developer Roadmap for `interface` Package

This document outlines planned features and improvements for the `interface` package. It's intended for developers who want to contribute to the package or understand its future direction.

## 1. Implement Atomic Types

### Description

Create a new way to define atomic types, similar to TypeScript's type aliases. This will allow users to define types that return single values instead of lists.

### Implementation Ideas

- Create a new function, say `type()`, that defines atomic types.
- Modify the `check_type()` function to handle these new atomic types.
- Update the `implement()` function to return atomic values when appropriate.

### Example Usage

```r
# Define an atomic type
Age <- type("Age", function(x) is.numeric(x) && x >= 0 && x <= 120)

# Use the atomic type
john_age <- implement(Age, 30)
print(john_age)  # Should print 30, not a list

# This should raise an error
try(implement(Age, 150))
```

### Integration with Existing Codebase

- Add a new file `R/type.R` to contain the `type()` function and related helpers.
- Modify `R/implement.R` to handle atomic types differently from interfaces.
- Update `R/helpers.R` to include type checking for atomic types.

## 2. Extend Interfaces and Existing R Types

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

# Extend an existing R type
EnhancedDataFrame <- interface("EnhancedDataFrame",
    extends = "data.frame",
    metadata = "list"
)

# Usage
john <- implement(Employee,
    name = "John Doe",
    age = 30,
    job_title = "Developer",
    salary = 75000
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

## 3. Improve Type Inference

### Description

Enhance the package's ability to infer types, especially for complex R objects like S3 and S4 classes.

### Implementation Ideas

- Develop a more sophisticated type inference system that can handle S3 and S4 classes.
- Implement a caching mechanism for inferred types to improve performance.

### Example Usage

```r
# Improved type inference for S3 classes
Date <- interface("Date", value = "Date")

today <- implement(Date, Sys.Date())
print(today$value)  # Should print today's date

# Automatic type inference
inferred_interface <- interface_from(my_complex_object)
```

### Integration with Existing Codebase

- Add a new file `R/type_inference.R` for type inference logic.
- Modify `R/helpers.R` to use the new type inference system in `check_type()`.

## 4. Add Method Signatures to Interfaces

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
    draw = function() cat("Drawing a circle\n"),
    area = function() pi * self$radius^2
)

my_circle$draw()
print(my_circle$area())
```

### Integration with Existing Codebase

- Modify `R/interface.R` to handle method signatures.
- Update `R/implement.R` to check and implement methods.
- Add new test cases in `tests/testthat/test-interface.R` for method functionality.

## Conclusion

These proposed features will significantly enhance the capabilities of the `interface` package, bringing it closer to the type systems found in languages like TypeScript. Each feature will require careful implementation and thorough testing to ensure it integrates well with the existing functionality.

Remember to update documentation, including the README and vignettes, as new features are implemented. Also, consider the performance implications of each new feature, especially for large-scale use cases.
