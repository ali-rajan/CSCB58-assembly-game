#####################################################################
#
# CSCB58 Winter 2024 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Ali Rajan, 1009034386, rajanal1, ali.rajan@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################


#################### CONSTANTS ####################

# Display
.eqv DISPLAY_BASE_ADDRESS 0x10008000    # $gp
.eqv DISPLAY_END_ADDRESS 0x1000bffc     # Bottom-right unit's address

# Note: on my screen, each unit is 5 pixels in the MIPS Bitmap Display as the display is 320x320 instead of 256x256
# (measured using a screen ruler)
.eqv DISPLAY_WIDTH 64
.eqv DISPLAY_HEIGHT 64

# UI dimensions and positions in units (not pixels) (TODO: remove unused constants)
.eqv UI_HEALTH_WIDTH 2
.eqv UI_HEALTH_HEIGHT 2
# .eqv UI_SCORE_BAR_UNIT_WIDTH 1
# .eqv UI_SCORE_BAR_HEIGHT 2

.eqv UI_HEALTH_Y 1
# .eqv UI_SCORE_BAR_START_X 62            # 2nd last column
# .eqv UI_SCORE_BAR_Y 1
.eqv UI_DIVIDER_Y 4                     # max(UI_HEALTH_HEIGHT, UI_SCORE_BAR_HEIGHT) + padding
.eqv UI_DIVIDER_THICKNESS 1
.eqv UI_END_Y 5                         # UI_DIVIDER_Y + UI_DIVIDER_THICKNESS

.eqv UI_HEALTH_1_X 1                  # i-th x-value is (left padding) + (x-spacing + UI_HEALTH_WIDTH) * i
.eqv UI_HEALTH_2_X 4
.eqv UI_HEALTH_3_X 7

# Entity dimensions and positions in units (not pixels)
.eqv PLAYER_WIDTH 3
.eqv PLAYER_HEIGHT 3

# Player's initial top-left unit position
.eqv PLAYER_INITIAL_X 2
.eqv PLAYER_INITIAL_Y 29
.eqv PLATFORM_WIDTH 12
.eqv PLATFORM_THICKNESS 1
# Platform spawn position ranges for the top-left unit (TODO: tweak values)
.eqv PLATFORM_SPAWN_MIN_X 62
.eqv PLATFORM_SPAWN_MAX_X 120
.eqv PLATFORM_SPAWN_MIN_Y 8                   # UI_END_Y + PLAYER_HEIGHT
.eqv PLATFORM_SPAWN_MAX_Y 63
# TODO: if there is a platform both above and below the player, collision detection can break (e.g. the values below)
# .eqv PLATFORM_SPAWN_MIN_Y 28
# .eqv PLATFORM_SPAWN_MAX_Y 32
.eqv ENEMY_WIDTH 2
.eqv ENEMY_HEIGHT 2
# Enemy spawn position ranges for the top-left unit
.eqv ENEMY_MIN_X 40
.eqv ENEMY_MAX_X 61
# TODO: adjust these so enemies aren't redundant because they're out of reach vertically
.eqv ENEMY_MIN_Y UI_END_Y
.eqv ENEMY_MAX_Y 61

# Colours
.eqv COLOUR_BACKGROUND 0x000000     # black
.eqv COLOUR_PLATFORM 0x964B00       # brown
.eqv COLOUR_PLAYER 0x0000FF         # blue
.eqv COLOUR_ENEMY 0xFFA500          # orange
.eqv COLOUR_UI_DIVIDER 0xFFFFFF     # white
.eqv COLOUR_UI_HEALTH 0xFF0000      # red

# Keyboard
.eqv KEYSTROKE_ADDRESS 0xffff0000
.eqv ASCII_W 0x77
.eqv ASCII_A 0x61
.eqv ASCII_D 0x64
.eqv ASCII_R 0x72
.eqv ASCII_Q 0x71

# Movement (TODO: tweak deltas and FPS)
.eqv SLEEP_DURATION 100             # sleep duration in milliseconds
.eqv PLAYER_DELTA_X 1               # x-value increment for each keypress
.eqv PLAYER_DELTA_Y 1
.eqv PLAYER_JUMP_APEX_TIME 15
# Bounds to prevent player from going off-screen
.eqv PLAYER_MIN_X 0
.eqv PLAYER_MAX_X 61
.eqv PLAYER_MIN_Y UI_END_Y
.eqv PLAYER_MAX_Y 61

.eqv PLATFORM_DELTA_X 1

.eqv PLAYER_MAX_HEALTH 3

.eqv COLLISION_NONE 100000
.eqv COLLISION_TOP 100001
.eqv COLLISION_BOTTOM 100002
.eqv COLLISION_LEFT 100003
.eqv COLLISION_RIGHT 100004

.eqv NUM_PLATFORMS 5
.eqv NUM_ENEMIES 3

.data

player_x: .word PLAYER_INITIAL_X
player_y: .word PLAYER_INITIAL_Y
player_y_velocity: .word 0
player_jump_time: .word 0
player_health: .word PLAYER_MAX_HEALTH

# Coordinates of each platform's top-left unit
platforms_x: .word 0:NUM_PLATFORMS
platforms_y: .word 0:NUM_PLATFORMS

# Coordinates of each enemy's top-left unit
enemies_x: .word 0:NUM_ENEMIES
enemies_y: .word 0:NUM_ENEMIES

# Coordinates of each health icon's top-left unit (y-value is same for all)
health_icons_x: .word UI_HEALTH_1_X, UI_HEALTH_2_X, UI_HEALTH_3_X

# Debug text
keypress_text_debug: .asciiz "key pressed: "
collision_top_debug: .asciiz "top collision\n"
collision_bottom_debug: .asciiz "bottom collision\n"
collision_left_debug: .asciiz "left collision\n"
collision_right_debug: .asciiz "right collision\n"
health_lost_debug: .asciiz "lives remaining: "
newline: .asciiz "\n"

.text

.globl main

j main


#################### UTILITIES ####################

# TODO: remove print macros once done debugging

# Prints the given string.
# Parameters:
    # %str: .asciiz string to print
# Uses:
    # $v0
    # $a0
.macro print_str(%str)
    li $v0, 4
    la $a0, %str
    syscall
.end_macro

# Prints the given register's character value.
# Parameters:
    # %reg: register storing the ASCII value
# Uses:
    # $v0
    # $a0
.macro print_char(%reg)
    li $v0, 11
    move $a0, %reg
    syscall
.end_macro

# Prints the given register's integer value.
# Parameters:
    # %reg: register storing the integer
# Uses:
    # $v0
    # $a0
.macro print_int(%reg)
    li $v0, 1
    move $a0, %reg
    syscall
.end_macro

# Sleeps for SLEEP_DURATION milliseconds.
# Uses:
    # $v0
    # $a0
.macro sleep()
    li $v0, 32
    li $a0, SLEEP_DURATION
    syscall
.end_macro

# Loads the data from the given word into the given register.
# Parameters:
    # %word_addr: address of the word to load
    # %dest_reg: register to load the word into
# Returns:
    # %dest_reg: the word
# Uses:
    # %dest_reg
.macro load_word(%word_addr, %dest_reg)
    la %dest_reg, %word_addr
    lw %dest_reg, 0(%dest_reg)
.end_macro

# Stores the data from the the given register in given word.
# Parameters:
    # %word_addr: address of the word to store data in
    # %src_reg: register to read from
# Uses:
    # $t0
    # %src_reg
.macro store_word(%word_addr, %src_reg)
    la $t0, %word_addr
    sw %src_reg, 0($t0)
.end_macro

# Returns a random integer n satisfying %min <= n <= %max.
# Parameters:
    # %min: the range's minimum, an immediate value
    # %max: the range's maximum, an immediate value
# Returns:
    # $v0: the random integer
# Uses:
    # $a0: random number generator syscall
    # $a1: random number generator syscall
    # $v0
.macro random_integer(%min, %max)
    li $v0, 42              # syscall code for random number generator
    li $a0, 0               # argument for random number generator ID (any integer)
    li $a1, %max
    subi $a1, $a1, %min
    addi $a1, $a1, 1        # $a1 = %max - %min + 1, the upper bound for the syscall random number
    syscall                 # $a0 = random integer n satisfying 0 <= n < %max - %min + 1

    addi $a0, $a0, %min     # $a0 is now some n satisfying %min <= n < %max + 1
    move $v0, $a0
.end_macro

# Computes the framebuffer address of the unit (x, y).
# Parameters:
    # %x: immediate unit x-value
    # %y: immediate unit y-value
# Returns:
    # $v0: the framebuffer address of (x, y)
# Uses:
    # $t0
    # $t1
    # $t2
    # $t3
    # $v0
.macro unit_address(%x, %y)     # TOOD: remove if unused
    li $t0, %x
    li $t1, %y
    li $t2, DISPLAY_WIDTH
    li $t3, DISPLAY_BASE_ADDRESS

    mult $t1, $t2
    mflo $v0
    add $v0, $v0, $t0
    sll $v0, $v0, 2         # $v0 = (y * DISPLAY_WIDTH + x) * 4 = offset from base address
    add $v0, $v0, $t3       # $v0 = offset + DISPLAY_BASE_ADDRESS
.end_macro

# Computes the framebuffer address of the unit (x, y).
# Parameters:
    # %x_reg: register storing the unit's x-value
    # %y_reg: register storing the unit's y-value
# Returns:
    # $v0: the framebuffer address of (x, y)
# Uses:
    # $t2
    # $t3
    # $v0
.macro unit_address_reg(%x_reg, %y_reg)
    li $t2, DISPLAY_WIDTH
    li $t3, DISPLAY_BASE_ADDRESS

    mult %y_reg, $t2
    mflo $v0
    add $v0, $v0, %x_reg
    sll $v0, $v0, 2         # $v0 = (y * DISPLAY_WIDTH + x) * 4 = offset from base address
    add $v0, $v0, $t3       # $v0 = offset + DISPLAY_BASE_ADDRESS
.end_macro

# Returns 1 if the given unit is on-screen and 0 otherwise.
# Parameters:
    # %x_reg: register storing the unit's x-value
    # %y_reg: register storing the unit's y-value
# Returns:
    # $v0: 1 if the unit is on-screen, 0 otherwise
# Uses:
    # $t0
    # $v0
.macro unit_is_on_screen(%x_reg, %y_reg)
    add $v0, $zero, $zero   # return value (changed if unit is on-screen)

    # Check if 0 <= x < DISPLAY_WIDTH
    blt %x_reg, $zero, _unit_is_on_screen_end
    li $t0, DISPLAY_WIDTH
    bge %x_reg, $t0, _unit_is_on_screen_end

    # Check if 0 <= y < DISPLAY_HEIGHT
    blt %y_reg, $zero, _unit_is_on_screen_end
    li $t0, DISPLAY_HEIGHT
    bge %y_reg, $t0, _unit_is_on_screen_end

    li $v0, 1   # return 1 if unit is on-screen
_unit_is_on_screen_end:
.end_macro


#################### DRAWING ####################

# Fills the given unit with the given colour. Does not check if the unit address given is valid.
# Parameters:
    # %unit_reg: register storing the address of the unit to colour
    # %colour: colour (immediate value)
# Uses:
    # $t0
.macro colour_unit_reg(%unit_reg, %colour)
    li $t0, %colour
    sw $t0, 0(%unit_reg)
.end_macro

# Fills the given unit with the given colour if the unit address given is valid. No effect otherwise.
# Uses:
    # $t0: unit_is_on_screen and macro
    # $t2: unit_address_reg
    # $t3: unit_address_reg
    # $v0: unit_is_on_screen and unit_address_reg
.macro colour_unit(%x_reg, %y_reg, %colour)
    unit_is_on_screen(%x_reg, %y_reg)
    beq $v0, $zero, _colour_unit_end    # do not colour unit if it's off-screen

    li $t0, %colour
    unit_address_reg(%x_reg, %y_reg)
    sw $t0, 0($v0)

_colour_unit_end:
.end_macro

# Fills the screen with the given colour.
# Parameters:
    # %colour: colour (immediate value)
# Uses:
    # $t0: colour_unit_reg
    # $s0
.macro fill_background(%colour)
    li $s0, DISPLAY_BASE_ADDRESS

_fill_background_loop:
    bgt $s0, DISPLAY_END_ADDRESS, _fill_background_loop_end     # while the last unit is not reached
    colour_unit_reg($s0, %colour)
    add $s0, $s0, 4                             # next unit is sizeof(word) ahead
    j _fill_background_loop

_fill_background_loop_end:
.end_macro

# Draws a rectangular entity with the specified attributes.
# Parameters:
    # %x_reg: register storing the x-value of the rectangle's top-left unit
    # %y_reg: register storing the y-value of the rectangle's top-left unit
    # %width: the rectangle's width in units
    # %height: the rectangle's height in units
    # %colour: the rectangle's colour (an immediate value)
# Uses:
    # $s0
    # $s1
    # $s2
    # $s3
    # $t0: colour_unit
    # $t2: colour_unit
    # $t3: colour_unit
    # $v0: colour_unit
.macro draw_entity(%x_reg, %y_reg, %width, %height, %colour)
    move $s0, %x_reg    # $s0 = current x
    move $s1, %y_reg    # $s1 = current y

    add $s2, %x_reg, %width     # $s2 = end_x (exclusive)
    add $s3, %y_reg, %height    # $s3 = end_x (exclusive)

_draw_for_each_y:
    bge $s1, $s3, _draw_entity_end          # while the last row is not reached

    _draw_for_each_x:
        bge $s0, $s2, _for_each_x_end       # while the last unit in the row is not reached
        colour_unit($s0, $s1, %colour)
        addi $s0, $s0, 1
        j _draw_for_each_x

    _for_each_x_end:
        move $s0, %x_reg
        addi $s1, $s1, 1

    j _draw_for_each_y

_draw_entity_end:
.end_macro


#################### ENTITIES ####################

# Generates random x and y-values in the given ranges and stores them in the specified registers.
# Parameters:
    # %min_x: minimum possible x-value
    # %max_x: maximum possible x-value
    # %min_y: minimum possible y-value
    # %max_y: maximum possible y-value
    # %dest_x_reg: register to store the x-value in
    # %dest_y_reg: register to store the y-value in
# Uses:
    # $a0: random_integer
    # $a1: random_integer
    # $v0: random_integer
    # %dest_x_reg
    # %dest_y_reg
.macro generate_random_position(%min_x, %max_x, %min_y, %max_y, %dest_x_reg, %dest_y_reg)
    random_integer(%min_x, %max_x)
    move %dest_x_reg, $v0
    random_integer(%min_y, %max_y)
    move %dest_y_reg, $v0
.end_macro

# Randomly generates x and y-values for all enemies based on the given ranges, storing them in the given arrays.
# Parameters:
    # %entities_x: the array of x-values
    # %entities_y: the array of y-values
    # %num_entities: the number of entities (an immediate value)
    # %min_x: minimum possible x-value
    # %max_x: maximum possible x-value
    # %min_y: minimum possible y-value
    # %max_y: maximum possible y-value
# Uses:
    # $t0
    # $t1
    # $t2
    # $t3
    # $t4
    # $t5
    # $t6
    # $t7
    # $a0: generate_random_position
    # $a1: generate_random_position
    # $v0: generate_random_position
.macro initialize_entities(%entities_x, %entities_y, %num_entities, %min_x, %max_x, %min_y, %max_y)
    # TODO: maybe separate this into a macro that randomly fills one array at a time (could be useful for platform
    # initializing where only y-values are randomized)
    la $t0, %entities_x
    la $t1, %entities_y
    add $t2, $zero, $zero   # $t2 = array offset = sizeof(word) * i (for the index i)
    li $t3, %num_entities
    sll $t3, $t3, 2         # $t3 = %num_entities * sizeof(word)

_initialize_entities_loop:                  # $t2 = array offset
    bge $t2, $t3, _initialize_entities_end  # while i < %num_entities
    add $t4, $t0, $t2
    add $t5, $t1, $t2

    generate_random_position(%min_x, %max_x, %min_y, %max_y, $t6, $t7)
    sw $t6, 0($t4)  # %entities_x[i] = random x-value
    sw $t7, 0($t5)  # %entities_y[i] = random y-value

    addi $t2, $t2, 4
    j _initialize_entities_loop

_initialize_entities_end:
.end_macro

# TODO: save $s0 - $s6 in stack if this is called elsewhere that uses those registers
# Draws all the entities based on their coordinates stored in the given arrays, their given dimensions, and the colour
# specified.
# Parameters:
    # %entities_x: array of x-values
    # %entities_y: array of y-values
    # %num_entities: number of entities (an immediate value)
    # %entity_width: width of each entity (an immediate value)
    # %entity_height: height of each entity (an immediate value)
    # %entity_colour: colour of each entity (an immediate value)
# Uses:
    # $t4
    # $t5
    # $t6
    # $t7
    # $t8
    # $t9
    # $s0: draw_entity
    # $s1: draw_entity
    # $s2: draw_entity
    # $s3: draw_entity
    # $t0: draw_entity
    # $t2: draw_entity
    # $t3: draw_entity
    # $v0: draw_entity
.macro draw_entities(%entities_x, %entities_y, %num_entities, %entity_width, %entity_height, %entity_colour)
    la $t8, %entities_x
    la $t9, %entities_y
    add $t4, $zero, $zero   # $t4 = array offset = sizeof(word) * i (for the index i)
    li $t5, %num_entities
    sll $t5, $t5, 2         # $t5 = %num_entities * sizeof(word)

_draw_entities_loop:
    bge $t4, $t5, _draw_entities_end        # while i < %num_entities

    lw $t6, 0($t8)  # $t6 = entities_x[i]
    lw $t7, 0($t9)  # $t7 = entities_y[i]

    draw_entity($t6, $t7, %entity_width, %entity_height, %entity_colour)

    addi $t4, $t4, 4
    addi $t8, $t8, 4
    addi $t9, $t9, 4
    j _draw_entities_loop

_draw_entities_end:
.end_macro

# Randomly generates x and y-values for all platforms except the first, storing them in platforms_x and platforms_y
# (respectively). The first platform is placed directly below the player's initial position.
# Uses:
    # $t0: initialize_entities and macro
    # $t1: initialize_entities and macro
    # $t2: initialize_entities and macro
    # $t3: initialize_entities and macro
    # $t4: initialize_entities and macro
    # $t5: initialize_entities and macro
    # $t6: initialize_entities and macro
    # $t7: initialize_entities and macro
    # $a0: initialize_entities
    # $a1: initialize_entities
    # $v0: initialize_entities
.macro initialize_platforms()   # TODO: it should be impossible to collide with both platforms on the left and right
    initialize_entities(platforms_x, platforms_y, NUM_PLATFORMS, PLATFORM_SPAWN_MIN_X, PLATFORM_SPAWN_MAX_X, PLATFORM_SPAWN_MIN_Y, PLATFORM_SPAWN_MAX_Y)

    # Overwrite first platform so it's placed below the player
    la $t0, platforms_x
    la $t1, platforms_y
    add $t2, $zero, $zero   # $t2 = array offset = sizeof(word) * i (for the index i)
    li $t3, NUM_PLATFORMS
    sll $t3, $t3, 2         # $t3 = NUM_PLATFORMS * sizeof(word)

    add $t4, $t0, $t2           # $t4 = addr(platforms_x[0])
    add $t5, $t1, $t2           # $t5 = addr(platforms_y[0])
    li $t6, PLAYER_INITIAL_X
    li $t7, PLAYER_INITIAL_Y
    addi $t7, $t7, PLAYER_HEIGHT

    sw $t6, 0($t4)
    sw $t7, 0($t5)
.end_macro

# Randomly generated x and y-values for all enemies, storing them in enemies_x and enemies_y (respectively). Wraps
# initialize_entities specifically for initializing enemies.
# Uses:
    # $t0: initialize_entities
    # $t1: initialize_entities
    # $t2: initialize_entities
    # $t3: initialize_entities
    # $t4: initialize_entities
    # $t5: initialize_entities
    # $t6: initialize_entities
    # $t7: initialize_entities
    # $a0: initialize_entities
    # $a1: initialize_entities
    # $v0: initialize_entities
.macro initialize_enemies()
    initialize_entities(enemies_x, enemies_y, NUM_ENEMIES, ENEMY_MIN_X, ENEMY_MAX_X, ENEMY_MIN_Y, ENEMY_MAX_Y)
.end_macro

# Draws all the platforms based on their coordinates stored in platforms_x and platforms_y. Wraps draw_entities
# specifically for drawing platforms.
# Uses:
    # $t4: draw_entities
    # $t5: draw_entities
    # $t6: draw_entities
    # $t7: draw_entities
    # $t8: draw_entities
    # $t9: draw_entities
    # $s0: draw_entities
    # $s1: draw_entities
    # $s2: draw_entities
    # $s3: draw_entities
    # $t0: draw_entities
    # $t2: draw_entities
    # $t3: draw_entities
    # $v0: draw_entities
.macro draw_platforms()
    draw_entities(platforms_x, platforms_y, NUM_PLATFORMS, PLATFORM_WIDTH, PLATFORM_THICKNESS, COLOUR_PLATFORM)
.end_macro

# Draws all the enemies based on their coordinates stored in enemies_x and enemies_y. Wraps draw_entities specifically
# for drawing enemies.
# Uses:
    # $t4: draw_entities
    # $t5: draw_entities
    # $t6: draw_entities
    # $t7: draw_entities
    # $t8: draw_entities
    # $t9: draw_entities
    # $s0: draw_entities
    # $s1: draw_entities
    # $s2: draw_entities
    # $s3: draw_entities
    # $t0: draw_entities
    # $t2: draw_entities
    # $t3: draw_entities
    # $v0: draw_entities
.macro draw_enemies()
    draw_entities(enemies_x, enemies_y, NUM_ENEMIES, ENEMY_WIDTH, ENEMY_HEIGHT, COLOUR_ENEMY)
.end_macro


#################### UI ####################

# Draws the UI divider.
# Uses:
    # $a0
    # $s0: draw_entity
    # $s1: draw_entity
    # $s2: draw_entity
    # $s3: draw_entity
    # $t0: draw_entity
    # $t2: draw_entity
    # $t3: draw_entity
    # $v0: draw_entity
.macro draw_ui_divider()
    li $a0, UI_DIVIDER_Y
    draw_entity($zero, $a0, DISPLAY_WIDTH, UI_DIVIDER_THICKNESS, COLOUR_UI_DIVIDER)
.end_macro

# Draws the health icons in the UI.
# Uses:
    # $v0: draw_entity
    # $s0: draw_entity
    # $s1: draw_entity
    # $s2: draw_entity
    # $s3: draw_entity
    # $t0: draw_entity
    # $t2: draw_entity
    # $t3: draw_entity
    # $t4
    # $t5
    # $t6
    # $t7
    # $t8
.macro draw_health_icons()
    la $t8, health_icons_x
    add $t4, $zero, $zero   # $t4 = array index i
    # li $t5, PLAYER_MAX_HEALTH
    load_word(player_health, $t5)
    li $t7, UI_HEALTH_Y

_draw_health_icons_loop:
    bge $t4, PLAYER_MAX_HEALTH, _draw_health_icons_end  # while i < PLAYER_MAX_HEALTH

    lw $t6, 0($t8)                      # $t6 = health_icons_x[i]
    bge $t4, $t5, _draw_lost_health     # if i >= player_health, the life is lost (fill vacated pixels)

    draw_entity($t6, $t7, UI_HEALTH_WIDTH, UI_HEALTH_HEIGHT, COLOUR_UI_HEALTH)
    j _draw_health_icons_increment

    _draw_lost_health:
        draw_entity($t6, $t7, UI_HEALTH_WIDTH, UI_HEALTH_HEIGHT, COLOUR_BACKGROUND)

_draw_health_icons_increment:
    addi $t4, $t4, 1
    addi $t8, $t8, 4
    j _draw_health_icons_loop

_draw_health_icons_end:
.end_macro


#################### MOVEMENT ####################

# Adds %delta_x to the player's x-coordinate.
# Parameters:
    # %delta_x: change in x-value, an immediate value
# Uses:
    # $t0: store_word
    # $t1
.macro update_player_x(%delta_x)
    load_word(player_x, $t1)
    addi $t1, $t1, %delta_x

    # Prevent player from going out of bounds
    blt $t1, PLAYER_MIN_X, _update_player_x_end
    bgt $t1, PLAYER_MAX_X, _update_player_x_end

    store_word(player_x, $t1)   # update if in bounds

_update_player_x_end:
.end_macro

# Detects whether there is a collision between the player and the given entity, and if so, returns which direction from
# the player the collision is in.
# The collision directions are checked in this order: no collision, bottom, top, left, right; the first detected
# direction is returned.
# Returns:
    # $v0: COLLISION_NONE, COLLISION_TOP, COLLISION_BOTTOM, COLLISION_LEFT, or COLLISION_RIGHT
# Uses:
    # $t0
    # $t1
    # $t2
    # $t3
    # $t4
    # $t5
    # $v0
.macro entity_collision(%x_reg, %y_reg, %width, %height)
    # Load player's perimeter x and y-values
    load_word(player_x, $t0)
    load_word(player_y, $t1)
    addi $t2, $t0, PLAYER_WIDTH
    addi $t3, $t1, PLAYER_HEIGHT
    # Load other entity's perimeter x and y-values
    addi $t4, %x_reg, %width
    addi $t5, %y_reg, %height

    #               left x (inclusive)  right x (exclusive) top y (inclusive)   bottom y (exclusive)
    # Player        $t0                 $t2                 $t1                 $t3
    # Other entity  %x_reg              $t4                 %y_reg              $t5

    # Check if entity collides with player
    li $v0, COLLISION_NONE  # return value
    blt $t2, %x_reg, _entity_collision_end
    blt $t4, $t0, _entity_collision_end
    blt $t3, %y_reg, _entity_collision_end
    blt $t5, $t1, _entity_collision_end

    # Determine collision direction relative to player
    bgt $t3, %y_reg, _no_bottom_collision
    li $v0, COLLISION_BOTTOM
    j _entity_collision_end

_no_bottom_collision:
    bgt $t5, $t1, _no_top_collision
    li $v0, COLLISION_TOP
    j _entity_collision_end

_no_top_collision:
    bgt $t4, $t0, _no_left_collision
    li $v0, COLLISION_LEFT
    j _entity_collision_end

_no_left_collision:
    bgt %x_reg, $t2, _entity_collision_end
    li $v0, COLLISION_RIGHT

_entity_collision_end:
.end_macro

# Handles collisions between the player and all of the platforms.
# Uses:
    # $s0
    # $s1
    # $s2
    # $s3
    # $s4
    # $s5
    # $s6
    # $s7
    # $t0: entity_collision and store_word
    # $t1: entity_collision
    # $t2: entity_collision
    # $t3: entity_collision
    # $t4: entity_collision
    # $t5: entity_collision
    # $v0: entity_collision
.macro handle_platform_collisions()
    la $s0, platforms_x
    la $s1, platforms_y
    add $s2, $zero, $zero   # $s2 = array offset = sizeof(word) * i (for the index i)
    li $s3, NUM_PLATFORMS
    sll $s3, $s3, 2         # $s3 = NUM_PLATFORMS * sizeof(word)
    add $s6, $zero, $zero   # flag storing whether a platform is below the player
    add $s7, $zero, $zero   # flag storing whether a platform is above the player

_for_each_platform:
    bge $s2, $s3, _platform_loop_end    # while i < NUM_PLATFORMS

    lw $s4, 0($s0)  # $s4 = platforms_x[i]
    lw $s5, 0($s1)  # $s5 = platforms_y[i]

    entity_collision($s4, $s5, PLATFORM_WIDTH, PLATFORM_THICKNESS)
    # Handle platform collisions, setting their respective flags if needed
    beq $v0, COLLISION_TOP, _platform_top_collision
    beq $v0, COLLISION_BOTTOM, _platform_bottom_collision
    beq $v0, COLLISION_LEFT, _platform_left_collision
    beq $v0, COLLISION_RIGHT, _platform_right_collision
    j _handle_platform_collision_end

    _platform_top_collision:
        li $s7, 1
        j _handle_platform_collision_end
    _platform_bottom_collision:
        li $s6, 1
        j _handle_platform_collision_end
    _platform_left_collision:
        addi $s4, $s4, PLATFORM_WIDTH
        addi $s4, $s4, 1    # TODO: this causes an off-by-one error, removing it breaks collision detection
        store_word(player_x, $s4)
        j _handle_platform_collision_end
    _platform_right_collision:
        subi $s4, $s4, PLAYER_WIDTH
        store_word(player_x, $s4)
        j _handle_platform_collision_end

_handle_platform_collision_end:
    addi $s2, $s2, 4
    addi $s0, $s0, 4
    addi $s1, $s1, 4
    j _for_each_platform

_platform_loop_end:
    # Update the player's y-velocity depending on whether a platform is below the player
    beq $s6, $zero, _no_platform_below
    beq $s6, 1, _platform_below
    j _platform_bottom_collisions_end

    _no_platform_below:         # start falling if no platforms are below the player and the jump apex is reached
        load_word(player_y_velocity, $s4)
        bge $s4, $zero, _start_player_fall  # fall if not currently jumping

        load_word(player_jump_time, $s0)
        blt $s0, PLAYER_JUMP_APEX_TIME, _platform_bottom_collisions_end     # do not fall if the jump is not complete

        _start_player_fall:
            li $s3, PLAYER_DELTA_Y
            store_word(player_y_velocity, $s3)
            j _platform_bottom_collisions_end

    _platform_below:    # reset the y-velocity if a platform is below the player and the player is not jumping
        load_word(player_y_velocity, $s4)
        blt $s4, $zero, _platform_bottom_collisions_end
        store_word(player_y_velocity, $zero)
        store_word(player_jump_time, $zero)     # reset jump time

_platform_bottom_collisions_end:
    # Update the player's y-velocity depending on whether a platform is above the player
    beq $s7, $zero, _platform_top_collisions_end    # no platforms above player
    li $s5, PLAYER_DELTA_Y
    store_word(player_y_velocity, $s5)

_platform_top_collisions_end:
.end_macro

# Handles collisions between the player and all enemies.
# Uses: entity_collision
    # $t0: entity_collision, draw_entity, decrease_player_health, draw_health_icons, and macro
    # $t1: entity_collision and macro
    # $t2: entity_collision, draw_entity, and draw_health_icons
    # $t3: entity_collision, draw_entity, and draw_health_icons
    # $t4: entity_collision and draw_health_icons
    # $t5: entity_collision and draw_health_icons
    # $t6: draw_health_icons
    # $t7: draw_health_icons
    # $t8: draw_health_icons
    # $t9
    # $v0: entity_collision, draw_entity, generate_random_position, and draw_health_icons
    # $a0: generate_random_position
    # $a1: generate_random_position
    # $s0: draw_entity and draw_health_icons
    # $s1: draw_entity and draw_health_icons
    # $s2: draw_entity and draw_health_icons
    # $s3: draw_entity and draw_health_icons
    # $s4
    # $s5
    # $s6
    # $s7
.macro handle_enemy_collisions()
    la $s4, enemies_x
    la $s5, enemies_y
    add $s6, $zero, $zero   # $s6 = array offset = sizeof(word) * i (for the index i)
    li $s7, NUM_ENEMIES
    sll $s7, $s7, 2         # $s7 = NUM_ENEMIES * sizeof(word)

_for_each_enemy:
    bge $s6, $s7, _enemy_loop_end

    lw $t8, 0($s4)  # $t8 = enemies_x[i]
    lw $t9, 0($s5)  # $t9 = enemies_y[i]

    entity_collision($t8, $t9, ENEMY_WIDTH, ENEMY_HEIGHT)
    beq $v0, COLLISION_NONE, _handle_enemy_collision_end    # remove existing enemy on collision

    draw_entity($t8, $t9, ENEMY_WIDTH, ENEMY_HEIGHT, COLOUR_BACKGROUND)     # fill vacated pixels
    generate_random_position(ENEMY_MIN_X, ENEMY_MAX_X, ENEMY_MIN_Y, ENEMY_MAX_Y, $t0, $t1)
    # Store new random position for enemy
    sw $t0, 0($s4)
    sw $t1, 0($s5)

    decrease_player_health()
    draw_health_icons()

_handle_enemy_collision_end:
    addi $s6, $s6, 4
    addi $s4, $s4, 4
    addi $s5, $s5, 4
    j _for_each_enemy

_enemy_loop_end:
.end_macro

# Updates the player's y-value based on it's vertical velocity, handles the player's jump time, and fills the pixels
# vacated due to the player's vertical movement.
# Uses:
    # $s0: draw_entity
    # $s1: draw_entity
    # $s2: draw_entity
    # $s3: draw_entity
    # $s6
    # $s7
    # $t0: store_word and draw_entity
    # $t2: draw_entity
    # $t3: draw_entity
    # $v0: draw_entity
.macro update_player_y()
    load_word(player_y, $s6)
    load_word(player_y_velocity, $s7)
    add $s6, $s6, $s7

    # Prevent player from going out of bounds
    blt $s6, PLAYER_MIN_Y, _update_player_y_end
    bgt $s6, PLAYER_MAX_Y, _player_fall
    beq $s7, $zero, _update_vertical_values         # no pixels are vacated so clearing is skipped

    # Clear the pixels not occupied after moving the player
    load_word(player_x, $a0)
    load_word(player_y, $a1)
    bge $s7, $zero, _clear_vacated_background   # no additional calculations needed for non-upward movement
    # If moving upwards, add the required offset
    addi $a1, $a1, PLAYER_HEIGHT
    subi $a1, $a1, PLAYER_DELTA_Y

_clear_vacated_background:
    draw_entity($a0, $a1, PLAYER_WIDTH, PLAYER_DELTA_Y, COLOUR_BACKGROUND)

_update_vertical_values:
    store_word(player_y, $s6)

    # Update jump time if the player is moving upwards (i.e. jumping)
    bge $s7, $zero, _update_player_y_end

    load_word(player_jump_time, $s6)
    addi $s6, $s6, 1
    store_word(player_jump_time, $s6)
    j _update_player_y_end

_player_fall:
    store_word(player_health, $zero)
    j game_over

_update_player_y_end:
.end_macro

# Uses:
    # $t7
    # $t8
    # $t9
    # $s5
    # $s6
    # $s7

# Uses: draw_entity
    # $s0
    # $s1
    # $s2
    # $s3
    # $t0: colour_unit
    # $t2: colour_unit
    # $t3: colour_unit
    # $v0: colour_unit

# Uses: generate_random_position
    # $a0: random_integer
    # $a1: random_integer
    # $v0: random_integer
.macro update_platforms()
    la $s7, platforms_x
    la $s6, platforms_y
    add $t8, $zero, $zero   # $t8 = array offset = sizeof(word) * i (for the index i)
    li $s5, NUM_PLATFORMS
    sll $s5, $s5, 2         # $s5 = NUM_PLATFORMS * sizeof(word)

_for_each_platform:                         # $t8 = array offset
    bge $t8, $s5, _update_platforms_end     # while i < NUM_PLATFORMS
    add $t9, $s7, $t8
    add $t6, $s6, $t8

    lw $t7, 0($t9)  # $t7 = platforms_x[i]
    lw $t5, 0($t6)  # $t5 = platforms_y[i]
    subi $t7, $t7, PLATFORM_DELTA_X
    sw $t7, 0($t9)  # %entities_x[i] = new x-value after moving

    bge $t7, -PLATFORM_WIDTH, _platform_off_screen_check_end
    generate_random_position(PLATFORM_SPAWN_MIN_X, PLATFORM_SPAWN_MAX_X, PLATFORM_SPAWN_MIN_Y, PLATFORM_SPAWN_MAX_Y, $t7, $t5)
    sw $t7, 0($t9)
    sw $t5, 0($t6)

_platform_off_screen_check_end:
    addi $t7, $t7, PLATFORM_WIDTH
    draw_entity($t7, $t5, PLATFORM_DELTA_X, PLATFORM_THICKNESS, COLOUR_BACKGROUND)     # fill vacated pixels

    addi $t8, $t8, 4
    j _for_each_platform

_update_platforms_end:
.end_macro


#################### GAME ####################

# Decreases the player health, handling the case where the player runs out of health.
# Uses:
    # $t0: store_word
    # $t1
    # $t2
.macro decrease_player_health()
    load_word(player_health, $t1)
    subi $t1, $t1, 1
    store_word(player_health, $t1)

    print_str(health_lost_debug)
    print_int($t1)
    print_str(newline)

    ble $t1, $zero, game_over

_decrease_player_health_end:
.end_macro

# Handles the keypresses for movement, restarting, and quitting the game. For player movement, the original player
# position is filled with the background colour before updating the position; the player is not redrawn after updating.
# Uses:
    # $s0: draw_entity and macro
    # $s1: draw_entity and macro
    # $s2: draw_entity
    # $s3: draw_entity
    # $t0: draw_entity and update_player_x
    # $t1: draw_entity and update_player_x
    # $t3: draw_entity
    # $v0: draw_entity
    # $a0
    # $a1
.macro handle_keypress()
    li $s0, KEYSTROKE_ADDRESS
    lw $s1, 0($s0)
    bne $s1, 1, _handle_keypress_end

    lw $s1, 4($s0)  # ASCII value of key pressed
    beq $s1, ASCII_W, _w_pressed
    beq $s1, ASCII_A, _a_pressed
    beq $s1, ASCII_D, _d_pressed
    beq $s1, ASCII_R, _r_pressed
    beq $s1, ASCII_Q, _q_pressed
    j _handle_keypress_end

_w_pressed:
    # Update player's y-velocity
    li $a0, -PLAYER_DELTA_Y
    store_word(player_y_velocity, $a0)  # TODO: this should only happen if a platform is below the player
    j _handle_keypress_end

_a_pressed:
    # Clear the pixels not occupied after moving the player
    load_word(player_x, $a0)
    load_word(player_y, $a1)
    # Add offset needed due to left movement
    addi $a0, $a0, PLAYER_WIDTH
    subi $a0, $a0, PLAYER_DELTA_X
    draw_entity($a0, $a1, PLAYER_DELTA_X, PLAYER_HEIGHT, COLOUR_BACKGROUND)

    update_player_x(-PLAYER_DELTA_X)
    j _handle_keypress_end

_d_pressed:
    # Clear the pixels not occupied after moving the player
    load_word(player_x, $a0)
    load_word(player_y, $a1)
    draw_entity($a0, $a1, PLAYER_DELTA_X, PLAYER_HEIGHT, COLOUR_BACKGROUND)

    update_player_x(PLAYER_DELTA_X)
    j _handle_keypress_end

_r_pressed:
    j initialize

_q_pressed:
    j quit

_handle_keypress_end:
.end_macro

# Handles keypresses only for restarting and quitting the game.
# Uses:
    # $s0
    # $s1
.macro handle_restart_quit_keypress()
    li $s0, KEYSTROKE_ADDRESS
    lw $s1, 0($s0)
    bne $s1, 1, _handle_restart_quit_keypress_end

    lw $s1, 4($s0)  # ASCII value of key pressed
    beq $s1, ASCII_R, _r_pressed
    beq $s1, ASCII_Q, _q_pressed
    j _handle_restart_quit_keypress_end

_r_pressed:
    j initialize

_q_pressed:
    j quit

_handle_restart_quit_keypress_end:
.end_macro


main:

initialize:     # jump here on restart
    fill_background(COLOUR_BACKGROUND)

    li $s0, PLAYER_INITIAL_X
    li $s1, PLAYER_INITIAL_Y
    store_word(player_x, $s0)
    store_word(player_y, $s1)
    store_word(player_y_velocity, $zero)
    store_word(player_jump_time, $zero)
    li $s0, PLAYER_MAX_HEALTH
    store_word(player_health, $s0)

    initialize_enemies()
    initialize_platforms()

    # TODO: handle enemy collision with platform (e.g. draw platform on top of enemy)
    draw_platforms()
    draw_enemies()
    draw_ui_divider()
    draw_health_icons()

game_loop:
    draw_platforms()
    draw_enemies()

    load_word(player_x, $a0)
    load_word(player_y, $a1)
    draw_entity($a0, $a1, PLAYER_WIDTH, PLAYER_HEIGHT, COLOUR_PLAYER)

    handle_keypress()   # do before handle_platform_collisions as that places player to the side of collided platforms
    # TODO: choose whether to update player's y-value and velocity after drawing here
    # Pro: cool vertical dilation animation during fall
    # Con: risk issues with collision detection
    handle_platform_collisions()     # this can update the player's y-velocity, do this before updating the y-value
    handle_enemy_collisions()
    update_player_y()   # TODO: fix ceiling spiderman bug
    update_platforms()  # TODO: fix incorrect platform pushing for right platform collisions

    sleep()
    j game_loop

game_over:
    fill_background(COLOUR_ENEMY)
    handle_restart_quit_keypress()
    sleep()
    j game_over

quit:
    # Exit
    li $v0, 10
    syscall
