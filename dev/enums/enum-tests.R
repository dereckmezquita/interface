# Source all R files
R_files <- list.files("./R", full.names = TRUE)
for (file in R_files) {
    source(file)
}

# Using enum types in interfaces
Car <- interface(
   colour = enum("red", "yellow", "black"),
   size = numeric
)

# This should work
my_car <- Car(colour = "red", size = 5)
print(my_car$colour)  # Should print: Enum: red

# This should throw an error
try(Car(colour = "green", size = 5))

# This should throw an error
try(my_car$colour <- "green")

# Using enum types standalone
AllowedColours <- enum("red", "yellow")

# This should throw an error
try(AllowedColours("green"))

# This should work
colour1 <- AllowedColours("red")
print(colour1)
print(class(colour1))

# FIX THIS: THIS SHOULD THROW AN ERROR BUT IT DOESN'T CURRENTLY
try({colour1 <- "yeet"})


AllowedColours <- enum("red", "yellow")

yeet <- AllowedColours("red")
yeet[1] <- "yellow"
print(yeet)
yeet[1] <- "red"
print(yeet)
yeet[1] <- "green"
