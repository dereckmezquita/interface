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
#' @return A function that creates typed data frames. When called, this function returns
#'         an object of class 'typed_frame' (which also inherits from the base frame class used, i.e. data.frame, data.table).
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

    creator <- function(...) {
        df <- frame(...)
        errors <- list()

        # check for missing columns
        for (col_name in names(col_types)) {
            if (!(col_name %in% names(df))) {
                errors <- append(errors, sprintf("Required column '%s' is missing", col_name))
            }
        }

        # missing cols check
        if (length(errors) > 0) {
            errors <- append(errors, sprintf("Missing columns: %s", paste(names(col_types), collapse = ", ")))
        }

        # number of columns check
        if (freeze_n_cols && ncol(df) != length(col_types)) {
            errors <- append(
                errors, sprintf("Number of columns must match: expected %d, got %d", length(col_types), ncol(df))
            )
        }

        # na check
        if (!allow_na && any(is.na(df))) {
            na_cols <- names(df)[sapply(df, function(x) return(any(is.na(x))) )]
            errors <- append(errors, sprintf("NA values found in column(s): %s", paste(na_cols, collapse = ", ")))
        }

        # go over each column and check the types
        for (col_name in names(col_types)) {
            curr_col_data <- df[[col_name]]
            curr_col_type <- col_types[[col_name]]

            # check for enum types
            if (inherits(curr_col_type, "enum_generator")) {
                enum_errors <- list()

                # type.frame generator function allows one to create a new frame object
                # we have to iterate over every value in the column and check it's typings
                # try catch to apply the enum generator function to the values provided for each record
                for (i in seq_along(curr_col_data)) {
                    tried <- tryCatch({
                        new_value <- curr_col_type(curr_col_data[[i]])
                        # NOTE: do not use explicit return here, it will break the loop
                        list(success = TRUE, value = new_value)
                    }, error = function(e) {
                        list(
                            success = FALSE,
                            value = NULL,
                            error = sprintf("Row %d: %s", i, e$message)
                        )
                    })

                    if (!tried$success) {
                        enum_errors <- c(enum_errors, tried$error)
                    }
                }

                if (length(enum_errors) > 0) {
                    errors <- append(errors, enum_errors)
                }

                df[[col_name]] <- tried$value
            } else {
                # For non-enum columns, use the original type
                error <- validate_property(col_name, curr_col_data, curr_col_type)
                if (!is.null(error)) {
                    errors <- append(errors, error)
                }
            }
        }

        # Process rows with callback
        if (!is.null(row_callback)) {
            for (i in seq_len(nrow(df))) {
                row <- df[i, , drop = FALSE]
                tried <- tryCatch({
                    new_value <- row_callback(row)
                    list(success = TRUE, value = new_value)
                }, error = function(e) {
                    list(
                        success = FALSE,
                        value = NULL,
                        error = sprintf("Row %d: %s", i, e$message)
                    )
                })

                if (!tried$success) {
                    errors <- append(errors, tried$error)
                }

                df[i, ] <- tried$value
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

#' Modify a user-defined function to return a single logical value
#' 
#' @description
#' Modifies a user-defined function to wrap its body in an all() call, ensuring that it returns a single logical value instead of a vector.
#' 
#' It uses bquote() to create a new body for the function.
#' The .() inside bquote() inserts the original body of the function.
#' The all() function wraps around the original body.
#' 
#' @param user_fun A user-defined function.
#' @return The modified function.
wrap_fun_in_all <- function(user_fun) {
    body(user_fun) <- bquote({
        all(.(body(user_fun)))
    })
    return(user_fun)
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
    if (!attr(value, "allow_na") && any(is.na(value))) {
        handle_violation("NA values are not allowed", attr(value, "on_violation"))
    }

    # Process new or modified rows with callback
    if (!is.null(attr(x, "row_callback"))) {
        # TODO: test what happens if i is not passed? Do we need to handle this and test all rows or none at all?
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
#' @param col_name The name of the column to modify or add.
#' @param value The new value to assign.
#' @return The modified typed data frame.
#' @export
`$<-.typed_frame` <- function(x, col_name, value) {
    # Check if adding new columns is allowed
    if (attr(x, "freeze_n_cols") && !(col_name %in% names(x))) {
        stop("Adding new columns is not allowed when freeze_n_cols is TRUE")
    }

    # Perform the assignment
    x <- NextMethod()

    # Re-validate the modified data
    if (col_name %in% names(attr(x, "col_types"))) {
        col_type <- attr(x, "col_types")[[col_name]]

        error <- validate_property(col_name, value, col_type)
        if (!is.null(error)) {
            handle_violation(error, attr(x, "on_violation"))
        }
    }

    # Check for NA values
    if (!attr(x, "allow_na") && any(is.na(value))) {
        handle_violation("NA values are not allowed", attr(x, "on_violation"))
    }

    # TODO: really review if a row callback is useful at all
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
#' @return No return value, called for side effects.
#'         Prints a summary of the typed data frame to the console, including its dimensions,
#'         column specifications, frame properties, and a preview of the data.
#' @importFrom utils head
#' @export
print.typed_frame <- function(x, ...) {
    # Determine the base frame type
    base_frame_type <- class(x)[2]  # The second class should be the base frame type

    cat("Typed Data Frame Summary:\n")
    cat(sprintf("Base Frame Type: %s\n", base_frame_type))
    cat(sprintf("Dimensions: %d rows x %d columns\n", nrow(x), ncol(x)))

    cat("\nColumn Specifications:\n")
    col_types <- attr(x, "col_types")
    max_name_length <- max(nchar(names(col_types)))

    for (name in names(col_types)) {
        type_desc <- get_type_description(col_types[[name]])
        cat(sprintf("  %-*s : %s\n", max_name_length, name, type_desc))
    }

    cat("\nFrame Properties:\n")
    cat(sprintf("  Freeze columns : %s\n", ifelse(attr(x, "freeze_n_cols"), "Yes", "No")))
    cat(sprintf("  Allow NA       : %s\n", ifelse(attr(x, "allow_na"), "Yes", "No")))
    cat(sprintf("  On violation   : %s\n", attr(x, "on_violation")))
    
    cat("\nData Preview:\n")
    print(as.data.frame(utils::head(x, 5)))

    if (nrow(x) > 5) {
        cat(sprintf("\n... with %d more rows\n", nrow(x) - 5))
    }
}

# Helper function to determine the type description
get_type_description <- function(col_type) {
    if (inherits(col_type, "enum_generator")) {
        return(paste0("Enum(", paste(attr(col_type, "values"), collapse = ", "), ")"))
    }

    if (is.function(col_type)) {
        if (identical(col_type, integer)) return("integer")
        if (identical(col_type, numeric)) return("numeric")
        if (identical(col_type, character)) return("character")
        if (identical(col_type, logical)) return("logical")
        return("custom function")
    }

    return(class(col_type)[1])
}

#' Combine typed data frames row-wise
#'
#' @description
#' This function combines multiple typed data frames row-wise, ensuring type consistency and applying row validation rules.
#' It extends the base \code{\link[base]{rbind}} function by adding type checks and row validation based on the specified rules for typed data frames.
#'
#' @param ... Typed data frames to combine.
#' @param deparse.level See \code{\link[base]{rbind}}.
#' @return The combined typed data frame. The returned object is of class 'typed_frame'
#'         and inherits all properties (column types, validation rules, etc.) from the first data frame in the list.
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

        # TODO: go over each col of frames we're adding and run validation; or force these to be typed_frame objects
        if (!identical(class(df), "typed_frame")) {
            stop("All data frames must be typed_frame objects")
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
