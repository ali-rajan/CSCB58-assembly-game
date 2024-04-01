# Pseudocode

## Setup

```
player_x = current x-value
player_y = current y-value
player_y_velocity = current vertical velocity
platforms_x = []
platforms_y = []
enemies_x = []
enemies_y = []

initialize_entities(entities_x, entities_y, num_entities, min_x, max_x, min_y, max_y)
  for i in 0, ..., num_entities:
    entities_x[i] = random x value in range
    entities_y[i] = random y value in range

initialize_platforms():
  wraps initialize_entities

initialize_enemies():
  wraps initialize_entities
```

## Entity Movement

```
update_platforms():
  for each platform:
    if platform is completely to the left of the screen:
      randomly generate new coordinates off screen to the right
    else:
      move_platform_left()  # TODO

update_enemies():
  for each enemy:
    if enemy is completely to the left of the screen:
      randomly generate new coordinates off screen to the right
      enemies_evaded++
    else:
      move_enemy_left()    # TODO

player_collisions():
  # TODO!!
  for each pixel on player's left perimeter:
    if pixel belongs to a platform:
      set player right of platform
    else if pixel belongs to an enemy:
      # TODO: handle enemy collision
  for each pixel on player's right perimeter:
    # Symmetric case

  for each pixel on player's bottom perimeter:
    if pixel belongs to a platform:
      set player above platform
      if player_y_velocity is downward:
        set player_y_velocity to neutral
    else if pixel belongs to an enemy:
      # Handle enemy collision
  for each pixel on player's top perimeter:
    if pixel belongs to a platform:
      set player below platform
      if player_y_velocity is upward:
        set player_y_velocity to downward
    else if pixel belongs to an enemy:
      # Handle enemy collision

# TODO: player movement logic
update_player()
```

## Event Handlers

```
handle_keypress():
  key = key pressed
  if key == "q"
      game_run = false
  else if key == "r"
    jump to the initialize stage (before the main loop)
  else if key == "w":
    player_jump()
  else if key == "a":
    fill current player position with background colour
    increment player_x  # draw player after this
  else if key == "d":
    fill current player position with background colour
    decerement player_x  # draw player after this

is_game_over():
  if player is below the screen:  # TODO: collision logic
    return true
  else if player.hp <= 0:
    return true
  else:
    return false

is_game_won():
  if enemies_evaded >= evasion_target:
    return true
  else:
    return false
```

## Main Loop

```
initialize_enemies()
initialize_platforms()
while game_run:
  # TODO: collison logic
  if game_over():
    display game over screen
  else if game_won():
    display game won screen

  handle_keypress()
  draw_enemies()
  draw_platforms()

  draw_player()
  
  # TODO
  update_player()
  update_platforms()
  update_enemies()
```
