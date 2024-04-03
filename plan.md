# Project Plan

## General Idea

- Auto-scrolling platforms
  - Random heights, cannot be too high for jumping to work at highest point
  - Same length for all platforms
  - Collision detection between player and platforms
- Square players and enemies
  - Different colours for each type of entity
  - Collision between player and enemy to lose HP
- Enemies are obstacles moving horizontally towards player
  - Shooting lasers
- Gravity and jumping along with horizontal movement
- Fail condition: player falls too low or all HP lost to collisions
- Win condition: all platforms crossed (for a certain platform count)
- Hearts icons to count HP
- Score bar based on number of platforms crossed
- Restart or quit at any point with certain key presses

## Milestone 1

- [x] Draw blank canvas
- [x] Draw player
- [x] Draw platforms
  - [x] Single platform
  - [x] Multiple platforms
  - [x] Random platform positioning
- [x] Draw enemies
  - [x] Single enemy
  - [x] Multiple enemies

## Milestone 2

- [x] Player horizontal movement
- [x] Gravity
- [x] Player-platform collision
  - [x] Vertical collision
  - [x] Horizontal collision
- [x] Player jumping
- [x] Restart and quit key presses
- [x] Enemy collision

## Milestone 3

- [x] HP
  - [x] Draw hearts
  - [x] Decrement on enemy collision
- [ ] Score
  - [ ] Draw bar based on number of platforms crossed
  - [ ] Increment on platform crossed
- [x] Fail condition
  - [x] Falling too low
  - [x] All HP lost to collisions
  - [ ] Draw "game over" screen
- [ ] Win condition
  - [ ] All enemies evaded
  - [ ] "You win" screen

## Milestone 4

- [ ] Scrolling platforms
- [ ] Scrolling enemies
- [ ] Shooting enemies

## Bugs

- [ ] Platform both below and above the player
    - Player is moved below the lower platform
- [ ] Ceiling spiderman
  - Player stays attached to the ceiling if reached when jumping
