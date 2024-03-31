# Pseudocode

## Setup

```
platforms_x = []
platforms_y = []
enemies_x = []
enemies_y = []

initialize_platforms()
initialize_player()
initialize_enemies()
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
