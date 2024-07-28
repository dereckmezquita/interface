# Test the Enum S3 Class implementation

# Create an enum type for colors
Colors <- enum("red", "green", "blue")

# Create enum values
color1 <- Colors("red")
print(color1)  # Should print: Enum: red

# This should work
color2 <- Colors("green")
print(color2)  # Should print: Enum: green

# This should throw an error
try(Colors("yellow"))

# Get the value of an enum
print(value(color1))  # Should print: "red"

# Check the type
print(typeof(value(color1)))  # Should print: character

# Test is.enum
print(is.enum(color1))  # Should print: TRUE

# Test as.character
print(as.character(color1))  # Should print: "red"

# Create an enum type for numbers
Numbers <- enum(1, 2, 3)

# Create enum values
num1 <- Numbers(1)
print(num1)  # Should print: Enum: 1

# This should throw an error (wrong type)
try(Numbers("1"))

# Test equality
print(color1 == Colors("red"))  # Should print: TRUE
print(color1 == color2)  # Should print: FALSE

# Get all allowed values of an enum object
print(enum_values(color1))
print(enum_values(num1))

# Use in a function
test_color <- function(color) {
  if (color == Colors("red")) {
    print("The color is red!")
  } else {
    print("The color is not red.")
  }
}

test_color(color1)
test_color(color2)

# Attempt to change value (this will work, but it's not recommended)
color1$value <- "blue"
print(color1)  # Should print: Enum: blue

# But this will still throw an error
try(color1$value <- "yellow")



yeet <- factor("a", levels = letters[1:3])

yeet[1] <- "z"
