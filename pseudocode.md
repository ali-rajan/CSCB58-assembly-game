# Pseudocode

*This is not up-to-date;* it was only used for brainstorming earlier towards the start of the project.

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
    entity_collision(player, platform)
    if platform collides below player:
      if player_y_velocity is downward:
        position player above platform
        set player_y_velocity to neutral
    else if platform collides above player:
      if player_y_velocity is upward:
        position player below platform
        set player_y_velocity downward
    else if platform collides left of player:
      position player right of platform
    else if platform collides right of player:
      position player left of platform

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

  handle_keypress()

  draw_enemies()
  draw_platforms()
  draw_player()

  update_player()
  update_platforms()
  update_enemies()
```
