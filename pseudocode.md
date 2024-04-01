# Pseudocode

## Setup

```
player_x = current x-value
player_y = current y-value
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
  for platform in platforms:
    if platform is completely to the left of the screen:
      randomly generate new coordinates off screen to the right
    else:
      move_platform_left()  # TODO

update_enemies():
  for enemy in enemies:
    if enemy is completely to the left of the screen:
      randomly generate new coordinates off screen to the right
      enemies_evaded++
    else:
      move_enemy_left()    # TODO

player_collisions():
  # TODO!!
  for each platform:
    if platform collides below player:
    else if platform collides left of player:
      player_platform_left_collision = true
    else if platform collides right of player:
      player_platform_right_collision = true
    else if platform collides above player:

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
    player_move_left()
  else if key == "d":
    player_move_right()

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

  draw_player()
  draw_enemies()
  draw_platforms()

  handle_keypress()
  update_player()
  update_platforms()
  update_enemies()
```
