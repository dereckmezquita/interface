# Define the S3 class constructor
MyS3Class <- function(value) {
  structure(list(value = value), class = "MyS3Class")
}

# Define print method for MyS3Class
print.MyS3Class <- function(x, ...) {
  cat("MyS3Class object with value:", x$value, "\n")
}

# Create an active binding function
create_active_binding <- function(name, initial_value) {
  value <- initial_value
  
  # Remove existing binding if it exists
  if (exists(name, envir = .GlobalEnv)) {
    rm(list = name, envir = .GlobalEnv)
  }
  
  makeActiveBinding(
    name,
    function(v) {
      if (missing(v)) {
        return(value)
      } else {
        cat("hello\n")
        value <<- MyS3Class(v)
      }
    },
    .GlobalEnv
  )
}

# Create an object of MyS3Class
obj <- MyS3Class(10)

# Create an active binding for the object
create_active_binding("obj", obj)

# Access the value
print(obj)  # Should print 10

# Assign a new value and trigger the custom logic
obj <- 29  # Should print "hello"
print(obj)  # Should print 29