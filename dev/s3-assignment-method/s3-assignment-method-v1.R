# Define the S3 class constructor with active binding built-in
MyS3Class <- function(name, value) {
  e <- new.env()
  e$value <- value
  makeActiveBinding(
    name,
    function(v) {
      if (missing(v)) {
        return(e$value)
      } else {
        cat("hello\n")
        if (v == 29) stop("Yeet")
        e$value <<- v
      }
    },
    .GlobalEnv
  )
  assign(name, e$value, envir = .GlobalEnv)
}

# Create an object of MyS3Class
MyS3Class("obj", 10)

# Access the value
print(obj)  # Should print 10

# Assign a new value and trigger the custom logic
obj <- 29  # Should print "hello"
print(obj)  # Should print 29
