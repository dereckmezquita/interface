box::use(dt = data.table)
# box::use(interface[type.frame, enum])

# Now create the PlayerFrame with an in-place enum declaration for 'shoots'
PlayerFrame <- type.frame(
    frame = dt$data.table,
    col_types = list(
        name = character,
        jersey_number = integer,
        position = character,
        birth_date = character,
        age = integer,
        birthplace = character,
        nationality = character,
        shoots = enum("Left", "Right"),
        height_imperial = numeric,
        height_metric = numeric,
        weight_imperial = numeric,
        weight_metric = numeric
    )
)

# Now create the player_frame
player_frame <- PlayerFrame(
    name = "John Doe",
    jersey_number = 42L,
    position = "Center",
    birth_date = "January 1, 2000",
    age = 21L,
    birthplace = "Toronto, ON, CAN",
    nationality = "CAN",
    shoots = "Left",
    height_imperial = 6.0,
    height_metric = 183,
    weight_imperial = 200,
    weight_metric = 91
)

# Print the player_frame to verify
print(player_frame)

class(player_frame$shoots)

player_frame$shoots

class(player_frame$shoots)
class(player_frame$shoots)
str(player_frame$shoots)
