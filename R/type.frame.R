#' Create a typed data frame
#'
#' @description
#' Creates a data frame with specified column types and validation rules. 
#' Ensures that the data frame adheres to the specified structure and validation rules during creation and modification.
#'
#' @param frame The base data structure (e.g., data.frame, data.table).
#' @param col_types A list of column types and validators.
#' @param freeze_n_cols Logical, whether to freeze the number of columns (default: TRUE).
#' @param row_callback A function to validate and process each row (optional).
#' @param allow_na Logical, whether to allow NA values (default: TRUE).
#' @param on_violation Action to take on violation: "error", "warning", or "silent" (default: "error").
#' @return A function that creates typed data frames.
#' @details
#' The `type.frame` function defines a blueprint for a data frame, specifying the types of its columns and optional validation rules for its rows. 
#' When a data frame is created or modified using this blueprint, it ensures that all data adheres to the specified rules.
#'
#' @examples
#' # Define a typed data frame
#' PersonFrame <- type.frame(
#'     frame = data.frame,
#'     col_types = list(
#'         id = integer,
#'         name = character,
#'         age = numeric,
#'         is_student = logical
#'     )
#' )
#'
#' # Create a data frame
#' persons <- PersonFrame(
#'     id = 1:3,
#'     name = c("Alice", "Bob", "Charlie"),
#'     age = c(25, 30, 35),
#'     is_student = c(TRUE, FALSE, TRUE)
#' )
#'
#' print(persons)
#'
#' # Invalid modification (throws error)
#' try(persons$id <- letters[1:3])
#'
#' # Adding a column (throws error if freeze_n_cols is TRUE)
#' try(persons$yeet <- letters[1:3])
#' @export
type.frame <- function(
    frame,
    col_types,
    freeze_n_cols = TRUE,
    row_callback = NULL,
    allow_na = TRUE,
    on_violation = c("error", "warning", "silent")
) {
    on_violation <- match.arg(on_violation)

    # Process in-place enum declarations
    for (name in names(col_types)) {
        if (inherits(col_types[[name]], "enum_generator")) {
            enum_generator <- col_types[[name]]
            col_types[[name]] <- list(
                type = "enum",
                validator = function(x) {
                    if (is.character(x)) {
                        return(enum_generator(x))
                    } else if (inherits(x, "enum")) {
                        return(x)
                    } else {
                        stop(sprintf("Invalid value for enum '%s'. Must be a character or enum object.", name))
                    }
                },
                values = attr(enum_generator, "values")
            )
        }
    }

    creator <- function(...) {
        df <- frame(...)
        errors <- list()

        # Validate column types and convert enum values
        for (col_name in names(col_types)) {
            if (!(col_name %in% names(df))) {
                errors <- c(errors, sprintf("Required column '%s' is missing", col_name))
            } else {
                col_data <- df[[col_name]]
                col_type <- col_types[[col_name]]

                # Handle enum conversion
                if (is.list(col_type) && col_type$type == "enum") {
                    df[[col_name]] <- sapply(col_data, function(x) {
                        tryCatch(
                            col_type$validator(x),
                            error = function(e) {
                                errors <<- c(errors, sprintf("Invalid enum value for column '%s': %s", col_name, x))
                                return(x)  # Return original value to allow further processing
                            }
                        )
                    })
                } else {
                    # For non-enum columns, use the original type
                    error <- validate_property(col_name, df[[col_name]], col_type)
                    if (!is.null(error)) {
                        errors <- c(errors, error)
                    }
                }
            }
        }

        # Check for NA values
        if (!allow_na && any(is.na(df))) {
            na_cols <- names(df)[apply(df, 2, function(x) any(is.na(x)))]
            errors <- c(errors, sprintf("NA values found in column(s): %s", paste(na_cols, collapse = ", ")))
        }

        # Process rows with callback
        if (!is.null(row_callback)) {
            for (i in seq_len(nrow(df))) {
                row <- df[i, , drop = FALSE]
                tryCatch({
                    result <- row_callback(row)
                    if (!isTRUE(result)) {
                        errors <- c(errors, sprintf("Row %d failed validation: %s", i, as.character(result)))
                    }
                }, error = function(e) {
                    errors <- c(errors, sprintf("Error processing row %d: %s", i, e$message))
                })
            }
        }

        # Handle all collected errors
        if (length(errors) > 0) {
            error_message <- paste("Validation errors:", paste(errors, collapse = "\n  "), sep = "\n  ")
            handle_violation(error_message, on_violation)
        }

        # Create the typed data frame
        return(structure(
            df,
            class = c("typed_frame", class(df)),
            col_types = col_types,
            freeze_n_cols = freeze_n_cols,
            row_callback = row_callback,
            allow_na = allow_na,
            on_violation = on_violation
        ))
    }

    return(creator)
}

#' Handle violations based on the specified action
#'
#' @description
#' Handles violations by either throwing an error, issuing a warning, or doing nothing, depending on the specified action.
#'
#' @param message The error message to be handled.
#' @param action The action to take: "error", "warning", or "silent".
handle_violation <- function(message, action) {
    switch(action,
        "error" = stop(message, call. = FALSE),
        "warning" = warning(message, call. = FALSE),
        "silent" = invisible(NULL)
    )
}

#' Modify a typed data frame using [ ]
#'
#' @description
#' Allows modifying a typed data frame using the [ ] operator, with validation checks.
#'
#' @param x A typed data frame.
#' @param i Row index.
#' @param j Column index or name.
#' @param value The new value to assign.
#' @return The modified typed data frame.
#' @export
`[<-.typed_frame` <- function(x, i, j, value) {
    # Check if adding new columns is allowed
    if (attr(x, "freeze_n_cols") && !all(j %in% names(x))) {
        stop("Adding new columns is not allowed when freeze_n_cols is TRUE")
    }

    # Perform the assignment
    x <- NextMethod()

    # Re-validate the modified data
    for (col_name in names(attr(x, "col_types"))) {
        if (col_name %in% j) {
            col_data <- x[[col_name]]
            col_type <- attr(x, "col_types")[[col_name]]

            error <- validate_property(col_name, col_data, col_type)
            if (!is.null(error)) {
                handle_violation(error, attr(x, "on_violation"))
            }
        }
    }

    # Check for NA values
    if (!attr(x, "allow_na") && any(is.na(x))) {
        handle_violation("NA values are not allowed", attr(x, "on_violation"))
    }

    # Validate rows
    if (!is.null(attr(x, "row_validator"))) {
        invalid_rows <- which(!apply(x, 1, attr(x, "row_validator")))
        if (length(invalid_rows) > 0) {
            handle_violation(sprintf("Invalid rows: %s", paste(invalid_rows, collapse = ", ")), attr(x, "on_violation"))
        }
    }

    # Process new or modified rows with callback
    if (!is.null(attr(x, "row_callback"))) {
        affected_rows <- unique(i)
        for (row_index in affected_rows) {
            row <- x[row_index, , drop = FALSE]
            result <- attr(x, "row_callback")(row)
            if (!isTRUE(result)) {
                handle_violation(sprintf("Row %d failed validation: %s", row_index, as.character(result)), attr(x, "on_violation"))
            }
        }
    }
    
    return(x)
}

#' Modify a typed data frame using $
#'
#' @description
#' Allows modifying a typed data frame using the $ operator, with validation checks.
#'
#' @param x A typed data frame.
#' @param name The name of the column to modify or add.
#' @param value The new value to assign.
#' @return The modified typed data frame.
#' @export
`$<-.typed_frame` <- function(x, name, value) {
    # Check if adding new columns is allowed
    if (attr(x, "freeze_n_cols") && !(name %in% names(x))) {
        stop("Adding new columns is not allowed when freeze_n_cols is TRUE")
    }

    # Perform the assignment
    x <- NextMethod()

    # Re-validate the modified data
    if (name %in% names(attr(x, "col_types"))) {
        col_type <- attr(x, "col_types")[[name]]

        error <- validate_property(name, value, col_type)
        if (!is.null(error)) {
            handle_violation(error, attr(x, "on_violation"))
        }
    }

    # Check for NA values
    if (!attr(x, "allow_na") && any(is.na(x))) {
        handle_violation("NA values are not allowed", attr(x, "on_violation"))
    }

    # Validate rows
    if (!is.null(attr(x, "row_validator"))) {
        invalid_rows <- which(!apply(x, 1, attr(x, "row_validator")))
        if (length(invalid_rows) > 0) {
            handle_violation(sprintf("Invalid rows: %s", paste(invalid_rows, collapse = ", ")), attr(x, "on_violation"))
        }
    }

    # Process all rows with callback if column modification occurs
    if (!is.null(attr(x, "row_callback"))) {
        for (i in seq_len(nrow(x))) {
            row <- x[i, , drop = FALSE]
            result <- attr(x, "row_callback")(row)
            if (!isTRUE(result)) {
                handle_violation(sprintf(
                    "Row %d failed validation after column modification: %s", i, as.character(result)), attr(x, "on_violation"
                ))
            }
        }
    }

    return(x)
}

#' Print method for typed data frames
#'
#' @description
#' Provides a custom print method for typed data frames, displaying their properties and validation status.
#'
#' @param x A typed data frame.
#' @param ... Additional arguments passed to print.
#' @export
print.typed_frame <- function(x, ...) {
    cat("Typed data frame with the following properties:\n")
    cat(sprintf("Number of rows: %d\n", nrow(x)))
    cat(sprintf("Number of columns: %d\n", ncol(x)))
    cat("Column types:\n")
    for (name in names(attr(x, "col_types"))) {
        cat(sprintf("  %s: %s\n", name, format(attr(x, "col_types")[[name]])))
    }
    cat(sprintf("Freeze columns: %s\n", ifelse(attr(x, "freeze_n_cols"), "Yes", "No")))
    cat(sprintf("Allow NA: %s\n", ifelse(attr(x, "allow_na"), "Yes", "No")))
    cat(sprintf("On violation: %s\n", attr(x, "on_violation")))
    cat("\nData:\n")
    NextMethod()
}

#' Combine typed data frames row-wise
#'
#' @description
#' This function combines multiple typed data frames row-wise, ensuring type consistency and applying row validation rules.
#' It extends the base \code{\link[base]{rbind}} function by adding type checks and row validation based on the specified rules for typed data frames.
#'
#' @param ... Typed data frames to combine.
#' @param deparse.level See \code{\link[base]{rbind}}.
#' @return The combined typed data frame.
#' @details
#' This version of \code{rbind} for \code{typed_frame} performs extra type checking and row validation to ensure consistency and adherence to specified rules. 
#' Refer to the base \code{rbind} documentation for additional details on combining data frames: \code{\link[base]{rbind}}.
#'
#' @export
rbind.typed_frame <- function(..., deparse.level = 1) {
    dfs <- list(...)
    base_df <- dfs[[1]]

    for (df in dfs[-1]) {
        # Validate number of columns
        if (ncol(df) != ncol(base_df)) {
            stop("Number of columns must match")
        }

        # Convert types to match base_df
        for (col_name in names(attr(base_df, "col_types"))) {
            col_type <- class(base_df[[col_name]])
            df[[col_name]] <- as(df[[col_name]], col_type)
        }

        # Validate rows with row_callback
        row_callback <- attr(base_df, "row_callback")
        if (!is.null(row_callback)) {
            for (i in seq_len(nrow(df))) {
                row <- df[i, , drop = FALSE]
                result <- row_callback(row)
                if (!isTRUE(result)) {
                    stop(sprintf("Row %d failed validation: %s", i, as.character(result)))
                }
            }
        }
    }

    result <- do.call(base::rbind, c(dfs, deparse.level = deparse.level))

    class(result) <- class(base_df)
    attr(result, "col_types") <- attr(base_df, "col_types")
    attr(result, "freeze_n_cols") <- attr(base_df, "freeze_n_cols")
    attr(result, "row_callback") <- attr(base_df, "row_callback")
    attr(result, "allow_na") <- attr(base_df, "allow_na")
    attr(result, "on_violation") <- attr(base_df, "on_violation")

    return(result)
}

#' Summary method for typed data frames
#'
#' @description
#' Provides a summary of the typed data frame, including validation status.
#'
#' @param x A typed data frame.
#' @return Summary information of the typed data frame.
#' @export
summary.typed_frame <- function(x) {
    cat("Typed data frame summary:\n")
    cat(sprintf("Number of rows: %d\n", nrow(x)))
    cat(sprintf("Number of columns: %d\n", ncol(x)))
    cat("Column types:\n")
    for (name in names(attr(x, "col_types"))) {
        cat(sprintf("  %s: %s\n", name, format(attr(x, "col_types")[[name]])))
    }
    cat(sprintf("Freeze columns: %s\n", ifelse(attr(x, "freeze_n_cols"), "Yes", "No")))
    cat(sprintf("Allow NA: %s\n", ifelse(attr(x, "allow_na"), "Yes", "No")))
    cat(sprintf("On violation: %s\n", attr(x, "on_violation")))

    cat("Validation status:\n")
    if (!is.null(attr(x, "row_callback"))) {
        errors <- list()
        for (i in seq_len(nrow(x))) {
            row <- x[i, , drop = FALSE]
            result <- attr(x, "row_callback")(row)
            if (!isTRUE(result)) {
                errors <- c(errors, sprintf("Row %d failed validation: %s", i, as.character(result)))
            }
        }
        if (length(errors) > 0) {
            cat("  Validation errors:\n")
            for (error in errors) {
                cat(sprintf("    %s\n", error))
            }
        } else {
            cat("  All rows passed validation.\n")
        }
    } else {
        cat("  No row callback defined for validation.\n")
    }
}
