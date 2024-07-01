library(R6)

InterfaceSystem <- R6Class("InterfaceSystem",
  public = list(
    interfaces = list(),
    
    define_interface = function(name, properties) {
      self$interfaces[[name]] <- properties
    },
    
    implement = function(interface_name, ...) {
      if (is.null(self$interfaces[[interface_name]])) {
        stop(paste("Interface", interface_name, "not defined"))
      }
      
      obj <- list(...)
      interface <- self$interfaces[[interface_name]]
      
      # Check if all required properties are present
      missing_props <- setdiff(names(interface), names(obj))
      if (length(missing_props) > 0) {
        stop(paste("Missing properties:", paste(missing_props, collapse = ", ")))
      }
      
      # Check types of properties
      for (prop in names(interface)) {
        expected_type <- interface[[prop]]
        actual_value <- obj[[prop]]
        
        if (!inherits(actual_value, expected_type)) {
          stop(paste("Property", prop, "should be of type", expected_type))
        }
      }
      
      # Create an R6 class dynamically
      className <- paste0(interface_name, "Impl")
      ImplClass <- R6Class(className,
        public = obj,
        active = lapply(names(obj), function(n) function(value) {
          if (missing(value)) self[[n]]
          else stop("Cannot modify readonly property")
        })
      )
      
      ImplClass$new()
    }
  )
)

# Example usage
system <- InterfaceSystem$new()

# Define an interface
system$define_interface("Person", list(
  name = "character",
  age = "numeric",
  email = "character"
))

# Create an object implementing the interface
john <- system$implement("Person",
  name = "John Doe",
  age = 30,
  email = "john@example.com"
)

# Accessing properties
print(john$name)  # "John Doe"
print(john$age)   # 30

# This would raise an error due to incorrect type
# try(system$implement("Person",
#   name = "Jane Doe",
#   age = "thirty",  # This should be a number
#   email = "jane@example.com"
# ))

# This would raise an error due to missing property
# try(system$implement("Person",
#   name = "Bob Smith",
#   age = 25
#   # missing email
# ))