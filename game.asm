#####################################################################
#
# CSCB58 Winter 2024 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Ali Rajan, 1009034386, rajanal1, ali.rajan@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8 (update this as needed)
# - Unit height in pixels: 8 (update this as needed)
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 512 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 4
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Moving objects
# 2. Moving platforms
# 3. Start menu
# 4. Animated sprites (player water droplet dilation during movement and water streak on platform right collision)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - The player has a "delayed jump" ability, allowing it to jump while midair if it had not jumped when on the last
#   platform it was above
# - When a platform collides the player from the right, there is a water streak effect (resembling a solid plowing
#   through a water droplet); the smeared water particles can be recollected (it was intended that the collision would
#   reduce HP and recollecting particles would restore HP, though this was not completed due to time constraints)
#
#####################################################################


######################################## CONSTANTS ########################################

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
.eqv UI_TOTAL_HEALTH_WIDTH 8            # width of entire health icon area
.eqv UI_SCORE_BAR_UNIT_WIDTH 1          # framebuffer units to draw per score point
.eqv UI_SCORE_BAR_HEIGHT 2
.eqv UI_MAIN_MENU_START_BOX_WIDTH 28
.eqv UI_MAIN_MENU_QUIT_BOX_WIDTH 21
.eqv UI_MAIN_MENU_BOX_HEIGHT 7

.eqv UI_HEALTH_Y 1
.eqv UI_SCORE_BAR_START_X 43
.eqv UI_SCORE_BAR_Y 1
.eqv UI_DIVIDER_Y 4                     # max(UI_HEALTH_HEIGHT, UI_SCORE_BAR_HEIGHT) + padding
.eqv UI_DIVIDER_THICKNESS 1
.eqv UI_END_Y 5                         # UI_DIVIDER_Y + UI_DIVIDER_THICKNESS
.eqv UI_MAIN_MENU_START_BOX_X 18
.eqv UI_MAIN_MENU_START_BOX_Y 45
.eqv UI_MAIN_MENU_QUIT_BOX_X 21
.eqv UI_MAIN_MENU_QUIT_BOX_Y 54

.eqv UI_HEALTH_1_X 1                    # i-th x-value is (left padding) + (x-spacing + UI_HEALTH_WIDTH) * i
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
.eqv PLATFORM_SPAWN_MIN_X 64
.eqv PLATFORM_SPAWN_MAX_X 90
.eqv PLATFORM_SPAWN_MIN_Y 8                 # UI_END_Y + PLAYER_HEIGHT
.eqv PLATFORM_SPAWN_MAX_Y 59
.eqv PLATFORM_SPAWN_X_PARTITION_WIDTH 5     # partitioning DISPLAY_WIDTH into initial platform spawn ranges
.eqv PLATFORM_SPAWN_X_PARTITION_SPACE 12    # should be enough to prevent simultaneous top and bottom collisions
# TODO: if there is a platform both above and below the player, collision detection can break (e.g. the values below)
# .eqv PLATFORM_SPAWN_MIN_Y 28
# .eqv PLATFORM_SPAWN_MAX_Y 32
.eqv ENEMY_WIDTH 4
.eqv ENEMY_HEIGHT 2
# Enemy spawn position ranges for the top-left unit
.eqv ENEMY_SPAWN_MIN_X 64
.eqv ENEMY_SPAWN_MAX_X 100
.eqv ENEMY_SPAWN_X_PARTITION_WIDTH 18
.eqv ENEMY_SPAWN_X_PARTITION_SPACE 40
# TODO: adjust these so enemies aren't redundant because they're out of reach vertically
.eqv ENEMY_SPAWN_MIN_Y UI_END_Y
.eqv ENEMY_SPAWN_MAX_Y 57

# Colours
.eqv COLOUR_BACKGROUND 0x000000         # black
.eqv COLOUR_PLATFORM 0x964B00           # brown
.eqv COLOUR_PLAYER 0x0000FF             # blue
.eqv COLOUR_ENEMY 0xFFA500              # orange
.eqv COLOUR_UI_DIVIDER 0xFFFFFF         # white
.eqv COLOUR_UI_HEALTH 0xFF0000          # red
.eqv COLOUR_UI_SCORE_BAR 0x6497B1       # blue variant
.eqv COLOUR_UI_TEXT 0xFFFFFF            # white
.eqv COLOUR_UI_MAIN_MENU_BOX 0xFFFFFF   # white

# Keyboard
.eqv KEYSTROKE_ADDRESS 0xFFFF0000
.eqv ASCII_W 0x77
.eqv ASCII_S 0x73
.eqv ASCII_A 0x61
.eqv ASCII_D 0x64
.eqv ASCII_R 0x72
.eqv ASCII_Q 0x71
.eqv ASCII_SPACE 0x20

# Movement (TODO: tweak deltas and FPS)
.eqv SLEEP_DURATION 40              # sleep duration in milliseconds
.eqv PLAYER_DELTA_X 1               # x-value increment for each keypress
.eqv PLAYER_DELTA_Y 1
.eqv PLAYER_JUMP_APEX_TIME 15
# Bounds to prevent player from going off-screen
.eqv PLAYER_MIN_X 0
.eqv PLAYER_MAX_X 61
.eqv PLAYER_MIN_Y UI_END_Y
.eqv PLAYER_MAX_Y 61

.eqv PLATFORM_DELTA_X 1
.eqv ENEMY_DELTA_X 2

.eqv PLAYER_MAX_HEALTH 3
.eqv WINNING_SCORE 20       # number of platforms to cross
# Options in the main menu
.eqv UI_MAIN_MENU_START_OPTION 0
.eqv UI_MAIN_MENU_QUIT_OPTION 1

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
score: .word 0  # number of platforms crossed

# Coordinates of each platform's top-left unit
platforms_x: .word 0:NUM_PLATFORMS
platforms_y: .word 0:NUM_PLATFORMS

# Coordinates of each enemy's top-left unit
enemies_x: .word 0:NUM_ENEMIES
enemies_y: .word 0:NUM_ENEMIES

# Coordinates of each health icon's top-left unit (y-value is same for all)
health_icons_x: .word UI_HEALTH_1_X, UI_HEALTH_2_X, UI_HEALTH_3_X

# Debug text (TODO: remove once done debugging, or decide to keep printing debug messages throughout)
keypress_text_debug: .asciiz "key pressed: "
collision_top_debug: .asciiz "top collision\n"
collision_bottom_debug: .asciiz "bottom collision\n"
collision_left_debug: .asciiz "left collision\n"
collision_right_debug: .asciiz "right collision\n"
health_lost_debug: .asciiz "lives remaining: "
score_increase_debug: .asciiz "score: "
newline: .asciiz "\n"

.text

.globl main

j main


######################################## UTILITIES ########################################

# TODO: remove print macros once done debugging (or decide to print debug messages throughout)

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

# Returns a random integer n satisfying %min <= n <= %max.
# Parameters:
    # %min_reg: register storing the range's minimum
    # %max_reg: register storing the range's maximum
# Returns:
    # $v0: the random integer
# Uses:
    # $a0: random number generator syscall
    # $a1: random number generator syscall
    # $v0
.macro random_integer_reg(%min_reg, %max_reg)
    li $v0, 42              # syscall code for random number generator
    li $a0, 0               # argument for random number generator ID (any integer)
    move $a1, %max_reg
    sub $a1, $a1, %min_reg
    addi $a1, $a1, 1        # $a1 = %max - %min + 1, the upper bound for the syscall random number
    syscall                 # $a0 = random integer n satisfying 0 <= n < %max - %min + 1

    add $a0, $a0, %min_reg  # $a0 is now some n satisfying %min <= n < %max + 1
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


######################################## DRAWING ########################################

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


######################################## ENTITIES ########################################

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

# Generates random integers in the specified range and stores them in the given array.
# Uses:
    # $t0
    # $t2
    # $t3
    # $t4
    # $a0: random_integer
    # $a1: random_integer
    # $v0: random_integer
.macro generate_random_values(%array, %num_entries, %min, %max)
    la $t0, %array
    add $t2, $zero, $zero   # $t2 = array offset = sizeof(word) * i (for the index i)
    li $t3, %num_entries
    sll $t3, $t3, 2         # $t3 = %num_entries * sizeof(word)

_generate_values_loop:                          # $t2 = array offset
    bge $t2, $t3, _generate_values_loop_end     # while i < %num_entries
    add $t4, $t0, $t2

    random_integer(%min, %max)
    sw $v0, 0($t4)  # %array[i] = random value

    addi $t2, $t2, 4
    j _generate_values_loop

_generate_values_loop_end:
.end_macro

# Randomly generates x and y-values for all enemies based on the given ranges, storing them in the given arrays. The
# width of the display is partitioned into ranges for each x-value.
# Parameters:
    # %entities_x: the array of x-values
    # %entities_y: the array of y-values
    # %num_entities: the number of entities (an immediate value)
    # %min_y: minimum possible y-value
    # %max_y: maximum possible y-value
    # %partition_x_width: width of each partition
    # %partition_x_space: spacing between partitions
# Uses:
    # $t0
    # $t1
    # $t2
    # $t3
    # $t4
    # $t5
    # $a0: random_integer_reg
    # $a1: random_integer_reg
    # $v0: random_integer_reg
.macro initialize_entities(%entities_x, %entities_y, %num_entities, %partition_x_width, %partition_x_space, %min_y, %max_y)
    generate_random_values(%entities_y, %num_entities, %min_y, %max_y)

    la $t4, %entities_x
    addi $t0, $zero, %partition_x_space   # lower bound for partition
    add $t2, $zero, $zero   # $t2 = array offset = sizeof(word) * i (for the index i)
    li $t3, %num_entities
    sll $t3, $t3, 2         # $t3 = %num_entries * sizeof(word)
_generate_x_values_loop:
    bge $t2, $t3, _generate_x_values_loop_end
    addi $t1, $t0, %partition_x_width   # upper bound for partition
    random_integer_reg($t0, $t1)

    add $t5, $t4, $t2
    sw $v0, 0($t5)  # %entities_x[i] = random x-value in i-th partition

    addi $t0, $t0, %partition_x_width
    addi $t0, $t0, %partition_x_space
    addi $t2, $t2, 4
    j _generate_x_values_loop

_generate_x_values_loop_end:
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
    # $t6:
    # $t7:
    # $a0: initialize_entities
    # $a1: initialize_entities
    # $v0: initialize_entities
.macro initialize_platforms()
    initialize_entities(platforms_x, platforms_y, NUM_PLATFORMS, PLATFORM_SPAWN_X_PARTITION_WIDTH, PLATFORM_SPAWN_X_PARTITION_SPACE, PLATFORM_SPAWN_MIN_Y, PLATFORM_SPAWN_MAX_Y)

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
    # $a0: initialize_entities
    # $a1: initialize_entities
    # $v0: initialize_entities
.macro initialize_enemies()
    initialize_entities(enemies_x, enemies_y, NUM_ENEMIES, ENEMY_SPAWN_X_PARTITION_WIDTH, ENEMY_SPAWN_X_PARTITION_SPACE, ENEMY_SPAWN_MIN_Y, ENEMY_SPAWN_MAX_Y)
.end_macro


######################################## UI ########################################

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

# Erases all health icons. Used when the game is over.
# Uses:
    # $a0
    # $a1
    # $s0: draw_entity
    # $s1: draw_entity
    # $s2: draw_entity
    # $s3: draw_entity
    # $t0: draw_entity
    # $t2: draw_entity
    # $t3: draw_entity
    # $v0: draw_entity
.macro erase_health_icons()
    li $a0, UI_HEALTH_1_X
    li $a1, UI_HEALTH_Y
    draw_entity($a0, $a1, UI_TOTAL_HEALTH_WIDTH, UI_HEALTH_HEIGHT, COLOUR_BACKGROUND)
.end_macro

# Draws the score bar.
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
.macro draw_score_bar()
    li $t4, UI_SCORE_BAR_START_X            # current score bar column's x-value
    li $t5, UI_SCORE_BAR_Y
    load_word(score, $t6)
    addi $t6, $t6, UI_SCORE_BAR_START_X     # score bar column x-value upper bound

_for_each_score_point:
    bge $t4, $t6, _draw_score_bar_end
    draw_entity($t4, $t5, UI_SCORE_BAR_UNIT_WIDTH, UI_SCORE_BAR_HEIGHT, COLOUR_UI_SCORE_BAR)

    addi $t4, $t4, 1
    j _for_each_score_point

_draw_score_bar_end:
.end_macro


# Draws a box highlighting the menu option selected.
# Parameters:
    # %option_reg: register storing the menu option selected, one of UI_MAIN_MENU_START_OPTION and
    # UI_MAIN_MENU_QUIT_OPTION
    # %highlight_colour: immediate value for the colour
# Uses:
    # $a0
    # $a1
    # $s0: draw_entity
    # $s1: draw_entity
    # $s2: draw_entity
    # $s3: draw_entity
    # $t0: draw_entity
    # $t2: draw_entity
    # $t3: draw_entity
    # $v0: draw_entity
.macro draw_menu_option_selected(%option_reg, %highlight_colour)
    beq %option_reg, UI_MAIN_MENU_QUIT_OPTION, _highlight_quit

    li $a0, UI_MAIN_MENU_START_BOX_X
    li $a1, UI_MAIN_MENU_START_BOX_Y
    draw_entity($a0, $a1, UI_MAIN_MENU_START_BOX_WIDTH, UI_MAIN_MENU_BOX_HEIGHT, %highlight_colour)
    j _draw_menu_option_selected_end

_highlight_quit:
    li $a0, UI_MAIN_MENU_QUIT_BOX_X
    li $a1, UI_MAIN_MENU_QUIT_BOX_Y
    draw_entity($a0, $a1, UI_MAIN_MENU_QUIT_BOX_WIDTH, UI_MAIN_MENU_BOX_HEIGHT, %highlight_colour)

_draw_menu_option_selected_end:
.end_macro


######################################## MOVEMENT ########################################

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
        addi $s4, $s4, 1
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
    generate_random_position(ENEMY_SPAWN_MIN_X, ENEMY_SPAWN_MAX_X, ENEMY_SPAWN_MIN_Y, ENEMY_SPAWN_MAX_Y, $t0, $t1)
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
    blt $s6, PLAYER_MIN_Y, _player_reached_ceiling
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

_player_reached_ceiling:
    li $s7, PLAYER_DELTA_Y
    store_word(player_y_velocity, $s7)

_update_player_y_end:
.end_macro

# Updates the position of each entity in the given array (moving to the left), randomly generating a new position once
# a platform is completely off-screen to the left. The vacated pixels for each platform are filled with the background
# colour, but the platform is not redrawn.
# Parameters:
    # %entities_x: x-values of the entities
    # %entities_y: y-values of the entities
    # %num_entities: number of entities
    # %entity_delta_x: distance to move each entity left
    # %entity_width: width of each entity
    # %entity_height: height of each entity
    # %entity_spawn_min_x: minimum x-value to respawn at once off-screen
    # %entity_spawn_max_x: maximum x-value to respawn at once off-screen
    # %entity_spawn_min_y: minimum y-value to respawn at once off-screen
    # %entity_spawn_max_y: maximum y-value to respawn at once off-screen
# Returns:
    # $v0: number of entities respawned after going off-screen during the current call
# Uses:
    # $t0: draw_entity
    # $t2: draw_entity
    # $t3: draw_entity
    # $t7
    # $t8
    # $t9
    # $s0: draw_entity
    # $s1: draw_entity
    # $s2: draw_entity
    # $s3: draw_entity
    # $s4
    # $s5
    # $s6
    # $s7
    # $a0: generate_random_position
    # $a1: generate_random_position
    # $v0: generate_random_position and draw_entity
.macro update_entities(%entities_x, %entities_y, %num_entities, %entity_delta_x, %entity_width, %entity_height, %entity_spawn_min_x, %entity_spawn_max_x, %entity_spawn_min_y, %entity_spawn_max_y)
    la $s7, %entities_x
    la $s6, %entities_y
    add $t8, $zero, $zero   # $t8 = array offset = sizeof(word) * i (for the index i)
    li $s5, %num_entities
    sll $s5, $s5, 2         # $s5 = %num_entities * sizeof(word)
    add $s4, $zero, $zero   # number of entities gone off-screen

_for_each_entity:                           # $t8 = array offset
    bge $t8, $s5, _update_entities_end      # while i < %num_entities
    add $t9, $s7, $t8
    add $t6, $s6, $t8

    lw $t7, 0($t9)  # $t7 = entities_x[i]
    lw $t5, 0($t6)  # $t5 = entities_y[i]
    subi $t7, $t7, %entity_delta_x
    sw $t7, 0($t9)  # %entities_x[i] = new x-value after moving

    addi $t7, $t7, %entity_width    # $t7 = entity's right x-value
    draw_entity($t7, $t5, %entity_delta_x, %entity_height, COLOUR_BACKGROUND)   # fill vacated pixels

    bge $t7, $zero, _entity_off_screen_check_end  # if entity is off-screen, generate new position
    generate_random_position(%entity_spawn_min_x, %entity_spawn_max_x, %entity_spawn_min_y, %entity_spawn_max_y, $t7, $t5)
    sw $t7, 0($t9)
    sw $t5, 0($t6)
    addi $s4, $s4, 1

_entity_off_screen_check_end:
    addi $t8, $t8, 4
    j _for_each_entity

_update_entities_end:
    move $v0, $s4   # return number of entities gone off-screen
.end_macro

# Updates the position of each platform, keeping track of the number of platforms crossed by the player. Wraps
# update_entities for platforms specifically.
# Uses:
    # $t0: update_entities and increase_score
    # $t1: increase_score
    # $t2: update_entities
    # $t3: update_entities
    # $t7: update_entities
    # $t8: update_entities
    # $t9: update_entities
    # $s0: update_entities
    # $s1: update_entities
    # $s2: update_entities
    # $s3: update_entities
    # $s4: update_entities
    # $s5: update_entities
    # $s6: update_entities
    # $s7: update_entities
    # $a0: update_entities
    # $a1: update_entities
    # $v0: update_entities
.macro update_platforms()
    update_entities(platforms_x, platforms_y, NUM_PLATFORMS, PLATFORM_DELTA_X, PLATFORM_WIDTH, PLATFORM_THICKNESS, PLATFORM_SPAWN_MIN_X, PLATFORM_SPAWN_MAX_X, PLATFORM_SPAWN_MIN_Y, PLATFORM_SPAWN_MAX_Y)
    increase_score($v0)     # increase score by $v0 = number of platforms crossed
    draw_score_bar()
.end_macro

# Updates the position of each enemies. Wraps update_entities for enemies specifically.
# Uses:
    # $t0: update_entities
    # $t2: update_entities
    # $t3: update_entities
    # $t7: update_entities
    # $t8: update_entities
    # $t9: update_entities
    # $s0: update_entities
    # $s1: update_entities
    # $s2: update_entities
    # $s3: update_entities
    # $s4: update_entities
    # $s5: update_entities
    # $s6: update_entities
    # $s7: update_entities
    # $a0: update_entities
    # $a1: update_entities
    # $v0: update_entities
.macro update_enemies()
    update_entities(enemies_x, enemies_y, NUM_ENEMIES, ENEMY_DELTA_X, ENEMY_WIDTH, ENEMY_HEIGHT, ENEMY_SPAWN_MIN_X, ENEMY_SPAWN_MAX_X, ENEMY_SPAWN_MIN_Y, ENEMY_SPAWN_MAX_Y)
.end_macro


######################################## GAME ########################################

# Decreases the player health, handling the case where the player runs out of health.
# Uses:
    # $t0: store_word
    # $t1
    # $t2
.macro decrease_player_health()
    load_word(player_health, $t1)
    subi $t1, $t1, 1
    store_word(player_health, $t1)

    # TODO: remove once done debugging
    # print_str(health_lost_debug)
    # print_int($t1)
    # print_str(newline)

    ble $t1, $zero, game_over

_decrease_player_health_end:
.end_macro

# Increases the score, handling the case where the winning score is reached (i.e. the game is won).
# Parameters:
    # %increment_reg: register storing the score increment
# Uses:
    # $t0: store_word
    # $t1
.macro increase_score(%increment_reg)
    load_word(score, $t1)
    add $t1, $t1, %increment_reg
    store_word(score, $t1)

    # TODO: remove once done debugging
    # print_str(score_increase_debug)
    # print_int($t1)
    # print_str(newline)

    bge $t1, WINNING_SCORE, game_won
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
    j main

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
    j main

_q_pressed:
    j quit

_handle_restart_quit_keypress_end:
.end_macro

# Parameters:
    # %option_reg: register storing the menu option selected, one of UI_MAIN_MENU_START_OPTION and
    # UI_MAIN_MENU_QUIT_OPTION
# Uses:
    # $s0
    # $s1
    # %option_reg

# Uses: draw_menu_option_selected
    # $a0
    # $a1
    # $s0: draw_entity
    # $s1: draw_entity
    # $s2: draw_entity
    # $s3: draw_entity
    # $t0: draw_entity
    # $t2: draw_entity
    # $t3: draw_entity
    # $v0: draw_entity
.macro handle_main_menu_keypress(%option_reg)
    li $s0, KEYSTROKE_ADDRESS
    lw $s1, 0($s0)
    bne $s1, 1, _handle_main_menu_keypress_end

    # TODO: check for restart and quit here

    lw $s1, 4($s0)  # ASCII value of key pressed
    beq $s1, ASCII_W, _previous_option
    beq $s1, ASCII_S, _next_option
    beq $s1, ASCII_SPACE, _select_option
    beq $s1, ASCII_R, _r_pressed
    beq $s1, ASCII_Q, _q_pressed
    j _handle_main_menu_keypress_end

_select_option:
    beq %option_reg, UI_MAIN_MENU_QUIT_OPTION, quit
    j initialize

_r_pressed:
    j main

_q_pressed:
    j quit

_previous_option:
    beq %option_reg, UI_MAIN_MENU_START_OPTION, _handle_main_menu_keypress_end  # no action if top option selected

    draw_menu_option_selected(%option_reg, COLOUR_BACKGROUND)   # vacate old box's pixels
    li %option_reg, UI_MAIN_MENU_START_OPTION
    j _redraw_highlight_box

_next_option:
    beq %option_reg, UI_MAIN_MENU_QUIT_OPTION, _handle_main_menu_keypress_end   # no action if bottom option selected

    draw_menu_option_selected(%option_reg, COLOUR_BACKGROUND)   # vacate old box's pixels
    li %option_reg, UI_MAIN_MENU_QUIT_OPTION
    j _redraw_highlight_box

_redraw_highlight_box:
    draw_menu_option_selected(%option_reg, COLOUR_UI_MAIN_MENU_BOX)
    jal draw_menu_screen

_handle_main_menu_keypress_end:
.end_macro


main:

menu:
    fill_background(COLOUR_BACKGROUND)
    li $a3, UI_MAIN_MENU_START_OPTION   # $a3 = menu option selected
    draw_menu_option_selected($a3, COLOUR_UI_MAIN_MENU_BOX)
    jal draw_menu_screen

handle_menu_input:
    handle_main_menu_keypress($a3)      # $a3 is modified directly
    j handle_menu_input

initialize:     # jump here on restart
    fill_background(COLOUR_BACKGROUND)

    li $s0, PLAYER_INITIAL_X
    li $s1, PLAYER_INITIAL_Y
    li $s2, PLAYER_MAX_HEALTH
    store_word(player_x, $s0)
    store_word(player_y, $s1)
    store_word(player_y_velocity, $zero)
    store_word(player_jump_time, $zero)
    store_word(player_health, $s2)
    store_word(score, $zero)

    initialize_enemies()
    initialize_platforms()

    draw_ui_divider()
    draw_health_icons()
    draw_score_bar()

game_loop:
    draw_platforms()
    draw_enemies()

    load_word(player_x, $a0)
    load_word(player_y, $a1)
    draw_entity($a0, $a1, PLAYER_WIDTH, PLAYER_HEIGHT, COLOUR_PLAYER)

    handle_keypress()   # do before handle_platform_collisions as that places player to the side of collided platforms
    handle_platform_collisions()     # this can update the player's y-velocity, do this before updating the y-value
    handle_enemy_collisions()
    update_player_y()   # TODO: fix ceiling spiderman bug
    update_platforms()
    update_enemies()

    sleep()
    j game_loop

game_over:
    jal draw_game_over_screen
    erase_health_icons()
    handle_restart_quit_keypress()
    sleep()
    j game_over

game_won:
    jal draw_you_won_screen
    handle_restart_quit_keypress()
    sleep()
    j game_won

quit:
    fill_background(COLOUR_BACKGROUND)
    # Exit
    li $v0, 10
    syscall


######################################## MENU SCREENS PIXEL ART ########################################
# Created using online pixel art drawing tool with image to MARS syntax converter

# Uses:
    # $t0
    # $t1
    # $t2
    # $t3
    # $t4
    # $t5
draw_menu_screen:
    la $t0, DISPLAY_BASE_ADDRESS
    li $t1, COLOUR_PLAYER
    li $t2, COLOUR_ENEMY
    li $t3, 0x0202b3        # extra blue for shadow effect
    li $t4, COLOUR_PLATFORM
    li $t5, COLOUR_UI_HEALTH

    sw $t1, 1300($t0)
    sw $t1, 1304($t0)
    sw $t1, 1308($t0)
    sw $t1, 1312($t0)
    sw $t1, 1316($t0)
    sw $t1, 1336($t0)
    sw $t1, 1340($t0)
    sw $t1, 1344($t0)
    sw $t1, 1348($t0)
    sw $t1, 1364($t0)
    sw $t1, 1368($t0)
    sw $t1, 1372($t0)
    sw $t1, 1376($t0)
    sw $t1, 1380($t0)
    sw $t1, 1384($t0)
    sw $t1, 1400($t0)
    sw $t1, 1404($t0)
    sw $t1, 1408($t0)
    sw $t1, 1412($t0)
    sw $t1, 1428($t0)
    sw $t1, 1456($t0)
    sw $t1, 1460($t0)
    sw $t1, 1464($t0)
    sw $t1, 1468($t0)
    sw $t1, 1484($t0)
    sw $t1, 1488($t0)
    sw $t1, 1492($t0)
    sw $t1, 1496($t0)
    sw $t1, 1500($t0)
    sw $t1, 1504($t0)
    sw $t1, 1508($t0)
    sw $t1, 1512($t0)
    sw $t1, 1552($t0)
    sw $t1, 1556($t0)
    sw $t1, 1560($t0)
    sw $t1, 1564($t0)
    sw $t1, 1568($t0)
    sw $t1, 1572($t0)
    sw $t1, 1576($t0)
    sw $t1, 1588($t0)
    sw $t1, 1592($t0)
    sw $t1, 1596($t0)
    sw $t1, 1600($t0)
    sw $t1, 1604($t0)
    sw $t1, 1608($t0)
    sw $t1, 1616($t0)
    sw $t1, 1620($t0)
    sw $t1, 1624($t0)
    sw $t1, 1628($t0)
    sw $t1, 1632($t0)
    sw $t1, 1636($t0)
    sw $t1, 1640($t0)
    sw $t1, 1644($t0)
    sw $t1, 1652($t0)
    sw $t1, 1656($t0)
    sw $t1, 1660($t0)
    sw $t1, 1664($t0)
    sw $t1, 1668($t0)
    sw $t1, 1672($t0)
    sw $t1, 1680($t0)
    sw $t1, 1684($t0)
    sw $t1, 1708($t0)
    sw $t1, 1712($t0)
    sw $t1, 1716($t0)
    sw $t1, 1720($t0)
    sw $t1, 1724($t0)
    sw $t1, 1728($t0)
    sw $t1, 1736($t0)
    sw $t1, 1740($t0)
    sw $t1, 1744($t0)
    sw $t1, 1748($t0)
    sw $t1, 1752($t0)
    sw $t1, 1756($t0)
    sw $t1, 1760($t0)
    sw $t1, 1764($t0)
    sw $t1, 1768($t0)
    sw $t1, 1772($t0)
    sw $t1, 1808($t0)
    sw $t1, 1812($t0)
    sw $t1, 1828($t0)
    sw $t1, 1832($t0)
    sw $t1, 1836($t0)
    sw $t1, 1844($t0)
    sw $t1, 1848($t0)
    sw $t1, 1860($t0)
    sw $t1, 1864($t0)
    sw $t1, 1872($t0)
    sw $t1, 1876($t0)
    sw $t1, 1880($t0)
    sw $t1, 1892($t0)
    sw $t1, 1896($t0)
    sw $t1, 1900($t0)
    sw $t1, 1908($t0)
    sw $t1, 1912($t0)
    sw $t1, 1924($t0)
    sw $t1, 1928($t0)
    sw $t1, 1936($t0)
    sw $t1, 1940($t0)
    sw $t1, 1964($t0)
    sw $t1, 1968($t0)
    sw $t1, 1972($t0)
    sw $t1, 2008($t0)
    sw $t1, 2012($t0)
    sw $t1, 2064($t0)
    sw $t1, 2068($t0)
    sw $t1, 2088($t0)
    sw $t1, 2092($t0)
    sw $t1, 2100($t0)
    sw $t1, 2104($t0)
    sw $t1, 2116($t0)
    sw $t1, 2120($t0)
    sw $t1, 2128($t0)
    sw $t1, 2132($t0)
    sw $t1, 2152($t0)
    sw $t1, 2156($t0)
    sw $t1, 2164($t0)
    sw $t1, 2168($t0)
    sw $t1, 2180($t0)
    sw $t1, 2184($t0)
    sw $t1, 2192($t0)
    sw $t1, 2196($t0)
    sw $t1, 2220($t0)
    sw $t1, 2224($t0)
    sw $t1, 2264($t0)
    sw $t1, 2268($t0)
    sw $t1, 2320($t0)
    sw $t1, 2324($t0)
    sw $t1, 2344($t0)
    sw $t1, 2348($t0)
    sw $t1, 2356($t0)
    sw $t1, 2360($t0)
    sw $t1, 2368($t0)
    sw $t1, 2372($t0)
    sw $t1, 2376($t0)
    sw $t1, 2384($t0)
    sw $t1, 2388($t0)
    sw $t1, 2408($t0)
    sw $t1, 2412($t0)
    sw $t1, 2420($t0)
    sw $t1, 2424($t0)
    sw $t1, 2428($t0)
    sw $t1, 2432($t0)
    sw $t1, 2436($t0)
    sw $t1, 2440($t0)
    sw $t1, 2448($t0)
    sw $t1, 2452($t0)
    sw $t1, 2476($t0)
    sw $t1, 2480($t0)
    sw $t1, 2484($t0)
    sw $t1, 2488($t0)
    sw $t1, 2520($t0)
    sw $t1, 2524($t0)
    sw $t1, 2576($t0)
    sw $t1, 2580($t0)
    sw $t1, 2600($t0)
    sw $t1, 2604($t0)
    sw $t1, 2612($t0)
    sw $t1, 2616($t0)
    sw $t1, 2620($t0)
    sw $t1, 2624($t0)
    sw $t1, 2628($t0)
    sw $t1, 2640($t0)
    sw $t1, 2644($t0)
    sw $t1, 2664($t0)
    sw $t1, 2668($t0)
    sw $t1, 2676($t0)
    sw $t1, 2680($t0)
    sw $t1, 2684($t0)
    sw $t1, 2688($t0)
    sw $t1, 2692($t0)
    sw $t1, 2704($t0)
    sw $t1, 2708($t0)
    sw $t1, 2732($t0)
    sw $t1, 2736($t0)
    sw $t1, 2740($t0)
    sw $t1, 2744($t0)
    sw $t1, 2776($t0)
    sw $t1, 2780($t0)
    sw $t1, 2832($t0)
    sw $t1, 2836($t0)
    sw $t1, 2856($t0)
    sw $t1, 2860($t0)
    sw $t1, 2868($t0)
    sw $t1, 2872($t0)
    sw $t1, 2876($t0)
    sw $t1, 2880($t0)
    sw $t1, 2896($t0)
    sw $t1, 2900($t0)
    sw $t1, 2920($t0)
    sw $t1, 2924($t0)
    sw $t1, 2932($t0)
    sw $t1, 2936($t0)
    sw $t1, 2960($t0)
    sw $t1, 2964($t0)
    sw $t1, 2988($t0)
    sw $t1, 2992($t0)
    sw $t1, 3032($t0)
    sw $t1, 3036($t0)
    sw $t1, 3088($t0)
    sw $t1, 3092($t0)
    sw $t1, 3108($t0)
    sw $t1, 3112($t0)
    sw $t1, 3116($t0)
    sw $t1, 3124($t0)
    sw $t1, 3128($t0)
    sw $t1, 3132($t0)
    sw $t1, 3136($t0)
    sw $t1, 3140($t0)
    sw $t1, 3152($t0)
    sw $t1, 3156($t0)
    sw $t1, 3160($t0)
    sw $t1, 3172($t0)
    sw $t1, 3176($t0)
    sw $t1, 3180($t0)
    sw $t1, 3188($t0)
    sw $t1, 3192($t0)
    sw $t1, 3216($t0)
    sw $t1, 3220($t0)
    sw $t1, 3224($t0)
    sw $t1, 3244($t0)
    sw $t1, 3248($t0)
    sw $t1, 3252($t0)
    sw $t1, 3288($t0)
    sw $t1, 3292($t0)
    sw $t1, 3344($t0)
    sw $t1, 3348($t0)
    sw $t1, 3352($t0)
    sw $t1, 3356($t0)
    sw $t1, 3360($t0)
    sw $t1, 3364($t0)
    sw $t1, 3368($t0)
    sw $t1, 3380($t0)
    sw $t1, 3384($t0)
    sw $t1, 3392($t0)
    sw $t1, 3396($t0)
    sw $t1, 3400($t0)
    sw $t1, 3408($t0)
    sw $t1, 3412($t0)
    sw $t1, 3416($t0)
    sw $t1, 3420($t0)
    sw $t1, 3424($t0)
    sw $t1, 3428($t0)
    sw $t1, 3432($t0)
    sw $t1, 3436($t0)
    sw $t1, 3444($t0)
    sw $t1, 3448($t0)
    sw $t1, 3472($t0)
    sw $t1, 3476($t0)
    sw $t1, 3480($t0)
    sw $t1, 3484($t0)
    sw $t1, 3488($t0)
    sw $t1, 3492($t0)
    sw $t1, 3500($t0)
    sw $t1, 3504($t0)
    sw $t1, 3508($t0)
    sw $t1, 3512($t0)
    sw $t1, 3516($t0)
    sw $t1, 3520($t0)
    sw $t1, 3544($t0)
    sw $t1, 3548($t0)
    sw $t1, 3604($t0)
    sw $t1, 3608($t0)
    sw $t1, 3612($t0)
    sw $t1, 3616($t0)
    sw $t1, 3620($t0)
    sw $t1, 3640($t0)
    sw $t1, 3652($t0)
    sw $t1, 3656($t0)
    sw $t1, 3668($t0)
    sw $t1, 3672($t0)
    sw $t1, 3676($t0)
    sw $t1, 3680($t0)
    sw $t1, 3684($t0)
    sw $t1, 3688($t0)
    sw $t1, 3704($t0)
    sw $t1, 3732($t0)
    sw $t1, 3736($t0)
    sw $t1, 3740($t0)
    sw $t1, 3744($t0)
    sw $t1, 3760($t0)
    sw $t1, 3764($t0)
    sw $t1, 3768($t0)
    sw $t1, 3772($t0)
    sw $t1, 3800($t0)
    sw $t1, 4672($t0)
    sw $t1, 4676($t0)
    sw $t1, 4680($t0)
    sw $t1, 4684($t0)
    sw $t1, 4688($t0)
    sw $t1, 4712($t0)
    sw $t1, 4716($t0)
    sw $t1, 4720($t0)
    sw $t1, 4724($t0)
    sw $t1, 4744($t0)
    sw $t1, 4748($t0)
    sw $t1, 4752($t0)
    sw $t1, 4756($t0)
    sw $t1, 4772($t0)
    sw $t1, 4792($t0)
    sw $t1, 4924($t0)
    sw $t1, 4928($t0)
    sw $t1, 4932($t0)
    sw $t1, 4936($t0)
    sw $t1, 4940($t0)
    sw $t1, 4944($t0)
    sw $t1, 4948($t0)
    sw $t1, 4964($t0)
    sw $t1, 4968($t0)
    sw $t1, 4972($t0)
    sw $t1, 4976($t0)
    sw $t1, 4980($t0)
    sw $t1, 4984($t0)
    sw $t1, 4996($t0)
    sw $t1, 5000($t0)
    sw $t1, 5004($t0)
    sw $t1, 5008($t0)
    sw $t1, 5012($t0)
    sw $t1, 5016($t0)
    sw $t1, 5024($t0)
    sw $t1, 5028($t0)
    sw $t1, 5048($t0)
    sw $t1, 5052($t0)
    sw $t1, 5180($t0)
    sw $t1, 5184($t0)
    sw $t1, 5200($t0)
    sw $t1, 5204($t0)
    sw $t1, 5208($t0)
    sw $t1, 5216($t0)
    sw $t1, 5220($t0)
    sw $t1, 5224($t0)
    sw $t1, 5236($t0)
    sw $t1, 5240($t0)
    sw $t1, 5244($t0)
    sw $t1, 5252($t0)
    sw $t1, 5256($t0)
    sw $t1, 5260($t0)
    sw $t1, 5280($t0)
    sw $t1, 5284($t0)
    sw $t1, 5304($t0)
    sw $t1, 5308($t0)
    sw $t1, 5436($t0)
    sw $t1, 5440($t0)
    sw $t1, 5460($t0)
    sw $t1, 5464($t0)
    sw $t1, 5472($t0)
    sw $t1, 5476($t0)
    sw $t1, 5496($t0)
    sw $t1, 5500($t0)
    sw $t1, 5508($t0)
    sw $t1, 5512($t0)
    sw $t1, 5536($t0)
    sw $t1, 5540($t0)
    sw $t1, 5560($t0)
    sw $t1, 5564($t0)
    sw $t1, 5692($t0)
    sw $t1, 5696($t0)
    sw $t1, 5716($t0)
    sw $t1, 5720($t0)
    sw $t1, 5728($t0)
    sw $t1, 5732($t0)
    sw $t1, 5736($t0)
    sw $t1, 5740($t0)
    sw $t1, 5744($t0)
    sw $t1, 5748($t0)
    sw $t1, 5752($t0)
    sw $t1, 5756($t0)
    sw $t1, 5764($t0)
    sw $t1, 5768($t0)
    sw $t1, 5772($t0)
    sw $t1, 5776($t0)
    sw $t1, 5780($t0)
    sw $t1, 5792($t0)
    sw $t1, 5796($t0)
    sw $t1, 5800($t0)
    sw $t1, 5804($t0)
    sw $t1, 5808($t0)
    sw $t1, 5812($t0)
    sw $t1, 5816($t0)
    sw $t1, 5820($t0)
    sw $t1, 5948($t0)
    sw $t1, 5952($t0)
    sw $t1, 5972($t0)
    sw $t1, 5976($t0)
    sw $t1, 5984($t0)
    sw $t1, 5988($t0)
    sw $t1, 5992($t0)
    sw $t1, 5996($t0)
    sw $t1, 6000($t0)
    sw $t1, 6004($t0)
    sw $t1, 6008($t0)
    sw $t1, 6012($t0)
    sw $t1, 6024($t0)
    sw $t1, 6028($t0)
    sw $t1, 6032($t0)
    sw $t1, 6036($t0)
    sw $t1, 6040($t0)
    sw $t1, 6048($t0)
    sw $t1, 6052($t0)
    sw $t1, 6056($t0)
    sw $t1, 6060($t0)
    sw $t1, 6064($t0)
    sw $t1, 6068($t0)
    sw $t1, 6072($t0)
    sw $t1, 6076($t0)
    sw $t1, 6204($t0)
    sw $t1, 6208($t0)
    sw $t1, 6228($t0)
    sw $t1, 6232($t0)
    sw $t1, 6240($t0)
    sw $t1, 6244($t0)
    sw $t1, 6264($t0)
    sw $t1, 6268($t0)
    sw $t1, 6292($t0)
    sw $t1, 6296($t0)
    sw $t1, 6304($t0)
    sw $t1, 6308($t0)
    sw $t1, 6328($t0)
    sw $t1, 6332($t0)
    sw $t1, 6460($t0)
    sw $t1, 6464($t0)
    sw $t1, 6480($t0)
    sw $t1, 6484($t0)
    sw $t1, 6488($t0)
    sw $t1, 6496($t0)
    sw $t1, 6500($t0)
    sw $t1, 6520($t0)
    sw $t1, 6524($t0)
    sw $t1, 6544($t0)
    sw $t1, 6548($t0)
    sw $t1, 6552($t0)
    sw $t1, 6560($t0)
    sw $t1, 6564($t0)
    sw $t1, 6584($t0)
    sw $t1, 6588($t0)
    sw $t1, 6716($t0)
    sw $t1, 6720($t0)
    sw $t1, 6724($t0)
    sw $t1, 6728($t0)
    sw $t1, 6732($t0)
    sw $t1, 6736($t0)
    sw $t1, 6740($t0)
    sw $t1, 6752($t0)
    sw $t1, 6756($t0)
    sw $t1, 6776($t0)
    sw $t1, 6780($t0)
    sw $t1, 6788($t0)
    sw $t1, 6792($t0)
    sw $t1, 6796($t0)
    sw $t1, 6800($t0)
    sw $t1, 6804($t0)
    sw $t1, 6808($t0)
    sw $t1, 6816($t0)
    sw $t1, 6820($t0)
    sw $t1, 6840($t0)
    sw $t1, 6844($t0)
    sw $t1, 6976($t0)
    sw $t1, 6980($t0)
    sw $t1, 6984($t0)
    sw $t1, 6988($t0)
    sw $t1, 6992($t0)
    sw $t1, 7012($t0)
    sw $t1, 7032($t0)
    sw $t1, 7048($t0)
    sw $t1, 7052($t0)
    sw $t1, 7056($t0)
    sw $t1, 7060($t0)
    sw $t1, 7076($t0)
    sw $t1, 7096($t0)
    sw $t2, 7904($t0)
    sw $t2, 7908($t0)
    sw $t2, 7912($t0)
    sw $t2, 8160($t0)
    sw $t2, 8164($t0)
    sw $t2, 8168($t0)
    sw $t2, 8176($t0)
    sw $t2, 8184($t0)
    sw $t2, 8416($t0)
    sw $t2, 8420($t0)
    sw $t2, 8424($t0)
    sw $t1, 8488($t0)
    sw $t1, 8492($t0)
    sw $t1, 8496($t0)
    sw $t1, 8500($t0)
    sw $t1, 8504($t0)
    sw $t1, 8508($t0)
    sw $t3, 8744($t0)
    sw $t1, 8748($t0)
    sw $t1, 8752($t0)
    sw $t1, 8756($t0)
    sw $t1, 8760($t0)
    sw $t1, 8764($t0)
    sw $t3, 9000($t0)
    sw $t1, 9004($t0)
    sw $t1, 9008($t0)
    sw $t1, 9012($t0)
    sw $t1, 9016($t0)
    sw $t1, 9020($t0)
    sw $t4, 9152($t0)
    sw $t4, 9156($t0)
    sw $t4, 9160($t0)
    sw $t4, 9164($t0)
    sw $t4, 9168($t0)
    sw $t4, 9172($t0)
    sw $t4, 9176($t0)
    sw $t4, 9180($t0)
    sw $t4, 9184($t0)
    sw $t4, 9188($t0)
    sw $t4, 9192($t0)
    sw $t4, 9196($t0)
    sw $t4, 9200($t0)
    sw $t4, 9204($t0)
    sw $t4, 9208($t0)
    sw $t4, 9212($t0)
    sw $t3, 9256($t0)
    sw $t1, 9260($t0)
    sw $t1, 9264($t0)
    sw $t1, 9268($t0)
    sw $t1, 9272($t0)
    sw $t1, 9276($t0)
    sw $t4, 9408($t0)
    sw $t4, 9412($t0)
    sw $t4, 9416($t0)
    sw $t4, 9420($t0)
    sw $t4, 9424($t0)
    sw $t4, 9428($t0)
    sw $t4, 9432($t0)
    sw $t4, 9436($t0)
    sw $t4, 9440($t0)
    sw $t4, 9444($t0)
    sw $t4, 9448($t0)
    sw $t4, 9452($t0)
    sw $t4, 9456($t0)
    sw $t4, 9460($t0)
    sw $t4, 9464($t0)
    sw $t4, 9468($t0)
    sw $t3, 9512($t0)
    sw $t1, 9516($t0)
    sw $t1, 9520($t0)
    sw $t1, 9524($t0)
    sw $t1, 9528($t0)
    sw $t1, 9532($t0)
    sw $t3, 9768($t0)
    sw $t3, 9772($t0)
    sw $t3, 9776($t0)
    sw $t3, 9780($t0)
    sw $t1, 9784($t0)
    sw $t1, 9788($t0)
    sw $t1, 10272($t0)
    sw $t1, 10776($t0)
    sw $t4, 11264($t0)
    sw $t4, 11268($t0)
    sw $t4, 11272($t0)
    sw $t4, 11276($t0)
    sw $t4, 11280($t0)
    sw $t4, 11284($t0)
    sw $t4, 11288($t0)
    sw $t4, 11520($t0)
    sw $t4, 11524($t0)
    sw $t4, 11528($t0)
    sw $t4, 11532($t0)
    sw $t4, 11536($t0)
    sw $t4, 11540($t0)
    sw $t4, 11544($t0)
    sw $t5, 11856($t0)
    sw $t5, 11860($t0)
    sw $t5, 11864($t0)
    sw $t5, 11872($t0)
    sw $t5, 11876($t0)
    sw $t5, 11880($t0)
    sw $t5, 11884($t0)
    sw $t5, 11888($t0)
    sw $t5, 11900($t0)
    sw $t5, 11904($t0)
    sw $t5, 11916($t0)
    sw $t5, 11920($t0)
    sw $t5, 11924($t0)
    sw $t5, 11936($t0)
    sw $t5, 11940($t0)
    sw $t5, 11944($t0)
    sw $t5, 11948($t0)
    sw $t5, 11952($t0)
    sw $t5, 12108($t0)
    sw $t5, 12136($t0)
    sw $t5, 12152($t0)
    sw $t5, 12164($t0)
    sw $t5, 12172($t0)
    sw $t5, 12184($t0)
    sw $t5, 12200($t0)
    sw $t5, 12368($t0)
    sw $t5, 12372($t0)
    sw $t5, 12392($t0)
    sw $t5, 12408($t0)
    sw $t5, 12412($t0)
    sw $t5, 12416($t0)
    sw $t5, 12420($t0)
    sw $t5, 12428($t0)
    sw $t5, 12432($t0)
    sw $t5, 12436($t0)
    sw $t5, 12456($t0)
    sw $t5, 12632($t0)
    sw $t5, 12648($t0)
    sw $t5, 12664($t0)
    sw $t5, 12676($t0)
    sw $t5, 12684($t0)
    sw $t5, 12692($t0)
    sw $t5, 12712($t0)
    sw $t5, 12876($t0)
    sw $t5, 12880($t0)
    sw $t5, 12884($t0)
    sw $t5, 12904($t0)
    sw $t5, 12920($t0)
    sw $t5, 12932($t0)
    sw $t5, 12940($t0)
    sw $t5, 12952($t0)
    sw $t5, 12968($t0)
    sw $t2, 14172($t0)
    sw $t2, 14176($t0)
    sw $t2, 14188($t0)
    sw $t2, 14200($t0)
    sw $t2, 14208($t0)
    sw $t2, 14212($t0)
    sw $t2, 14216($t0)
    sw $t2, 14224($t0)
    sw $t2, 14228($t0)
    sw $t2, 14232($t0)
    sw $t2, 14236($t0)
    sw $t2, 14240($t0)
    sw $t2, 14424($t0)
    sw $t2, 14436($t0)
    sw $t2, 14444($t0)
    sw $t2, 14456($t0)
    sw $t2, 14468($t0)
    sw $t2, 14488($t0)
    sw $t2, 14680($t0)
    sw $t2, 14692($t0)
    sw $t2, 14700($t0)
    sw $t2, 14712($t0)
    sw $t2, 14724($t0)
    sw $t2, 14744($t0)
    sw $t2, 14936($t0)
    sw $t2, 14944($t0)
    sw $t2, 14956($t0)
    sw $t2, 14968($t0)
    sw $t2, 14980($t0)
    sw $t2, 15000($t0)
    sw $t2, 15196($t0)
    sw $t2, 15204($t0)
    sw $t2, 15216($t0)
    sw $t2, 15220($t0)
    sw $t2, 15232($t0)
    sw $t2, 15236($t0)
    sw $t2, 15240($t0)
    sw $t2, 15256($t0)

    jr $ra


# Uses:
    # $t0
    # $t1
    # $t2
draw_game_over_screen:
    la $t0, DISPLAY_BASE_ADDRESS
    li $t1, COLOUR_ENEMY
    li $t2, COLOUR_UI_TEXT

    sw $t1, 2336($t0)
    sw $t1, 2340($t0)
    sw $t1, 2344($t0)
    sw $t1, 2348($t0)
    sw $t1, 2352($t0)
    sw $t1, 2356($t0)
    sw $t1, 2360($t0)
    sw $t1, 2364($t0)
    sw $t1, 2368($t0)
    sw $t1, 2372($t0)
    sw $t1, 2376($t0)
    sw $t1, 2380($t0)
    sw $t1, 2384($t0)
    sw $t1, 2388($t0)
    sw $t1, 2392($t0)
    sw $t1, 2396($t0)
    sw $t1, 2400($t0)
    sw $t1, 2404($t0)
    sw $t1, 2408($t0)
    sw $t1, 2412($t0)
    sw $t1, 2416($t0)
    sw $t1, 2420($t0)
    sw $t1, 2424($t0)
    sw $t1, 2428($t0)
    sw $t1, 2432($t0)
    sw $t1, 2436($t0)
    sw $t1, 2440($t0)
    sw $t1, 2444($t0)
    sw $t1, 2448($t0)
    sw $t1, 2452($t0)
    sw $t1, 2456($t0)
    sw $t1, 2460($t0)
    sw $t1, 2464($t0)
    sw $t1, 2468($t0)
    sw $t1, 2472($t0)
    sw $t1, 2476($t0)
    sw $t1, 2480($t0)
    sw $t1, 2484($t0)
    sw $t1, 2488($t0)
    sw $t1, 2492($t0)
    sw $t1, 2496($t0)
    sw $t1, 2500($t0)
    sw $t1, 2504($t0)
    sw $t1, 2508($t0)
    sw $t1, 2512($t0)
    sw $t1, 2516($t0)
    sw $t1, 2520($t0)
    sw $t1, 2524($t0)
    sw $t1, 2592($t0)
    sw $t1, 2596($t0)
    sw $t1, 2600($t0)
    sw $t1, 2604($t0)
    sw $t1, 2608($t0)
    sw $t1, 2612($t0)
    sw $t2, 2616($t0)
    sw $t2, 2620($t0)
    sw $t2, 2624($t0)
    sw $t2, 2628($t0)
    sw $t1, 2632($t0)
    sw $t1, 2636($t0)
    sw $t1, 2640($t0)
    sw $t1, 2644($t0)
    sw $t1, 2648($t0)
    sw $t1, 2652($t0)
    sw $t2, 2656($t0)
    sw $t2, 2660($t0)
    sw $t2, 2664($t0)
    sw $t2, 2668($t0)
    sw $t1, 2672($t0)
    sw $t1, 2676($t0)
    sw $t1, 2680($t0)
    sw $t1, 2684($t0)
    sw $t2, 2688($t0)
    sw $t2, 2692($t0)
    sw $t1, 2696($t0)
    sw $t1, 2700($t0)
    sw $t1, 2704($t0)
    sw $t1, 2708($t0)
    sw $t1, 2712($t0)
    sw $t1, 2716($t0)
    sw $t2, 2720($t0)
    sw $t2, 2724($t0)
    sw $t1, 2728($t0)
    sw $t1, 2732($t0)
    sw $t2, 2736($t0)
    sw $t2, 2740($t0)
    sw $t2, 2744($t0)
    sw $t2, 2748($t0)
    sw $t2, 2752($t0)
    sw $t2, 2756($t0)
    sw $t2, 2760($t0)
    sw $t2, 2764($t0)
    sw $t1, 2768($t0)
    sw $t1, 2772($t0)
    sw $t1, 2776($t0)
    sw $t1, 2780($t0)
    sw $t1, 2848($t0)
    sw $t1, 2852($t0)
    sw $t1, 2856($t0)
    sw $t1, 2860($t0)
    sw $t1, 2864($t0)
    sw $t1, 2868($t0)
    sw $t2, 2872($t0)
    sw $t2, 2876($t0)
    sw $t2, 2880($t0)
    sw $t2, 2884($t0)
    sw $t1, 2888($t0)
    sw $t1, 2892($t0)
    sw $t1, 2896($t0)
    sw $t1, 2900($t0)
    sw $t1, 2904($t0)
    sw $t1, 2908($t0)
    sw $t2, 2912($t0)
    sw $t2, 2916($t0)
    sw $t2, 2920($t0)
    sw $t2, 2924($t0)
    sw $t1, 2928($t0)
    sw $t1, 2932($t0)
    sw $t1, 2936($t0)
    sw $t1, 2940($t0)
    sw $t2, 2944($t0)
    sw $t2, 2948($t0)
    sw $t1, 2952($t0)
    sw $t1, 2956($t0)
    sw $t1, 2960($t0)
    sw $t1, 2964($t0)
    sw $t1, 2968($t0)
    sw $t1, 2972($t0)
    sw $t2, 2976($t0)
    sw $t2, 2980($t0)
    sw $t1, 2984($t0)
    sw $t1, 2988($t0)
    sw $t2, 2992($t0)
    sw $t2, 2996($t0)
    sw $t2, 3000($t0)
    sw $t2, 3004($t0)
    sw $t2, 3008($t0)
    sw $t2, 3012($t0)
    sw $t2, 3016($t0)
    sw $t2, 3020($t0)
    sw $t1, 3024($t0)
    sw $t1, 3028($t0)
    sw $t1, 3032($t0)
    sw $t1, 3036($t0)
    sw $t1, 3104($t0)
    sw $t1, 3108($t0)
    sw $t1, 3112($t0)
    sw $t1, 3116($t0)
    sw $t2, 3120($t0)
    sw $t2, 3124($t0)
    sw $t1, 3128($t0)
    sw $t1, 3132($t0)
    sw $t1, 3136($t0)
    sw $t1, 3140($t0)
    sw $t1, 3144($t0)
    sw $t1, 3148($t0)
    sw $t1, 3152($t0)
    sw $t1, 3156($t0)
    sw $t2, 3160($t0)
    sw $t2, 3164($t0)
    sw $t1, 3168($t0)
    sw $t1, 3172($t0)
    sw $t1, 3176($t0)
    sw $t1, 3180($t0)
    sw $t2, 3184($t0)
    sw $t2, 3188($t0)
    sw $t1, 3192($t0)
    sw $t1, 3196($t0)
    sw $t2, 3200($t0)
    sw $t2, 3204($t0)
    sw $t2, 3208($t0)
    sw $t2, 3212($t0)
    sw $t1, 3216($t0)
    sw $t1, 3220($t0)
    sw $t2, 3224($t0)
    sw $t2, 3228($t0)
    sw $t2, 3232($t0)
    sw $t2, 3236($t0)
    sw $t1, 3240($t0)
    sw $t1, 3244($t0)
    sw $t2, 3248($t0)
    sw $t2, 3252($t0)
    sw $t1, 3256($t0)
    sw $t1, 3260($t0)
    sw $t1, 3264($t0)
    sw $t1, 3268($t0)
    sw $t1, 3272($t0)
    sw $t1, 3276($t0)
    sw $t1, 3280($t0)
    sw $t1, 3284($t0)
    sw $t1, 3288($t0)
    sw $t1, 3292($t0)
    sw $t1, 3360($t0)
    sw $t1, 3364($t0)
    sw $t1, 3368($t0)
    sw $t1, 3372($t0)
    sw $t2, 3376($t0)
    sw $t2, 3380($t0)
    sw $t1, 3384($t0)
    sw $t1, 3388($t0)
    sw $t1, 3392($t0)
    sw $t1, 3396($t0)
    sw $t1, 3400($t0)
    sw $t1, 3404($t0)
    sw $t1, 3408($t0)
    sw $t1, 3412($t0)
    sw $t2, 3416($t0)
    sw $t2, 3420($t0)
    sw $t1, 3424($t0)
    sw $t1, 3428($t0)
    sw $t1, 3432($t0)
    sw $t1, 3436($t0)
    sw $t2, 3440($t0)
    sw $t2, 3444($t0)
    sw $t1, 3448($t0)
    sw $t1, 3452($t0)
    sw $t2, 3456($t0)
    sw $t2, 3460($t0)
    sw $t2, 3464($t0)
    sw $t2, 3468($t0)
    sw $t1, 3472($t0)
    sw $t1, 3476($t0)
    sw $t2, 3480($t0)
    sw $t2, 3484($t0)
    sw $t2, 3488($t0)
    sw $t2, 3492($t0)
    sw $t1, 3496($t0)
    sw $t1, 3500($t0)
    sw $t2, 3504($t0)
    sw $t2, 3508($t0)
    sw $t1, 3512($t0)
    sw $t1, 3516($t0)
    sw $t1, 3520($t0)
    sw $t1, 3524($t0)
    sw $t1, 3528($t0)
    sw $t1, 3532($t0)
    sw $t1, 3536($t0)
    sw $t1, 3540($t0)
    sw $t1, 3544($t0)
    sw $t1, 3548($t0)
    sw $t1, 3616($t0)
    sw $t1, 3620($t0)
    sw $t1, 3624($t0)
    sw $t1, 3628($t0)
    sw $t2, 3632($t0)
    sw $t2, 3636($t0)
    sw $t1, 3640($t0)
    sw $t1, 3644($t0)
    sw $t2, 3648($t0)
    sw $t2, 3652($t0)
    sw $t2, 3656($t0)
    sw $t2, 3660($t0)
    sw $t1, 3664($t0)
    sw $t1, 3668($t0)
    sw $t2, 3672($t0)
    sw $t2, 3676($t0)
    sw $t2, 3680($t0)
    sw $t2, 3684($t0)
    sw $t2, 3688($t0)
    sw $t2, 3692($t0)
    sw $t2, 3696($t0)
    sw $t2, 3700($t0)
    sw $t1, 3704($t0)
    sw $t1, 3708($t0)
    sw $t2, 3712($t0)
    sw $t2, 3716($t0)
    sw $t1, 3720($t0)
    sw $t1, 3724($t0)
    sw $t2, 3728($t0)
    sw $t2, 3732($t0)
    sw $t1, 3736($t0)
    sw $t1, 3740($t0)
    sw $t2, 3744($t0)
    sw $t2, 3748($t0)
    sw $t1, 3752($t0)
    sw $t1, 3756($t0)
    sw $t2, 3760($t0)
    sw $t2, 3764($t0)
    sw $t2, 3768($t0)
    sw $t2, 3772($t0)
    sw $t2, 3776($t0)
    sw $t2, 3780($t0)
    sw $t1, 3784($t0)
    sw $t1, 3788($t0)
    sw $t1, 3792($t0)
    sw $t1, 3796($t0)
    sw $t1, 3800($t0)
    sw $t1, 3804($t0)
    sw $t1, 3872($t0)
    sw $t1, 3876($t0)
    sw $t1, 3880($t0)
    sw $t1, 3884($t0)
    sw $t2, 3888($t0)
    sw $t2, 3892($t0)
    sw $t1, 3896($t0)
    sw $t1, 3900($t0)
    sw $t2, 3904($t0)
    sw $t2, 3908($t0)
    sw $t2, 3912($t0)
    sw $t2, 3916($t0)
    sw $t1, 3920($t0)
    sw $t1, 3924($t0)
    sw $t2, 3928($t0)
    sw $t2, 3932($t0)
    sw $t2, 3936($t0)
    sw $t2, 3940($t0)
    sw $t2, 3944($t0)
    sw $t2, 3948($t0)
    sw $t2, 3952($t0)
    sw $t2, 3956($t0)
    sw $t1, 3960($t0)
    sw $t1, 3964($t0)
    sw $t2, 3968($t0)
    sw $t2, 3972($t0)
    sw $t1, 3976($t0)
    sw $t1, 3980($t0)
    sw $t2, 3984($t0)
    sw $t2, 3988($t0)
    sw $t1, 3992($t0)
    sw $t1, 3996($t0)
    sw $t2, 4000($t0)
    sw $t2, 4004($t0)
    sw $t1, 4008($t0)
    sw $t1, 4012($t0)
    sw $t2, 4016($t0)
    sw $t2, 4020($t0)
    sw $t2, 4024($t0)
    sw $t2, 4028($t0)
    sw $t2, 4032($t0)
    sw $t2, 4036($t0)
    sw $t1, 4040($t0)
    sw $t1, 4044($t0)
    sw $t1, 4048($t0)
    sw $t1, 4052($t0)
    sw $t1, 4056($t0)
    sw $t1, 4060($t0)
    sw $t1, 4128($t0)
    sw $t1, 4132($t0)
    sw $t1, 4136($t0)
    sw $t1, 4140($t0)
    sw $t2, 4144($t0)
    sw $t2, 4148($t0)
    sw $t1, 4152($t0)
    sw $t1, 4156($t0)
    sw $t1, 4160($t0)
    sw $t1, 4164($t0)
    sw $t2, 4168($t0)
    sw $t2, 4172($t0)
    sw $t1, 4176($t0)
    sw $t1, 4180($t0)
    sw $t2, 4184($t0)
    sw $t2, 4188($t0)
    sw $t1, 4192($t0)
    sw $t1, 4196($t0)
    sw $t1, 4200($t0)
    sw $t1, 4204($t0)
    sw $t2, 4208($t0)
    sw $t2, 4212($t0)
    sw $t1, 4216($t0)
    sw $t1, 4220($t0)
    sw $t2, 4224($t0)
    sw $t2, 4228($t0)
    sw $t1, 4232($t0)
    sw $t1, 4236($t0)
    sw $t1, 4240($t0)
    sw $t1, 4244($t0)
    sw $t1, 4248($t0)
    sw $t1, 4252($t0)
    sw $t2, 4256($t0)
    sw $t2, 4260($t0)
    sw $t1, 4264($t0)
    sw $t1, 4268($t0)
    sw $t2, 4272($t0)
    sw $t2, 4276($t0)
    sw $t1, 4280($t0)
    sw $t1, 4284($t0)
    sw $t1, 4288($t0)
    sw $t1, 4292($t0)
    sw $t1, 4296($t0)
    sw $t1, 4300($t0)
    sw $t1, 4304($t0)
    sw $t1, 4308($t0)
    sw $t1, 4312($t0)
    sw $t1, 4316($t0)
    sw $t1, 4384($t0)
    sw $t1, 4388($t0)
    sw $t1, 4392($t0)
    sw $t1, 4396($t0)
    sw $t2, 4400($t0)
    sw $t2, 4404($t0)
    sw $t1, 4408($t0)
    sw $t1, 4412($t0)
    sw $t1, 4416($t0)
    sw $t1, 4420($t0)
    sw $t2, 4424($t0)
    sw $t2, 4428($t0)
    sw $t1, 4432($t0)
    sw $t1, 4436($t0)
    sw $t2, 4440($t0)
    sw $t2, 4444($t0)
    sw $t1, 4448($t0)
    sw $t1, 4452($t0)
    sw $t1, 4456($t0)
    sw $t1, 4460($t0)
    sw $t2, 4464($t0)
    sw $t2, 4468($t0)
    sw $t1, 4472($t0)
    sw $t1, 4476($t0)
    sw $t2, 4480($t0)
    sw $t2, 4484($t0)
    sw $t1, 4488($t0)
    sw $t1, 4492($t0)
    sw $t1, 4496($t0)
    sw $t1, 4500($t0)
    sw $t1, 4504($t0)
    sw $t1, 4508($t0)
    sw $t2, 4512($t0)
    sw $t2, 4516($t0)
    sw $t1, 4520($t0)
    sw $t1, 4524($t0)
    sw $t2, 4528($t0)
    sw $t2, 4532($t0)
    sw $t1, 4536($t0)
    sw $t1, 4540($t0)
    sw $t1, 4544($t0)
    sw $t1, 4548($t0)
    sw $t1, 4552($t0)
    sw $t1, 4556($t0)
    sw $t1, 4560($t0)
    sw $t1, 4564($t0)
    sw $t1, 4568($t0)
    sw $t1, 4572($t0)
    sw $t1, 4640($t0)
    sw $t1, 4644($t0)
    sw $t1, 4648($t0)
    sw $t1, 4652($t0)
    sw $t1, 4656($t0)
    sw $t1, 4660($t0)
    sw $t2, 4664($t0)
    sw $t2, 4668($t0)
    sw $t2, 4672($t0)
    sw $t2, 4676($t0)
    sw $t1, 4680($t0)
    sw $t1, 4684($t0)
    sw $t1, 4688($t0)
    sw $t1, 4692($t0)
    sw $t2, 4696($t0)
    sw $t2, 4700($t0)
    sw $t1, 4704($t0)
    sw $t1, 4708($t0)
    sw $t1, 4712($t0)
    sw $t1, 4716($t0)
    sw $t2, 4720($t0)
    sw $t2, 4724($t0)
    sw $t1, 4728($t0)
    sw $t1, 4732($t0)
    sw $t2, 4736($t0)
    sw $t2, 4740($t0)
    sw $t1, 4744($t0)
    sw $t1, 4748($t0)
    sw $t1, 4752($t0)
    sw $t1, 4756($t0)
    sw $t1, 4760($t0)
    sw $t1, 4764($t0)
    sw $t2, 4768($t0)
    sw $t2, 4772($t0)
    sw $t1, 4776($t0)
    sw $t1, 4780($t0)
    sw $t2, 4784($t0)
    sw $t2, 4788($t0)
    sw $t2, 4792($t0)
    sw $t2, 4796($t0)
    sw $t2, 4800($t0)
    sw $t2, 4804($t0)
    sw $t2, 4808($t0)
    sw $t2, 4812($t0)
    sw $t1, 4816($t0)
    sw $t1, 4820($t0)
    sw $t1, 4824($t0)
    sw $t1, 4828($t0)
    sw $t1, 4896($t0)
    sw $t1, 4900($t0)
    sw $t1, 4904($t0)
    sw $t1, 4908($t0)
    sw $t1, 4912($t0)
    sw $t1, 4916($t0)
    sw $t2, 4920($t0)
    sw $t2, 4924($t0)
    sw $t2, 4928($t0)
    sw $t2, 4932($t0)
    sw $t1, 4936($t0)
    sw $t1, 4940($t0)
    sw $t1, 4944($t0)
    sw $t1, 4948($t0)
    sw $t2, 4952($t0)
    sw $t2, 4956($t0)
    sw $t1, 4960($t0)
    sw $t1, 4964($t0)
    sw $t1, 4968($t0)
    sw $t1, 4972($t0)
    sw $t2, 4976($t0)
    sw $t2, 4980($t0)
    sw $t1, 4984($t0)
    sw $t1, 4988($t0)
    sw $t2, 4992($t0)
    sw $t2, 4996($t0)
    sw $t1, 5000($t0)
    sw $t1, 5004($t0)
    sw $t1, 5008($t0)
    sw $t1, 5012($t0)
    sw $t1, 5016($t0)
    sw $t1, 5020($t0)
    sw $t2, 5024($t0)
    sw $t2, 5028($t0)
    sw $t1, 5032($t0)
    sw $t1, 5036($t0)
    sw $t2, 5040($t0)
    sw $t2, 5044($t0)
    sw $t2, 5048($t0)
    sw $t2, 5052($t0)
    sw $t2, 5056($t0)
    sw $t2, 5060($t0)
    sw $t2, 5064($t0)
    sw $t2, 5068($t0)
    sw $t1, 5072($t0)
    sw $t1, 5076($t0)
    sw $t1, 5080($t0)
    sw $t1, 5084($t0)
    sw $t1, 5152($t0)
    sw $t1, 5156($t0)
    sw $t1, 5160($t0)
    sw $t1, 5164($t0)
    sw $t1, 5168($t0)
    sw $t1, 5172($t0)
    sw $t1, 5176($t0)
    sw $t1, 5180($t0)
    sw $t1, 5184($t0)
    sw $t1, 5188($t0)
    sw $t1, 5192($t0)
    sw $t1, 5196($t0)
    sw $t1, 5200($t0)
    sw $t1, 5204($t0)
    sw $t1, 5208($t0)
    sw $t1, 5212($t0)
    sw $t1, 5216($t0)
    sw $t1, 5220($t0)
    sw $t1, 5224($t0)
    sw $t1, 5228($t0)
    sw $t1, 5232($t0)
    sw $t1, 5236($t0)
    sw $t1, 5240($t0)
    sw $t1, 5244($t0)
    sw $t1, 5248($t0)
    sw $t1, 5252($t0)
    sw $t1, 5256($t0)
    sw $t1, 5260($t0)
    sw $t1, 5264($t0)
    sw $t1, 5268($t0)
    sw $t1, 5272($t0)
    sw $t1, 5276($t0)
    sw $t1, 5280($t0)
    sw $t1, 5284($t0)
    sw $t1, 5288($t0)
    sw $t1, 5292($t0)
    sw $t1, 5296($t0)
    sw $t1, 5300($t0)
    sw $t1, 5304($t0)
    sw $t1, 5308($t0)
    sw $t1, 5312($t0)
    sw $t1, 5316($t0)
    sw $t1, 5320($t0)
    sw $t1, 5324($t0)
    sw $t1, 5328($t0)
    sw $t1, 5332($t0)
    sw $t1, 5336($t0)
    sw $t1, 5340($t0)
    sw $t1, 5408($t0)
    sw $t1, 5412($t0)
    sw $t1, 5416($t0)
    sw $t1, 5420($t0)
    sw $t1, 5424($t0)
    sw $t1, 5428($t0)
    sw $t1, 5432($t0)
    sw $t1, 5436($t0)
    sw $t1, 5440($t0)
    sw $t1, 5444($t0)
    sw $t1, 5448($t0)
    sw $t1, 5452($t0)
    sw $t1, 5456($t0)
    sw $t1, 5460($t0)
    sw $t1, 5464($t0)
    sw $t1, 5468($t0)
    sw $t1, 5472($t0)
    sw $t1, 5476($t0)
    sw $t1, 5480($t0)
    sw $t1, 5484($t0)
    sw $t1, 5488($t0)
    sw $t1, 5492($t0)
    sw $t1, 5496($t0)
    sw $t1, 5500($t0)
    sw $t1, 5504($t0)
    sw $t1, 5508($t0)
    sw $t1, 5512($t0)
    sw $t1, 5516($t0)
    sw $t1, 5520($t0)
    sw $t1, 5524($t0)
    sw $t1, 5528($t0)
    sw $t1, 5532($t0)
    sw $t1, 5536($t0)
    sw $t1, 5540($t0)
    sw $t1, 5544($t0)
    sw $t1, 5548($t0)
    sw $t1, 5552($t0)
    sw $t1, 5556($t0)
    sw $t1, 5560($t0)
    sw $t1, 5564($t0)
    sw $t1, 5568($t0)
    sw $t1, 5572($t0)
    sw $t1, 5576($t0)
    sw $t1, 5580($t0)
    sw $t1, 5584($t0)
    sw $t1, 5588($t0)
    sw $t1, 5592($t0)
    sw $t1, 5596($t0)
    sw $t1, 5664($t0)
    sw $t1, 5668($t0)
    sw $t1, 5672($t0)
    sw $t1, 5676($t0)
    sw $t1, 5680($t0)
    sw $t1, 5684($t0)
    sw $t1, 5688($t0)
    sw $t1, 5692($t0)
    sw $t1, 5696($t0)
    sw $t1, 5700($t0)
    sw $t1, 5704($t0)
    sw $t1, 5708($t0)
    sw $t1, 5712($t0)
    sw $t1, 5716($t0)
    sw $t1, 5720($t0)
    sw $t1, 5724($t0)
    sw $t1, 5728($t0)
    sw $t1, 5732($t0)
    sw $t1, 5736($t0)
    sw $t1, 5740($t0)
    sw $t1, 5744($t0)
    sw $t1, 5748($t0)
    sw $t1, 5752($t0)
    sw $t1, 5756($t0)
    sw $t1, 5760($t0)
    sw $t1, 5764($t0)
    sw $t1, 5768($t0)
    sw $t1, 5772($t0)
    sw $t1, 5776($t0)
    sw $t1, 5780($t0)
    sw $t1, 5784($t0)
    sw $t1, 5788($t0)
    sw $t1, 5792($t0)
    sw $t1, 5796($t0)
    sw $t1, 5800($t0)
    sw $t1, 5804($t0)
    sw $t1, 5808($t0)
    sw $t1, 5812($t0)
    sw $t1, 5816($t0)
    sw $t1, 5820($t0)
    sw $t1, 5824($t0)
    sw $t1, 5828($t0)
    sw $t1, 5832($t0)
    sw $t1, 5836($t0)
    sw $t1, 5840($t0)
    sw $t1, 5844($t0)
    sw $t1, 5848($t0)
    sw $t1, 5852($t0)
    sw $t1, 5920($t0)
    sw $t1, 5924($t0)
    sw $t1, 5928($t0)
    sw $t2, 5932($t0)
    sw $t2, 5936($t0)
    sw $t2, 5940($t0)
    sw $t2, 5944($t0)
    sw $t1, 5948($t0)
    sw $t1, 5952($t0)
    sw $t1, 5956($t0)
    sw $t1, 5960($t0)
    sw $t2, 5964($t0)
    sw $t2, 5968($t0)
    sw $t1, 5972($t0)
    sw $t1, 5976($t0)
    sw $t1, 5980($t0)
    sw $t1, 5984($t0)
    sw $t1, 5988($t0)
    sw $t1, 5992($t0)
    sw $t2, 5996($t0)
    sw $t2, 6000($t0)
    sw $t1, 6004($t0)
    sw $t1, 6008($t0)
    sw $t2, 6012($t0)
    sw $t2, 6016($t0)
    sw $t2, 6020($t0)
    sw $t2, 6024($t0)
    sw $t2, 6028($t0)
    sw $t2, 6032($t0)
    sw $t2, 6036($t0)
    sw $t2, 6040($t0)
    sw $t1, 6044($t0)
    sw $t1, 6048($t0)
    sw $t2, 6052($t0)
    sw $t2, 6056($t0)
    sw $t2, 6060($t0)
    sw $t2, 6064($t0)
    sw $t2, 6068($t0)
    sw $t2, 6072($t0)
    sw $t1, 6076($t0)
    sw $t1, 6080($t0)
    sw $t1, 6084($t0)
    sw $t1, 6088($t0)
    sw $t1, 6092($t0)
    sw $t1, 6096($t0)
    sw $t2, 6100($t0)
    sw $t2, 6104($t0)
    sw $t1, 6108($t0)
    sw $t1, 6176($t0)
    sw $t1, 6180($t0)
    sw $t1, 6184($t0)
    sw $t2, 6188($t0)
    sw $t2, 6192($t0)
    sw $t2, 6196($t0)
    sw $t2, 6200($t0)
    sw $t1, 6204($t0)
    sw $t1, 6208($t0)
    sw $t1, 6212($t0)
    sw $t1, 6216($t0)
    sw $t2, 6220($t0)
    sw $t2, 6224($t0)
    sw $t1, 6228($t0)
    sw $t1, 6232($t0)
    sw $t1, 6236($t0)
    sw $t1, 6240($t0)
    sw $t1, 6244($t0)
    sw $t1, 6248($t0)
    sw $t2, 6252($t0)
    sw $t2, 6256($t0)
    sw $t1, 6260($t0)
    sw $t1, 6264($t0)
    sw $t2, 6268($t0)
    sw $t2, 6272($t0)
    sw $t2, 6276($t0)
    sw $t2, 6280($t0)
    sw $t2, 6284($t0)
    sw $t2, 6288($t0)
    sw $t2, 6292($t0)
    sw $t2, 6296($t0)
    sw $t1, 6300($t0)
    sw $t1, 6304($t0)
    sw $t2, 6308($t0)
    sw $t2, 6312($t0)
    sw $t2, 6316($t0)
    sw $t2, 6320($t0)
    sw $t2, 6324($t0)
    sw $t2, 6328($t0)
    sw $t1, 6332($t0)
    sw $t1, 6336($t0)
    sw $t1, 6340($t0)
    sw $t1, 6344($t0)
    sw $t1, 6348($t0)
    sw $t1, 6352($t0)
    sw $t2, 6356($t0)
    sw $t2, 6360($t0)
    sw $t1, 6364($t0)
    sw $t1, 6432($t0)
    sw $t2, 6436($t0)
    sw $t2, 6440($t0)
    sw $t1, 6444($t0)
    sw $t1, 6448($t0)
    sw $t1, 6452($t0)
    sw $t1, 6456($t0)
    sw $t2, 6460($t0)
    sw $t2, 6464($t0)
    sw $t1, 6468($t0)
    sw $t1, 6472($t0)
    sw $t2, 6476($t0)
    sw $t2, 6480($t0)
    sw $t1, 6484($t0)
    sw $t1, 6488($t0)
    sw $t1, 6492($t0)
    sw $t1, 6496($t0)
    sw $t1, 6500($t0)
    sw $t1, 6504($t0)
    sw $t2, 6508($t0)
    sw $t2, 6512($t0)
    sw $t1, 6516($t0)
    sw $t1, 6520($t0)
    sw $t2, 6524($t0)
    sw $t2, 6528($t0)
    sw $t1, 6532($t0)
    sw $t1, 6536($t0)
    sw $t1, 6540($t0)
    sw $t1, 6544($t0)
    sw $t1, 6548($t0)
    sw $t1, 6552($t0)
    sw $t1, 6556($t0)
    sw $t1, 6560($t0)
    sw $t2, 6564($t0)
    sw $t2, 6568($t0)
    sw $t1, 6572($t0)
    sw $t1, 6576($t0)
    sw $t1, 6580($t0)
    sw $t1, 6584($t0)
    sw $t2, 6588($t0)
    sw $t2, 6592($t0)
    sw $t1, 6596($t0)
    sw $t1, 6600($t0)
    sw $t1, 6604($t0)
    sw $t1, 6608($t0)
    sw $t2, 6612($t0)
    sw $t2, 6616($t0)
    sw $t1, 6620($t0)
    sw $t1, 6688($t0)
    sw $t2, 6692($t0)
    sw $t2, 6696($t0)
    sw $t1, 6700($t0)
    sw $t1, 6704($t0)
    sw $t1, 6708($t0)
    sw $t1, 6712($t0)
    sw $t2, 6716($t0)
    sw $t2, 6720($t0)
    sw $t1, 6724($t0)
    sw $t1, 6728($t0)
    sw $t2, 6732($t0)
    sw $t2, 6736($t0)
    sw $t1, 6740($t0)
    sw $t1, 6744($t0)
    sw $t1, 6748($t0)
    sw $t1, 6752($t0)
    sw $t1, 6756($t0)
    sw $t1, 6760($t0)
    sw $t2, 6764($t0)
    sw $t2, 6768($t0)
    sw $t1, 6772($t0)
    sw $t1, 6776($t0)
    sw $t2, 6780($t0)
    sw $t2, 6784($t0)
    sw $t1, 6788($t0)
    sw $t1, 6792($t0)
    sw $t1, 6796($t0)
    sw $t1, 6800($t0)
    sw $t1, 6804($t0)
    sw $t1, 6808($t0)
    sw $t1, 6812($t0)
    sw $t1, 6816($t0)
    sw $t2, 6820($t0)
    sw $t2, 6824($t0)
    sw $t1, 6828($t0)
    sw $t1, 6832($t0)
    sw $t1, 6836($t0)
    sw $t1, 6840($t0)
    sw $t2, 6844($t0)
    sw $t2, 6848($t0)
    sw $t1, 6852($t0)
    sw $t1, 6856($t0)
    sw $t1, 6860($t0)
    sw $t1, 6864($t0)
    sw $t2, 6868($t0)
    sw $t2, 6872($t0)
    sw $t1, 6876($t0)
    sw $t1, 6944($t0)
    sw $t2, 6948($t0)
    sw $t2, 6952($t0)
    sw $t1, 6956($t0)
    sw $t1, 6960($t0)
    sw $t1, 6964($t0)
    sw $t1, 6968($t0)
    sw $t2, 6972($t0)
    sw $t2, 6976($t0)
    sw $t1, 6980($t0)
    sw $t1, 6984($t0)
    sw $t1, 6988($t0)
    sw $t1, 6992($t0)
    sw $t2, 6996($t0)
    sw $t2, 7000($t0)
    sw $t1, 7004($t0)
    sw $t1, 7008($t0)
    sw $t2, 7012($t0)
    sw $t2, 7016($t0)
    sw $t1, 7020($t0)
    sw $t1, 7024($t0)
    sw $t1, 7028($t0)
    sw $t1, 7032($t0)
    sw $t2, 7036($t0)
    sw $t2, 7040($t0)
    sw $t2, 7044($t0)
    sw $t2, 7048($t0)
    sw $t2, 7052($t0)
    sw $t2, 7056($t0)
    sw $t1, 7060($t0)
    sw $t1, 7064($t0)
    sw $t1, 7068($t0)
    sw $t1, 7072($t0)
    sw $t2, 7076($t0)
    sw $t2, 7080($t0)
    sw $t2, 7084($t0)
    sw $t2, 7088($t0)
    sw $t2, 7092($t0)
    sw $t2, 7096($t0)
    sw $t1, 7100($t0)
    sw $t1, 7104($t0)
    sw $t1, 7108($t0)
    sw $t1, 7112($t0)
    sw $t1, 7116($t0)
    sw $t1, 7120($t0)
    sw $t2, 7124($t0)
    sw $t2, 7128($t0)
    sw $t1, 7132($t0)
    sw $t1, 7200($t0)
    sw $t2, 7204($t0)
    sw $t2, 7208($t0)
    sw $t1, 7212($t0)
    sw $t1, 7216($t0)
    sw $t1, 7220($t0)
    sw $t1, 7224($t0)
    sw $t2, 7228($t0)
    sw $t2, 7232($t0)
    sw $t1, 7236($t0)
    sw $t1, 7240($t0)
    sw $t1, 7244($t0)
    sw $t1, 7248($t0)
    sw $t2, 7252($t0)
    sw $t2, 7256($t0)
    sw $t1, 7260($t0)
    sw $t1, 7264($t0)
    sw $t2, 7268($t0)
    sw $t2, 7272($t0)
    sw $t1, 7276($t0)
    sw $t1, 7280($t0)
    sw $t1, 7284($t0)
    sw $t1, 7288($t0)
    sw $t2, 7292($t0)
    sw $t2, 7296($t0)
    sw $t2, 7300($t0)
    sw $t2, 7304($t0)
    sw $t2, 7308($t0)
    sw $t2, 7312($t0)
    sw $t1, 7316($t0)
    sw $t1, 7320($t0)
    sw $t1, 7324($t0)
    sw $t1, 7328($t0)
    sw $t2, 7332($t0)
    sw $t2, 7336($t0)
    sw $t2, 7340($t0)
    sw $t2, 7344($t0)
    sw $t2, 7348($t0)
    sw $t2, 7352($t0)
    sw $t1, 7356($t0)
    sw $t1, 7360($t0)
    sw $t1, 7364($t0)
    sw $t1, 7368($t0)
    sw $t1, 7372($t0)
    sw $t1, 7376($t0)
    sw $t2, 7380($t0)
    sw $t2, 7384($t0)
    sw $t1, 7388($t0)
    sw $t1, 7456($t0)
    sw $t2, 7460($t0)
    sw $t2, 7464($t0)
    sw $t1, 7468($t0)
    sw $t1, 7472($t0)
    sw $t1, 7476($t0)
    sw $t1, 7480($t0)
    sw $t2, 7484($t0)
    sw $t2, 7488($t0)
    sw $t1, 7492($t0)
    sw $t1, 7496($t0)
    sw $t1, 7500($t0)
    sw $t1, 7504($t0)
    sw $t2, 7508($t0)
    sw $t2, 7512($t0)
    sw $t1, 7516($t0)
    sw $t1, 7520($t0)
    sw $t2, 7524($t0)
    sw $t2, 7528($t0)
    sw $t1, 7532($t0)
    sw $t1, 7536($t0)
    sw $t1, 7540($t0)
    sw $t1, 7544($t0)
    sw $t2, 7548($t0)
    sw $t2, 7552($t0)
    sw $t1, 7556($t0)
    sw $t1, 7560($t0)
    sw $t1, 7564($t0)
    sw $t1, 7568($t0)
    sw $t1, 7572($t0)
    sw $t1, 7576($t0)
    sw $t1, 7580($t0)
    sw $t1, 7584($t0)
    sw $t2, 7588($t0)
    sw $t2, 7592($t0)
    sw $t1, 7596($t0)
    sw $t1, 7600($t0)
    sw $t2, 7604($t0)
    sw $t2, 7608($t0)
    sw $t1, 7612($t0)
    sw $t1, 7616($t0)
    sw $t1, 7620($t0)
    sw $t1, 7624($t0)
    sw $t1, 7628($t0)
    sw $t1, 7632($t0)
    sw $t1, 7636($t0)
    sw $t1, 7640($t0)
    sw $t1, 7644($t0)
    sw $t1, 7712($t0)
    sw $t2, 7716($t0)
    sw $t2, 7720($t0)
    sw $t1, 7724($t0)
    sw $t1, 7728($t0)
    sw $t1, 7732($t0)
    sw $t1, 7736($t0)
    sw $t2, 7740($t0)
    sw $t2, 7744($t0)
    sw $t1, 7748($t0)
    sw $t1, 7752($t0)
    sw $t1, 7756($t0)
    sw $t1, 7760($t0)
    sw $t2, 7764($t0)
    sw $t2, 7768($t0)
    sw $t1, 7772($t0)
    sw $t1, 7776($t0)
    sw $t2, 7780($t0)
    sw $t2, 7784($t0)
    sw $t1, 7788($t0)
    sw $t1, 7792($t0)
    sw $t1, 7796($t0)
    sw $t1, 7800($t0)
    sw $t2, 7804($t0)
    sw $t2, 7808($t0)
    sw $t1, 7812($t0)
    sw $t1, 7816($t0)
    sw $t1, 7820($t0)
    sw $t1, 7824($t0)
    sw $t1, 7828($t0)
    sw $t1, 7832($t0)
    sw $t1, 7836($t0)
    sw $t1, 7840($t0)
    sw $t2, 7844($t0)
    sw $t2, 7848($t0)
    sw $t1, 7852($t0)
    sw $t1, 7856($t0)
    sw $t2, 7860($t0)
    sw $t2, 7864($t0)
    sw $t1, 7868($t0)
    sw $t1, 7872($t0)
    sw $t1, 7876($t0)
    sw $t1, 7880($t0)
    sw $t1, 7884($t0)
    sw $t1, 7888($t0)
    sw $t1, 7892($t0)
    sw $t1, 7896($t0)
    sw $t1, 7900($t0)
    sw $t1, 7968($t0)
    sw $t1, 7972($t0)
    sw $t1, 7976($t0)
    sw $t2, 7980($t0)
    sw $t2, 7984($t0)
    sw $t2, 7988($t0)
    sw $t2, 7992($t0)
    sw $t1, 7996($t0)
    sw $t1, 8000($t0)
    sw $t1, 8004($t0)
    sw $t1, 8008($t0)
    sw $t1, 8012($t0)
    sw $t1, 8016($t0)
    sw $t1, 8020($t0)
    sw $t1, 8024($t0)
    sw $t2, 8028($t0)
    sw $t2, 8032($t0)
    sw $t1, 8036($t0)
    sw $t1, 8040($t0)
    sw $t1, 8044($t0)
    sw $t1, 8048($t0)
    sw $t1, 8052($t0)
    sw $t1, 8056($t0)
    sw $t2, 8060($t0)
    sw $t2, 8064($t0)
    sw $t2, 8068($t0)
    sw $t2, 8072($t0)
    sw $t2, 8076($t0)
    sw $t2, 8080($t0)
    sw $t2, 8084($t0)
    sw $t2, 8088($t0)
    sw $t1, 8092($t0)
    sw $t1, 8096($t0)
    sw $t2, 8100($t0)
    sw $t2, 8104($t0)
    sw $t1, 8108($t0)
    sw $t1, 8112($t0)
    sw $t1, 8116($t0)
    sw $t1, 8120($t0)
    sw $t2, 8124($t0)
    sw $t2, 8128($t0)
    sw $t1, 8132($t0)
    sw $t1, 8136($t0)
    sw $t1, 8140($t0)
    sw $t1, 8144($t0)
    sw $t2, 8148($t0)
    sw $t2, 8152($t0)
    sw $t1, 8156($t0)
    sw $t1, 8224($t0)
    sw $t1, 8228($t0)
    sw $t1, 8232($t0)
    sw $t2, 8236($t0)
    sw $t2, 8240($t0)
    sw $t2, 8244($t0)
    sw $t2, 8248($t0)
    sw $t1, 8252($t0)
    sw $t1, 8256($t0)
    sw $t1, 8260($t0)
    sw $t1, 8264($t0)
    sw $t1, 8268($t0)
    sw $t1, 8272($t0)
    sw $t1, 8276($t0)
    sw $t1, 8280($t0)
    sw $t2, 8284($t0)
    sw $t2, 8288($t0)
    sw $t1, 8292($t0)
    sw $t1, 8296($t0)
    sw $t1, 8300($t0)
    sw $t1, 8304($t0)
    sw $t1, 8308($t0)
    sw $t1, 8312($t0)
    sw $t2, 8316($t0)
    sw $t2, 8320($t0)
    sw $t2, 8324($t0)
    sw $t2, 8328($t0)
    sw $t2, 8332($t0)
    sw $t2, 8336($t0)
    sw $t2, 8340($t0)
    sw $t2, 8344($t0)
    sw $t1, 8348($t0)
    sw $t1, 8352($t0)
    sw $t2, 8356($t0)
    sw $t2, 8360($t0)
    sw $t1, 8364($t0)
    sw $t1, 8368($t0)
    sw $t1, 8372($t0)
    sw $t1, 8376($t0)
    sw $t2, 8380($t0)
    sw $t2, 8384($t0)
    sw $t1, 8388($t0)
    sw $t1, 8392($t0)
    sw $t1, 8396($t0)
    sw $t1, 8400($t0)
    sw $t2, 8404($t0)
    sw $t2, 8408($t0)
    sw $t1, 8412($t0)
    sw $t1, 8480($t0)
    sw $t1, 8484($t0)
    sw $t1, 8488($t0)
    sw $t1, 8492($t0)
    sw $t1, 8496($t0)
    sw $t1, 8500($t0)
    sw $t1, 8504($t0)
    sw $t1, 8508($t0)
    sw $t1, 8512($t0)
    sw $t1, 8516($t0)
    sw $t1, 8520($t0)
    sw $t1, 8524($t0)
    sw $t1, 8528($t0)
    sw $t1, 8532($t0)
    sw $t1, 8536($t0)
    sw $t1, 8540($t0)
    sw $t1, 8544($t0)
    sw $t1, 8548($t0)
    sw $t1, 8552($t0)
    sw $t1, 8556($t0)
    sw $t1, 8560($t0)
    sw $t1, 8564($t0)
    sw $t1, 8568($t0)
    sw $t1, 8572($t0)
    sw $t1, 8576($t0)
    sw $t1, 8580($t0)
    sw $t1, 8584($t0)
    sw $t1, 8588($t0)
    sw $t1, 8592($t0)
    sw $t1, 8596($t0)
    sw $t1, 8600($t0)
    sw $t1, 8604($t0)
    sw $t1, 8608($t0)
    sw $t1, 8612($t0)
    sw $t1, 8616($t0)
    sw $t1, 8620($t0)
    sw $t1, 8624($t0)
    sw $t1, 8628($t0)
    sw $t1, 8632($t0)
    sw $t1, 8636($t0)
    sw $t1, 8640($t0)
    sw $t1, 8644($t0)
    sw $t1, 8648($t0)
    sw $t1, 8652($t0)
    sw $t1, 8656($t0)
    sw $t1, 8660($t0)
    sw $t1, 8664($t0)
    sw $t1, 8668($t0)
    sw $t2, 9492($t0)
    sw $t2, 9496($t0)
    sw $t2, 9516($t0)
    sw $t2, 9520($t0)
    sw $t2, 9524($t0)
    sw $t2, 9528($t0)
    sw $t2, 9532($t0)
    sw $t2, 9544($t0)
    sw $t2, 9548($t0)
    sw $t2, 9572($t0)
    sw $t2, 9576($t0)
    sw $t2, 9588($t0)
    sw $t2, 9600($t0)
    sw $t2, 9608($t0)
    sw $t2, 9612($t0)
    sw $t2, 9616($t0)
    sw $t2, 9624($t0)
    sw $t2, 9628($t0)
    sw $t2, 9632($t0)
    sw $t2, 9636($t0)
    sw $t2, 9640($t0)
    sw $t2, 9744($t0)
    sw $t2, 9756($t0)
    sw $t2, 9780($t0)
    sw $t2, 9796($t0)
    sw $t2, 9808($t0)
    sw $t2, 9824($t0)
    sw $t2, 9836($t0)
    sw $t2, 9844($t0)
    sw $t2, 9856($t0)
    sw $t2, 9868($t0)
    sw $t2, 9888($t0)
    sw $t2, 10000($t0)
    sw $t2, 10012($t0)
    sw $t2, 10036($t0)
    sw $t2, 10052($t0)
    sw $t2, 10064($t0)
    sw $t2, 10080($t0)
    sw $t2, 10092($t0)
    sw $t2, 10100($t0)
    sw $t2, 10112($t0)
    sw $t2, 10124($t0)
    sw $t2, 10144($t0)
    sw $t2, 10256($t0)
    sw $t2, 10264($t0)
    sw $t2, 10292($t0)
    sw $t2, 10308($t0)
    sw $t2, 10320($t0)
    sw $t2, 10336($t0)
    sw $t2, 10344($t0)
    sw $t2, 10356($t0)
    sw $t2, 10368($t0)
    sw $t2, 10380($t0)
    sw $t2, 10400($t0)
    sw $t2, 10516($t0)
    sw $t2, 10524($t0)
    sw $t2, 10548($t0)
    sw $t2, 10568($t0)
    sw $t2, 10572($t0)
    sw $t2, 10596($t0)
    sw $t2, 10604($t0)
    sw $t2, 10616($t0)
    sw $t2, 10620($t0)
    sw $t2, 10632($t0)
    sw $t2, 10636($t0)
    sw $t2, 10640($t0)
    sw $t2, 10656($t0)
    sw $t2, 11024($t0)
    sw $t2, 11028($t0)
    sw $t2, 11032($t0)
    sw $t2, 11052($t0)
    sw $t2, 11056($t0)
    sw $t2, 11060($t0)
    sw $t2, 11064($t0)
    sw $t2, 11068($t0)
    sw $t2, 11080($t0)
    sw $t2, 11084($t0)
    sw $t2, 11104($t0)
    sw $t2, 11108($t0)
    sw $t2, 11112($t0)
    sw $t2, 11124($t0)
    sw $t2, 11128($t0)
    sw $t2, 11132($t0)
    sw $t2, 11136($t0)
    sw $t2, 11148($t0)
    sw $t2, 11152($t0)
    sw $t2, 11156($t0)
    sw $t2, 11164($t0)
    sw $t2, 11168($t0)
    sw $t2, 11172($t0)
    sw $t2, 11176($t0)
    sw $t2, 11180($t0)
    sw $t2, 11192($t0)
    sw $t2, 11196($t0)
    sw $t2, 11208($t0)
    sw $t2, 11212($t0)
    sw $t2, 11216($t0)
    sw $t2, 11228($t0)
    sw $t2, 11232($t0)
    sw $t2, 11236($t0)
    sw $t2, 11240($t0)
    sw $t2, 11244($t0)
    sw $t2, 11280($t0)
    sw $t2, 11292($t0)
    sw $t2, 11316($t0)
    sw $t2, 11332($t0)
    sw $t2, 11344($t0)
    sw $t2, 11360($t0)
    sw $t2, 11372($t0)
    sw $t2, 11380($t0)
    sw $t2, 11400($t0)
    sw $t2, 11428($t0)
    sw $t2, 11444($t0)
    sw $t2, 11456($t0)
    sw $t2, 11464($t0)
    sw $t2, 11476($t0)
    sw $t2, 11492($t0)
    sw $t2, 11536($t0)
    sw $t2, 11540($t0)
    sw $t2, 11544($t0)
    sw $t2, 11572($t0)
    sw $t2, 11588($t0)
    sw $t2, 11600($t0)
    sw $t2, 11616($t0)
    sw $t2, 11620($t0)
    sw $t2, 11624($t0)
    sw $t2, 11636($t0)
    sw $t2, 11640($t0)
    sw $t2, 11644($t0)
    sw $t2, 11660($t0)
    sw $t2, 11664($t0)
    sw $t2, 11684($t0)
    sw $t2, 11700($t0)
    sw $t2, 11704($t0)
    sw $t2, 11708($t0)
    sw $t2, 11712($t0)
    sw $t2, 11720($t0)
    sw $t2, 11724($t0)
    sw $t2, 11728($t0)
    sw $t2, 11748($t0)
    sw $t2, 11792($t0)
    sw $t2, 11800($t0)
    sw $t2, 11828($t0)
    sw $t2, 11844($t0)
    sw $t2, 11856($t0)
    sw $t2, 11872($t0)
    sw $t2, 11880($t0)
    sw $t2, 11892($t0)
    sw $t2, 11924($t0)
    sw $t2, 11940($t0)
    sw $t2, 11956($t0)
    sw $t2, 11968($t0)
    sw $t2, 11976($t0)
    sw $t2, 11984($t0)
    sw $t2, 12004($t0)
    sw $t2, 12048($t0)
    sw $t2, 12060($t0)
    sw $t2, 12084($t0)
    sw $t2, 12104($t0)
    sw $t2, 12108($t0)
    sw $t2, 12128($t0)
    sw $t2, 12140($t0)
    sw $t2, 12148($t0)
    sw $t2, 12152($t0)
    sw $t2, 12156($t0)
    sw $t2, 12160($t0)
    sw $t2, 12168($t0)
    sw $t2, 12172($t0)
    sw $t2, 12176($t0)
    sw $t2, 12196($t0)
    sw $t2, 12212($t0)
    sw $t2, 12224($t0)
    sw $t2, 12232($t0)
    sw $t2, 12244($t0)
    sw $t2, 12260($t0)

    jr $ra

# Uses:
    # $t0
    # $t1
    # $t2
draw_you_won_screen:
    la $t0, DISPLAY_BASE_ADDRESS
    li $t1, COLOUR_PLAYER
    li $t2, COLOUR_UI_TEXT

    sw $t1, 2356($t0)
    sw $t1, 2360($t0)
    sw $t1, 2364($t0)
    sw $t1, 2368($t0)
    sw $t1, 2372($t0)
    sw $t1, 2376($t0)
    sw $t1, 2380($t0)
    sw $t1, 2384($t0)
    sw $t1, 2388($t0)
    sw $t1, 2392($t0)
    sw $t1, 2396($t0)
    sw $t1, 2400($t0)
    sw $t1, 2404($t0)
    sw $t1, 2408($t0)
    sw $t1, 2412($t0)
    sw $t1, 2416($t0)
    sw $t1, 2420($t0)
    sw $t1, 2424($t0)
    sw $t1, 2428($t0)
    sw $t1, 2432($t0)
    sw $t1, 2436($t0)
    sw $t1, 2440($t0)
    sw $t1, 2444($t0)
    sw $t1, 2448($t0)
    sw $t1, 2452($t0)
    sw $t1, 2456($t0)
    sw $t1, 2460($t0)
    sw $t1, 2464($t0)
    sw $t1, 2468($t0)
    sw $t1, 2472($t0)
    sw $t1, 2476($t0)
    sw $t1, 2480($t0)
    sw $t1, 2484($t0)
    sw $t1, 2488($t0)
    sw $t1, 2492($t0)
    sw $t1, 2496($t0)
    sw $t1, 2500($t0)
    sw $t1, 2504($t0)
    sw $t1, 2612($t0)
    sw $t1, 2616($t0)
    sw $t1, 2620($t0)
    sw $t1, 2624($t0)
    sw $t2, 2628($t0)
    sw $t2, 2632($t0)
    sw $t1, 2636($t0)
    sw $t1, 2640($t0)
    sw $t1, 2644($t0)
    sw $t1, 2648($t0)
    sw $t1, 2652($t0)
    sw $t1, 2656($t0)
    sw $t2, 2660($t0)
    sw $t2, 2664($t0)
    sw $t1, 2668($t0)
    sw $t1, 2672($t0)
    sw $t1, 2676($t0)
    sw $t1, 2680($t0)
    sw $t2, 2684($t0)
    sw $t2, 2688($t0)
    sw $t2, 2692($t0)
    sw $t2, 2696($t0)
    sw $t1, 2700($t0)
    sw $t1, 2704($t0)
    sw $t1, 2708($t0)
    sw $t1, 2712($t0)
    sw $t2, 2716($t0)
    sw $t2, 2720($t0)
    sw $t1, 2724($t0)
    sw $t1, 2728($t0)
    sw $t1, 2732($t0)
    sw $t1, 2736($t0)
    sw $t2, 2740($t0)
    sw $t2, 2744($t0)
    sw $t1, 2748($t0)
    sw $t1, 2752($t0)
    sw $t1, 2756($t0)
    sw $t1, 2760($t0)
    sw $t1, 2868($t0)
    sw $t1, 2872($t0)
    sw $t1, 2876($t0)
    sw $t1, 2880($t0)
    sw $t2, 2884($t0)
    sw $t2, 2888($t0)
    sw $t1, 2892($t0)
    sw $t1, 2896($t0)
    sw $t1, 2900($t0)
    sw $t1, 2904($t0)
    sw $t1, 2908($t0)
    sw $t1, 2912($t0)
    sw $t2, 2916($t0)
    sw $t2, 2920($t0)
    sw $t1, 2924($t0)
    sw $t1, 2928($t0)
    sw $t1, 2932($t0)
    sw $t1, 2936($t0)
    sw $t2, 2940($t0)
    sw $t2, 2944($t0)
    sw $t2, 2948($t0)
    sw $t2, 2952($t0)
    sw $t1, 2956($t0)
    sw $t1, 2960($t0)
    sw $t1, 2964($t0)
    sw $t1, 2968($t0)
    sw $t2, 2972($t0)
    sw $t2, 2976($t0)
    sw $t1, 2980($t0)
    sw $t1, 2984($t0)
    sw $t1, 2988($t0)
    sw $t1, 2992($t0)
    sw $t2, 2996($t0)
    sw $t2, 3000($t0)
    sw $t1, 3004($t0)
    sw $t1, 3008($t0)
    sw $t1, 3012($t0)
    sw $t1, 3016($t0)
    sw $t1, 3124($t0)
    sw $t1, 3128($t0)
    sw $t1, 3132($t0)
    sw $t1, 3136($t0)
    sw $t2, 3140($t0)
    sw $t2, 3144($t0)
    sw $t1, 3148($t0)
    sw $t1, 3152($t0)
    sw $t1, 3156($t0)
    sw $t1, 3160($t0)
    sw $t1, 3164($t0)
    sw $t1, 3168($t0)
    sw $t2, 3172($t0)
    sw $t2, 3176($t0)
    sw $t1, 3180($t0)
    sw $t1, 3184($t0)
    sw $t2, 3188($t0)
    sw $t2, 3192($t0)
    sw $t1, 3196($t0)
    sw $t1, 3200($t0)
    sw $t1, 3204($t0)
    sw $t1, 3208($t0)
    sw $t2, 3212($t0)
    sw $t2, 3216($t0)
    sw $t1, 3220($t0)
    sw $t1, 3224($t0)
    sw $t2, 3228($t0)
    sw $t2, 3232($t0)
    sw $t1, 3236($t0)
    sw $t1, 3240($t0)
    sw $t1, 3244($t0)
    sw $t1, 3248($t0)
    sw $t2, 3252($t0)
    sw $t2, 3256($t0)
    sw $t1, 3260($t0)
    sw $t1, 3264($t0)
    sw $t1, 3268($t0)
    sw $t1, 3272($t0)
    sw $t1, 3380($t0)
    sw $t1, 3384($t0)
    sw $t1, 3388($t0)
    sw $t1, 3392($t0)
    sw $t2, 3396($t0)
    sw $t2, 3400($t0)
    sw $t1, 3404($t0)
    sw $t1, 3408($t0)
    sw $t1, 3412($t0)
    sw $t1, 3416($t0)
    sw $t1, 3420($t0)
    sw $t1, 3424($t0)
    sw $t2, 3428($t0)
    sw $t2, 3432($t0)
    sw $t1, 3436($t0)
    sw $t1, 3440($t0)
    sw $t2, 3444($t0)
    sw $t2, 3448($t0)
    sw $t1, 3452($t0)
    sw $t1, 3456($t0)
    sw $t1, 3460($t0)
    sw $t1, 3464($t0)
    sw $t2, 3468($t0)
    sw $t2, 3472($t0)
    sw $t1, 3476($t0)
    sw $t1, 3480($t0)
    sw $t2, 3484($t0)
    sw $t2, 3488($t0)
    sw $t1, 3492($t0)
    sw $t1, 3496($t0)
    sw $t1, 3500($t0)
    sw $t1, 3504($t0)
    sw $t2, 3508($t0)
    sw $t2, 3512($t0)
    sw $t1, 3516($t0)
    sw $t1, 3520($t0)
    sw $t1, 3524($t0)
    sw $t1, 3528($t0)
    sw $t1, 3636($t0)
    sw $t1, 3640($t0)
    sw $t1, 3644($t0)
    sw $t1, 3648($t0)
    sw $t1, 3652($t0)
    sw $t1, 3656($t0)
    sw $t2, 3660($t0)
    sw $t2, 3664($t0)
    sw $t2, 3668($t0)
    sw $t2, 3672($t0)
    sw $t2, 3676($t0)
    sw $t2, 3680($t0)
    sw $t1, 3684($t0)
    sw $t1, 3688($t0)
    sw $t1, 3692($t0)
    sw $t1, 3696($t0)
    sw $t2, 3700($t0)
    sw $t2, 3704($t0)
    sw $t1, 3708($t0)
    sw $t1, 3712($t0)
    sw $t1, 3716($t0)
    sw $t1, 3720($t0)
    sw $t2, 3724($t0)
    sw $t2, 3728($t0)
    sw $t1, 3732($t0)
    sw $t1, 3736($t0)
    sw $t2, 3740($t0)
    sw $t2, 3744($t0)
    sw $t1, 3748($t0)
    sw $t1, 3752($t0)
    sw $t1, 3756($t0)
    sw $t1, 3760($t0)
    sw $t2, 3764($t0)
    sw $t2, 3768($t0)
    sw $t1, 3772($t0)
    sw $t1, 3776($t0)
    sw $t1, 3780($t0)
    sw $t1, 3784($t0)
    sw $t1, 3892($t0)
    sw $t1, 3896($t0)
    sw $t1, 3900($t0)
    sw $t1, 3904($t0)
    sw $t1, 3908($t0)
    sw $t1, 3912($t0)
    sw $t2, 3916($t0)
    sw $t2, 3920($t0)
    sw $t2, 3924($t0)
    sw $t2, 3928($t0)
    sw $t2, 3932($t0)
    sw $t2, 3936($t0)
    sw $t1, 3940($t0)
    sw $t1, 3944($t0)
    sw $t1, 3948($t0)
    sw $t1, 3952($t0)
    sw $t2, 3956($t0)
    sw $t2, 3960($t0)
    sw $t1, 3964($t0)
    sw $t1, 3968($t0)
    sw $t1, 3972($t0)
    sw $t1, 3976($t0)
    sw $t2, 3980($t0)
    sw $t2, 3984($t0)
    sw $t1, 3988($t0)
    sw $t1, 3992($t0)
    sw $t2, 3996($t0)
    sw $t2, 4000($t0)
    sw $t1, 4004($t0)
    sw $t1, 4008($t0)
    sw $t1, 4012($t0)
    sw $t1, 4016($t0)
    sw $t2, 4020($t0)
    sw $t2, 4024($t0)
    sw $t1, 4028($t0)
    sw $t1, 4032($t0)
    sw $t1, 4036($t0)
    sw $t1, 4040($t0)
    sw $t1, 4148($t0)
    sw $t1, 4152($t0)
    sw $t1, 4156($t0)
    sw $t1, 4160($t0)
    sw $t1, 4164($t0)
    sw $t1, 4168($t0)
    sw $t1, 4172($t0)
    sw $t1, 4176($t0)
    sw $t2, 4180($t0)
    sw $t2, 4184($t0)
    sw $t1, 4188($t0)
    sw $t1, 4192($t0)
    sw $t1, 4196($t0)
    sw $t1, 4200($t0)
    sw $t1, 4204($t0)
    sw $t1, 4208($t0)
    sw $t2, 4212($t0)
    sw $t2, 4216($t0)
    sw $t1, 4220($t0)
    sw $t1, 4224($t0)
    sw $t1, 4228($t0)
    sw $t1, 4232($t0)
    sw $t2, 4236($t0)
    sw $t2, 4240($t0)
    sw $t1, 4244($t0)
    sw $t1, 4248($t0)
    sw $t2, 4252($t0)
    sw $t2, 4256($t0)
    sw $t1, 4260($t0)
    sw $t1, 4264($t0)
    sw $t1, 4268($t0)
    sw $t1, 4272($t0)
    sw $t2, 4276($t0)
    sw $t2, 4280($t0)
    sw $t1, 4284($t0)
    sw $t1, 4288($t0)
    sw $t1, 4292($t0)
    sw $t1, 4296($t0)
    sw $t1, 4404($t0)
    sw $t1, 4408($t0)
    sw $t1, 4412($t0)
    sw $t1, 4416($t0)
    sw $t1, 4420($t0)
    sw $t1, 4424($t0)
    sw $t1, 4428($t0)
    sw $t1, 4432($t0)
    sw $t2, 4436($t0)
    sw $t2, 4440($t0)
    sw $t1, 4444($t0)
    sw $t1, 4448($t0)
    sw $t1, 4452($t0)
    sw $t1, 4456($t0)
    sw $t1, 4460($t0)
    sw $t1, 4464($t0)
    sw $t2, 4468($t0)
    sw $t2, 4472($t0)
    sw $t1, 4476($t0)
    sw $t1, 4480($t0)
    sw $t1, 4484($t0)
    sw $t1, 4488($t0)
    sw $t2, 4492($t0)
    sw $t2, 4496($t0)
    sw $t1, 4500($t0)
    sw $t1, 4504($t0)
    sw $t2, 4508($t0)
    sw $t2, 4512($t0)
    sw $t1, 4516($t0)
    sw $t1, 4520($t0)
    sw $t1, 4524($t0)
    sw $t1, 4528($t0)
    sw $t2, 4532($t0)
    sw $t2, 4536($t0)
    sw $t1, 4540($t0)
    sw $t1, 4544($t0)
    sw $t1, 4548($t0)
    sw $t1, 4552($t0)
    sw $t1, 4660($t0)
    sw $t1, 4664($t0)
    sw $t1, 4668($t0)
    sw $t1, 4672($t0)
    sw $t1, 4676($t0)
    sw $t1, 4680($t0)
    sw $t1, 4684($t0)
    sw $t1, 4688($t0)
    sw $t2, 4692($t0)
    sw $t2, 4696($t0)
    sw $t1, 4700($t0)
    sw $t1, 4704($t0)
    sw $t1, 4708($t0)
    sw $t1, 4712($t0)
    sw $t1, 4716($t0)
    sw $t1, 4720($t0)
    sw $t1, 4724($t0)
    sw $t1, 4728($t0)
    sw $t2, 4732($t0)
    sw $t2, 4736($t0)
    sw $t2, 4740($t0)
    sw $t2, 4744($t0)
    sw $t1, 4748($t0)
    sw $t1, 4752($t0)
    sw $t1, 4756($t0)
    sw $t1, 4760($t0)
    sw $t1, 4764($t0)
    sw $t1, 4768($t0)
    sw $t2, 4772($t0)
    sw $t2, 4776($t0)
    sw $t2, 4780($t0)
    sw $t2, 4784($t0)
    sw $t1, 4788($t0)
    sw $t1, 4792($t0)
    sw $t1, 4796($t0)
    sw $t1, 4800($t0)
    sw $t1, 4804($t0)
    sw $t1, 4808($t0)
    sw $t1, 4916($t0)
    sw $t1, 4920($t0)
    sw $t1, 4924($t0)
    sw $t1, 4928($t0)
    sw $t1, 4932($t0)
    sw $t1, 4936($t0)
    sw $t1, 4940($t0)
    sw $t1, 4944($t0)
    sw $t2, 4948($t0)
    sw $t2, 4952($t0)
    sw $t1, 4956($t0)
    sw $t1, 4960($t0)
    sw $t1, 4964($t0)
    sw $t1, 4968($t0)
    sw $t1, 4972($t0)
    sw $t1, 4976($t0)
    sw $t1, 4980($t0)
    sw $t1, 4984($t0)
    sw $t2, 4988($t0)
    sw $t2, 4992($t0)
    sw $t2, 4996($t0)
    sw $t2, 5000($t0)
    sw $t1, 5004($t0)
    sw $t1, 5008($t0)
    sw $t1, 5012($t0)
    sw $t1, 5016($t0)
    sw $t1, 5020($t0)
    sw $t1, 5024($t0)
    sw $t2, 5028($t0)
    sw $t2, 5032($t0)
    sw $t2, 5036($t0)
    sw $t2, 5040($t0)
    sw $t1, 5044($t0)
    sw $t1, 5048($t0)
    sw $t1, 5052($t0)
    sw $t1, 5056($t0)
    sw $t1, 5060($t0)
    sw $t1, 5064($t0)
    sw $t1, 5172($t0)
    sw $t1, 5176($t0)
    sw $t1, 5180($t0)
    sw $t1, 5184($t0)
    sw $t1, 5188($t0)
    sw $t1, 5192($t0)
    sw $t1, 5196($t0)
    sw $t1, 5200($t0)
    sw $t1, 5204($t0)
    sw $t1, 5208($t0)
    sw $t1, 5212($t0)
    sw $t1, 5216($t0)
    sw $t1, 5220($t0)
    sw $t1, 5224($t0)
    sw $t1, 5228($t0)
    sw $t1, 5232($t0)
    sw $t1, 5236($t0)
    sw $t1, 5240($t0)
    sw $t1, 5244($t0)
    sw $t1, 5248($t0)
    sw $t1, 5252($t0)
    sw $t1, 5256($t0)
    sw $t1, 5260($t0)
    sw $t1, 5264($t0)
    sw $t1, 5268($t0)
    sw $t1, 5272($t0)
    sw $t1, 5276($t0)
    sw $t1, 5280($t0)
    sw $t1, 5284($t0)
    sw $t1, 5288($t0)
    sw $t1, 5292($t0)
    sw $t1, 5296($t0)
    sw $t1, 5300($t0)
    sw $t1, 5304($t0)
    sw $t1, 5308($t0)
    sw $t1, 5312($t0)
    sw $t1, 5316($t0)
    sw $t1, 5320($t0)
    sw $t1, 5428($t0)
    sw $t1, 5432($t0)
    sw $t1, 5436($t0)
    sw $t1, 5440($t0)
    sw $t1, 5444($t0)
    sw $t1, 5448($t0)
    sw $t1, 5452($t0)
    sw $t1, 5456($t0)
    sw $t1, 5460($t0)
    sw $t1, 5464($t0)
    sw $t1, 5468($t0)
    sw $t1, 5472($t0)
    sw $t1, 5476($t0)
    sw $t1, 5480($t0)
    sw $t1, 5484($t0)
    sw $t1, 5488($t0)
    sw $t1, 5492($t0)
    sw $t1, 5496($t0)
    sw $t1, 5500($t0)
    sw $t1, 5504($t0)
    sw $t1, 5508($t0)
    sw $t1, 5512($t0)
    sw $t1, 5516($t0)
    sw $t1, 5520($t0)
    sw $t1, 5524($t0)
    sw $t1, 5528($t0)
    sw $t1, 5532($t0)
    sw $t1, 5536($t0)
    sw $t1, 5540($t0)
    sw $t1, 5544($t0)
    sw $t1, 5548($t0)
    sw $t1, 5552($t0)
    sw $t1, 5556($t0)
    sw $t1, 5560($t0)
    sw $t1, 5564($t0)
    sw $t1, 5568($t0)
    sw $t1, 5572($t0)
    sw $t1, 5576($t0)
    sw $t1, 5684($t0)
    sw $t1, 5688($t0)
    sw $t1, 5692($t0)
    sw $t1, 5696($t0)
    sw $t1, 5700($t0)
    sw $t1, 5704($t0)
    sw $t1, 5708($t0)
    sw $t1, 5712($t0)
    sw $t1, 5716($t0)
    sw $t1, 5720($t0)
    sw $t1, 5724($t0)
    sw $t1, 5728($t0)
    sw $t1, 5732($t0)
    sw $t1, 5736($t0)
    sw $t1, 5740($t0)
    sw $t1, 5744($t0)
    sw $t1, 5748($t0)
    sw $t1, 5752($t0)
    sw $t1, 5756($t0)
    sw $t1, 5760($t0)
    sw $t1, 5764($t0)
    sw $t1, 5768($t0)
    sw $t1, 5772($t0)
    sw $t1, 5776($t0)
    sw $t1, 5780($t0)
    sw $t1, 5784($t0)
    sw $t1, 5788($t0)
    sw $t1, 5792($t0)
    sw $t1, 5796($t0)
    sw $t1, 5800($t0)
    sw $t1, 5804($t0)
    sw $t1, 5808($t0)
    sw $t1, 5812($t0)
    sw $t1, 5816($t0)
    sw $t1, 5820($t0)
    sw $t1, 5824($t0)
    sw $t1, 5828($t0)
    sw $t1, 5832($t0)
    sw $t1, 5940($t0)
    sw $t2, 5944($t0)
    sw $t2, 5948($t0)
    sw $t1, 5952($t0)
    sw $t1, 5956($t0)
    sw $t1, 5960($t0)
    sw $t1, 5964($t0)
    sw $t1, 5968($t0)
    sw $t1, 5972($t0)
    sw $t2, 5976($t0)
    sw $t2, 5980($t0)
    sw $t1, 5984($t0)
    sw $t1, 5988($t0)
    sw $t1, 5992($t0)
    sw $t1, 5996($t0)
    sw $t2, 6000($t0)
    sw $t2, 6004($t0)
    sw $t2, 6008($t0)
    sw $t2, 6012($t0)
    sw $t1, 6016($t0)
    sw $t1, 6020($t0)
    sw $t1, 6024($t0)
    sw $t1, 6028($t0)
    sw $t2, 6032($t0)
    sw $t2, 6036($t0)
    sw $t1, 6040($t0)
    sw $t1, 6044($t0)
    sw $t1, 6048($t0)
    sw $t1, 6052($t0)
    sw $t2, 6056($t0)
    sw $t2, 6060($t0)
    sw $t1, 6064($t0)
    sw $t1, 6068($t0)
    sw $t1, 6072($t0)
    sw $t1, 6076($t0)
    sw $t2, 6080($t0)
    sw $t2, 6084($t0)
    sw $t1, 6088($t0)
    sw $t1, 6196($t0)
    sw $t2, 6200($t0)
    sw $t2, 6204($t0)
    sw $t1, 6208($t0)
    sw $t1, 6212($t0)
    sw $t1, 6216($t0)
    sw $t1, 6220($t0)
    sw $t1, 6224($t0)
    sw $t1, 6228($t0)
    sw $t2, 6232($t0)
    sw $t2, 6236($t0)
    sw $t1, 6240($t0)
    sw $t1, 6244($t0)
    sw $t1, 6248($t0)
    sw $t1, 6252($t0)
    sw $t2, 6256($t0)
    sw $t2, 6260($t0)
    sw $t2, 6264($t0)
    sw $t2, 6268($t0)
    sw $t1, 6272($t0)
    sw $t1, 6276($t0)
    sw $t1, 6280($t0)
    sw $t1, 6284($t0)
    sw $t2, 6288($t0)
    sw $t2, 6292($t0)
    sw $t1, 6296($t0)
    sw $t1, 6300($t0)
    sw $t1, 6304($t0)
    sw $t1, 6308($t0)
    sw $t2, 6312($t0)
    sw $t2, 6316($t0)
    sw $t1, 6320($t0)
    sw $t1, 6324($t0)
    sw $t1, 6328($t0)
    sw $t1, 6332($t0)
    sw $t2, 6336($t0)
    sw $t2, 6340($t0)
    sw $t1, 6344($t0)
    sw $t1, 6452($t0)
    sw $t2, 6456($t0)
    sw $t2, 6460($t0)
    sw $t1, 6464($t0)
    sw $t1, 6468($t0)
    sw $t1, 6472($t0)
    sw $t1, 6476($t0)
    sw $t1, 6480($t0)
    sw $t1, 6484($t0)
    sw $t2, 6488($t0)
    sw $t2, 6492($t0)
    sw $t1, 6496($t0)
    sw $t1, 6500($t0)
    sw $t2, 6504($t0)
    sw $t2, 6508($t0)
    sw $t1, 6512($t0)
    sw $t1, 6516($t0)
    sw $t1, 6520($t0)
    sw $t1, 6524($t0)
    sw $t2, 6528($t0)
    sw $t2, 6532($t0)
    sw $t1, 6536($t0)
    sw $t1, 6540($t0)
    sw $t2, 6544($t0)
    sw $t2, 6548($t0)
    sw $t2, 6552($t0)
    sw $t2, 6556($t0)
    sw $t1, 6560($t0)
    sw $t1, 6564($t0)
    sw $t2, 6568($t0)
    sw $t2, 6572($t0)
    sw $t1, 6576($t0)
    sw $t1, 6580($t0)
    sw $t1, 6584($t0)
    sw $t1, 6588($t0)
    sw $t2, 6592($t0)
    sw $t2, 6596($t0)
    sw $t1, 6600($t0)
    sw $t1, 6708($t0)
    sw $t2, 6712($t0)
    sw $t2, 6716($t0)
    sw $t1, 6720($t0)
    sw $t1, 6724($t0)
    sw $t1, 6728($t0)
    sw $t1, 6732($t0)
    sw $t1, 6736($t0)
    sw $t1, 6740($t0)
    sw $t2, 6744($t0)
    sw $t2, 6748($t0)
    sw $t1, 6752($t0)
    sw $t1, 6756($t0)
    sw $t2, 6760($t0)
    sw $t2, 6764($t0)
    sw $t1, 6768($t0)
    sw $t1, 6772($t0)
    sw $t1, 6776($t0)
    sw $t1, 6780($t0)
    sw $t2, 6784($t0)
    sw $t2, 6788($t0)
    sw $t1, 6792($t0)
    sw $t1, 6796($t0)
    sw $t2, 6800($t0)
    sw $t2, 6804($t0)
    sw $t2, 6808($t0)
    sw $t2, 6812($t0)
    sw $t1, 6816($t0)
    sw $t1, 6820($t0)
    sw $t2, 6824($t0)
    sw $t2, 6828($t0)
    sw $t1, 6832($t0)
    sw $t1, 6836($t0)
    sw $t1, 6840($t0)
    sw $t1, 6844($t0)
    sw $t2, 6848($t0)
    sw $t2, 6852($t0)
    sw $t1, 6856($t0)
    sw $t1, 6964($t0)
    sw $t2, 6968($t0)
    sw $t2, 6972($t0)
    sw $t1, 6976($t0)
    sw $t1, 6980($t0)
    sw $t2, 6984($t0)
    sw $t2, 6988($t0)
    sw $t1, 6992($t0)
    sw $t1, 6996($t0)
    sw $t2, 7000($t0)
    sw $t2, 7004($t0)
    sw $t1, 7008($t0)
    sw $t1, 7012($t0)
    sw $t2, 7016($t0)
    sw $t2, 7020($t0)
    sw $t1, 7024($t0)
    sw $t1, 7028($t0)
    sw $t1, 7032($t0)
    sw $t1, 7036($t0)
    sw $t2, 7040($t0)
    sw $t2, 7044($t0)
    sw $t1, 7048($t0)
    sw $t1, 7052($t0)
    sw $t2, 7056($t0)
    sw $t2, 7060($t0)
    sw $t1, 7064($t0)
    sw $t1, 7068($t0)
    sw $t2, 7072($t0)
    sw $t2, 7076($t0)
    sw $t2, 7080($t0)
    sw $t2, 7084($t0)
    sw $t1, 7088($t0)
    sw $t1, 7092($t0)
    sw $t1, 7096($t0)
    sw $t1, 7100($t0)
    sw $t2, 7104($t0)
    sw $t2, 7108($t0)
    sw $t1, 7112($t0)
    sw $t1, 7220($t0)
    sw $t2, 7224($t0)
    sw $t2, 7228($t0)
    sw $t1, 7232($t0)
    sw $t1, 7236($t0)
    sw $t2, 7240($t0)
    sw $t2, 7244($t0)
    sw $t1, 7248($t0)
    sw $t1, 7252($t0)
    sw $t2, 7256($t0)
    sw $t2, 7260($t0)
    sw $t1, 7264($t0)
    sw $t1, 7268($t0)
    sw $t2, 7272($t0)
    sw $t2, 7276($t0)
    sw $t1, 7280($t0)
    sw $t1, 7284($t0)
    sw $t1, 7288($t0)
    sw $t1, 7292($t0)
    sw $t2, 7296($t0)
    sw $t2, 7300($t0)
    sw $t1, 7304($t0)
    sw $t1, 7308($t0)
    sw $t2, 7312($t0)
    sw $t2, 7316($t0)
    sw $t1, 7320($t0)
    sw $t1, 7324($t0)
    sw $t2, 7328($t0)
    sw $t2, 7332($t0)
    sw $t2, 7336($t0)
    sw $t2, 7340($t0)
    sw $t1, 7344($t0)
    sw $t1, 7348($t0)
    sw $t1, 7352($t0)
    sw $t1, 7356($t0)
    sw $t2, 7360($t0)
    sw $t2, 7364($t0)
    sw $t1, 7368($t0)
    sw $t1, 7476($t0)
    sw $t2, 7480($t0)
    sw $t2, 7484($t0)
    sw $t2, 7488($t0)
    sw $t2, 7492($t0)
    sw $t1, 7496($t0)
    sw $t1, 7500($t0)
    sw $t2, 7504($t0)
    sw $t2, 7508($t0)
    sw $t2, 7512($t0)
    sw $t2, 7516($t0)
    sw $t1, 7520($t0)
    sw $t1, 7524($t0)
    sw $t2, 7528($t0)
    sw $t2, 7532($t0)
    sw $t1, 7536($t0)
    sw $t1, 7540($t0)
    sw $t1, 7544($t0)
    sw $t1, 7548($t0)
    sw $t2, 7552($t0)
    sw $t2, 7556($t0)
    sw $t1, 7560($t0)
    sw $t1, 7564($t0)
    sw $t2, 7568($t0)
    sw $t2, 7572($t0)
    sw $t1, 7576($t0)
    sw $t1, 7580($t0)
    sw $t1, 7584($t0)
    sw $t1, 7588($t0)
    sw $t2, 7592($t0)
    sw $t2, 7596($t0)
    sw $t1, 7600($t0)
    sw $t1, 7604($t0)
    sw $t1, 7608($t0)
    sw $t1, 7612($t0)
    sw $t1, 7616($t0)
    sw $t1, 7620($t0)
    sw $t1, 7624($t0)
    sw $t1, 7732($t0)
    sw $t2, 7736($t0)
    sw $t2, 7740($t0)
    sw $t2, 7744($t0)
    sw $t2, 7748($t0)
    sw $t1, 7752($t0)
    sw $t1, 7756($t0)
    sw $t2, 7760($t0)
    sw $t2, 7764($t0)
    sw $t2, 7768($t0)
    sw $t2, 7772($t0)
    sw $t1, 7776($t0)
    sw $t1, 7780($t0)
    sw $t2, 7784($t0)
    sw $t2, 7788($t0)
    sw $t1, 7792($t0)
    sw $t1, 7796($t0)
    sw $t1, 7800($t0)
    sw $t1, 7804($t0)
    sw $t2, 7808($t0)
    sw $t2, 7812($t0)
    sw $t1, 7816($t0)
    sw $t1, 7820($t0)
    sw $t2, 7824($t0)
    sw $t2, 7828($t0)
    sw $t1, 7832($t0)
    sw $t1, 7836($t0)
    sw $t1, 7840($t0)
    sw $t1, 7844($t0)
    sw $t2, 7848($t0)
    sw $t2, 7852($t0)
    sw $t1, 7856($t0)
    sw $t1, 7860($t0)
    sw $t1, 7864($t0)
    sw $t1, 7868($t0)
    sw $t1, 7872($t0)
    sw $t1, 7876($t0)
    sw $t1, 7880($t0)
    sw $t1, 7988($t0)
    sw $t2, 7992($t0)
    sw $t2, 7996($t0)
    sw $t1, 8000($t0)
    sw $t1, 8004($t0)
    sw $t1, 8008($t0)
    sw $t1, 8012($t0)
    sw $t1, 8016($t0)
    sw $t1, 8020($t0)
    sw $t2, 8024($t0)
    sw $t2, 8028($t0)
    sw $t1, 8032($t0)
    sw $t1, 8036($t0)
    sw $t1, 8040($t0)
    sw $t1, 8044($t0)
    sw $t2, 8048($t0)
    sw $t2, 8052($t0)
    sw $t2, 8056($t0)
    sw $t2, 8060($t0)
    sw $t1, 8064($t0)
    sw $t1, 8068($t0)
    sw $t1, 8072($t0)
    sw $t1, 8076($t0)
    sw $t2, 8080($t0)
    sw $t2, 8084($t0)
    sw $t1, 8088($t0)
    sw $t1, 8092($t0)
    sw $t1, 8096($t0)
    sw $t1, 8100($t0)
    sw $t2, 8104($t0)
    sw $t2, 8108($t0)
    sw $t1, 8112($t0)
    sw $t1, 8116($t0)
    sw $t1, 8120($t0)
    sw $t1, 8124($t0)
    sw $t2, 8128($t0)
    sw $t2, 8132($t0)
    sw $t1, 8136($t0)
    sw $t1, 8244($t0)
    sw $t2, 8248($t0)
    sw $t2, 8252($t0)
    sw $t1, 8256($t0)
    sw $t1, 8260($t0)
    sw $t1, 8264($t0)
    sw $t1, 8268($t0)
    sw $t1, 8272($t0)
    sw $t1, 8276($t0)
    sw $t2, 8280($t0)
    sw $t2, 8284($t0)
    sw $t1, 8288($t0)
    sw $t1, 8292($t0)
    sw $t1, 8296($t0)
    sw $t1, 8300($t0)
    sw $t2, 8304($t0)
    sw $t2, 8308($t0)
    sw $t2, 8312($t0)
    sw $t2, 8316($t0)
    sw $t1, 8320($t0)
    sw $t1, 8324($t0)
    sw $t1, 8328($t0)
    sw $t1, 8332($t0)
    sw $t2, 8336($t0)
    sw $t2, 8340($t0)
    sw $t1, 8344($t0)
    sw $t1, 8348($t0)
    sw $t1, 8352($t0)
    sw $t1, 8356($t0)
    sw $t2, 8360($t0)
    sw $t2, 8364($t0)
    sw $t1, 8368($t0)
    sw $t1, 8372($t0)
    sw $t1, 8376($t0)
    sw $t1, 8380($t0)
    sw $t2, 8384($t0)
    sw $t2, 8388($t0)
    sw $t1, 8392($t0)
    sw $t1, 8500($t0)
    sw $t1, 8504($t0)
    sw $t1, 8508($t0)
    sw $t1, 8512($t0)
    sw $t1, 8516($t0)
    sw $t1, 8520($t0)
    sw $t1, 8524($t0)
    sw $t1, 8528($t0)
    sw $t1, 8532($t0)
    sw $t1, 8536($t0)
    sw $t1, 8540($t0)
    sw $t1, 8544($t0)
    sw $t1, 8548($t0)
    sw $t1, 8552($t0)
    sw $t1, 8556($t0)
    sw $t1, 8560($t0)
    sw $t1, 8564($t0)
    sw $t1, 8568($t0)
    sw $t1, 8572($t0)
    sw $t1, 8576($t0)
    sw $t1, 8580($t0)
    sw $t1, 8584($t0)
    sw $t1, 8588($t0)
    sw $t1, 8592($t0)
    sw $t1, 8596($t0)
    sw $t1, 8600($t0)
    sw $t1, 8604($t0)
    sw $t1, 8608($t0)
    sw $t1, 8612($t0)
    sw $t1, 8616($t0)
    sw $t1, 8620($t0)
    sw $t1, 8624($t0)
    sw $t1, 8628($t0)
    sw $t1, 8632($t0)
    sw $t1, 8636($t0)
    sw $t1, 8640($t0)
    sw $t1, 8644($t0)
    sw $t1, 8648($t0)
    sw $t2, 9492($t0)
    sw $t2, 9496($t0)
    sw $t2, 9516($t0)
    sw $t2, 9520($t0)
    sw $t2, 9524($t0)
    sw $t2, 9528($t0)
    sw $t2, 9532($t0)
    sw $t2, 9544($t0)
    sw $t2, 9548($t0)
    sw $t2, 9572($t0)
    sw $t2, 9576($t0)
    sw $t2, 9588($t0)
    sw $t2, 9600($t0)
    sw $t2, 9608($t0)
    sw $t2, 9612($t0)
    sw $t2, 9616($t0)
    sw $t2, 9624($t0)
    sw $t2, 9628($t0)
    sw $t2, 9632($t0)
    sw $t2, 9636($t0)
    sw $t2, 9640($t0)
    sw $t2, 9744($t0)
    sw $t2, 9756($t0)
    sw $t2, 9780($t0)
    sw $t2, 9796($t0)
    sw $t2, 9808($t0)
    sw $t2, 9824($t0)
    sw $t2, 9836($t0)
    sw $t2, 9844($t0)
    sw $t2, 9856($t0)
    sw $t2, 9868($t0)
    sw $t2, 9888($t0)
    sw $t2, 10000($t0)
    sw $t2, 10012($t0)
    sw $t2, 10036($t0)
    sw $t2, 10052($t0)
    sw $t2, 10064($t0)
    sw $t2, 10080($t0)
    sw $t2, 10092($t0)
    sw $t2, 10100($t0)
    sw $t2, 10112($t0)
    sw $t2, 10124($t0)
    sw $t2, 10144($t0)
    sw $t2, 10256($t0)
    sw $t2, 10264($t0)
    sw $t2, 10292($t0)
    sw $t2, 10308($t0)
    sw $t2, 10320($t0)
    sw $t2, 10336($t0)
    sw $t2, 10344($t0)
    sw $t2, 10356($t0)
    sw $t2, 10368($t0)
    sw $t2, 10380($t0)
    sw $t2, 10400($t0)
    sw $t2, 10516($t0)
    sw $t2, 10524($t0)
    sw $t2, 10548($t0)
    sw $t2, 10568($t0)
    sw $t2, 10572($t0)
    sw $t2, 10596($t0)
    sw $t2, 10604($t0)
    sw $t2, 10616($t0)
    sw $t2, 10620($t0)
    sw $t2, 10632($t0)
    sw $t2, 10636($t0)
    sw $t2, 10640($t0)
    sw $t2, 10656($t0)
    sw $t2, 11024($t0)
    sw $t2, 11028($t0)
    sw $t2, 11032($t0)
    sw $t2, 11052($t0)
    sw $t2, 11056($t0)
    sw $t2, 11060($t0)
    sw $t2, 11064($t0)
    sw $t2, 11068($t0)
    sw $t2, 11080($t0)
    sw $t2, 11084($t0)
    sw $t2, 11104($t0)
    sw $t2, 11108($t0)
    sw $t2, 11112($t0)
    sw $t2, 11124($t0)
    sw $t2, 11128($t0)
    sw $t2, 11132($t0)
    sw $t2, 11136($t0)
    sw $t2, 11148($t0)
    sw $t2, 11152($t0)
    sw $t2, 11156($t0)
    sw $t2, 11164($t0)
    sw $t2, 11168($t0)
    sw $t2, 11172($t0)
    sw $t2, 11176($t0)
    sw $t2, 11180($t0)
    sw $t2, 11192($t0)
    sw $t2, 11196($t0)
    sw $t2, 11208($t0)
    sw $t2, 11212($t0)
    sw $t2, 11216($t0)
    sw $t2, 11228($t0)
    sw $t2, 11232($t0)
    sw $t2, 11236($t0)
    sw $t2, 11240($t0)
    sw $t2, 11244($t0)
    sw $t2, 11280($t0)
    sw $t2, 11292($t0)
    sw $t2, 11316($t0)
    sw $t2, 11332($t0)
    sw $t2, 11344($t0)
    sw $t2, 11360($t0)
    sw $t2, 11372($t0)
    sw $t2, 11380($t0)
    sw $t2, 11400($t0)
    sw $t2, 11428($t0)
    sw $t2, 11444($t0)
    sw $t2, 11456($t0)
    sw $t2, 11464($t0)
    sw $t2, 11476($t0)
    sw $t2, 11492($t0)
    sw $t2, 11536($t0)
    sw $t2, 11540($t0)
    sw $t2, 11544($t0)
    sw $t2, 11572($t0)
    sw $t2, 11588($t0)
    sw $t2, 11600($t0)
    sw $t2, 11616($t0)
    sw $t2, 11620($t0)
    sw $t2, 11624($t0)
    sw $t2, 11636($t0)
    sw $t2, 11640($t0)
    sw $t2, 11644($t0)
    sw $t2, 11660($t0)
    sw $t2, 11664($t0)
    sw $t2, 11684($t0)
    sw $t2, 11700($t0)
    sw $t2, 11704($t0)
    sw $t2, 11708($t0)
    sw $t2, 11712($t0)
    sw $t2, 11720($t0)
    sw $t2, 11724($t0)
    sw $t2, 11728($t0)
    sw $t2, 11748($t0)
    sw $t2, 11792($t0)
    sw $t2, 11800($t0)
    sw $t2, 11828($t0)
    sw $t2, 11844($t0)
    sw $t2, 11856($t0)
    sw $t2, 11872($t0)
    sw $t2, 11880($t0)
    sw $t2, 11892($t0)
    sw $t2, 11924($t0)
    sw $t2, 11940($t0)
    sw $t2, 11956($t0)
    sw $t2, 11968($t0)
    sw $t2, 11976($t0)
    sw $t2, 11984($t0)
    sw $t2, 12004($t0)
    sw $t2, 12048($t0)
    sw $t2, 12060($t0)
    sw $t2, 12084($t0)
    sw $t2, 12104($t0)
    sw $t2, 12108($t0)
    sw $t2, 12128($t0)
    sw $t2, 12140($t0)
    sw $t2, 12148($t0)
    sw $t2, 12152($t0)
    sw $t2, 12156($t0)
    sw $t2, 12160($t0)
    sw $t2, 12168($t0)
    sw $t2, 12172($t0)
    sw $t2, 12176($t0)
    sw $t2, 12196($t0)
    sw $t2, 12212($t0)
    sw $t2, 12224($t0)
    sw $t2, 12232($t0)
    sw $t2, 12244($t0)
    sw $t2, 12260($t0)

    jr $ra
