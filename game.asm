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

.eqv DISPLAY_BASE_ADDRESS 0x10008000    # $gp
.eqv DISPLAY_END_ADDRESS 0x1000bffc     # Bottom-right unit's address
.eqv KEYSTROKE_ADDRESS 0xffff0000

# Dimensions in number of units (not pixels)
# Note: on my screen, each unit is 5 pixels in the MIPS Bitmap Display as the display is 320x320 instead of 256x256
# (measured using a screen ruler)
.eqv DISPLAY_WIDTH 64
.eqv DISPLAY_HEIGHT 64

.eqv PLAYER_WIDTH 3
.eqv PLAYER_HEIGHT 3
# Player's initial top-left unit position
.eqv PLAYER_INITIAL_X 2
.eqv PLAYER_INITIAL_Y 29

.eqv PLATFORM_WIDTH 12
.eqv PLATFORM_THICKNESS 1
# Platform spawn position ranges for the top-left unit
.eqv PLATFORM_MIN_X 0
.eqv PLATFORM_MAX_X 52
# TODO: adjust y-range so it is never impossible to jump onto one (height-wise)
.eqv PLATFORM_MIN_Y 0
.eqv PLATFORM_MAX_Y 63

.eqv ENEMY_WIDTH 2
.eqv ENEMY_HEIGHT 2
# Enemy spawn position ranges for the top-left unit
.eqv ENEMY_MIN_X 40
.eqv ENEMY_MAX_X 61
# TODO: adjust these so enemies aren't redundant because they're out of reach vertically
.eqv ENEMY_MIN_Y 0
.eqv ENEMY_MAX_Y 61

# Colours
.eqv COLOUR_BACKGROUND 0x000000     # black
.eqv COLOUR_PLATFORM 0x964B00       # brown
.eqv COLOUR_PLAYER 0x0000FF         # blue
.eqv COLOUR_ENEMY 0xFF0000          # red

.eqv NUM_PLATFORMS 5
.eqv NUM_ENEMIES 3

.data

player_x: .word PLAYER_INITIAL_X
player_y: .word PLAYER_INITIAL_Y

# Coordinates of each platform's top-left unit
platforms_x: .word 0:NUM_PLATFORMS
platforms_y: .word 0:NUM_PLATFORMS

# Coordinates of each enemy's top-left unit
enemies_x: .word 0:NUM_ENEMIES
enemies_y: .word 0:NUM_ENEMIES

.text

.globl main

j main


#################### UTILITIES ####################

# Loads the data from the given word into the given register
# Parameters:
    # %word_addr: the address of the word to load
    # %dest_reg: the register to load the word into
# Returns:
    # %dest_reg: the word
# Uses:
    # %dest_reg
.macro load_word(%word_addr, %dest_reg)
    la %dest_reg, %word_addr
    lw %dest_reg, 0(%dest_reg)
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
    # $a0: random_integer
    # $a1: random_integer
    # $v0: random_integer
.macro initialize_entities(%entities_x, %entities_y, %num_entities, %min_x, %max_x, %min_y, %max_y)
    la $t0, %entities_x
    la $t1, %entities_y
    add $t2, $zero, $zero   # $t2 = array offset = sizeof(word) * i (for the index i)
    li $t3, %num_entities
    sll $t3, $t3, 2         # $t3 = %num_entities * sizeof(word)

_initialize_entities_loop:                  # $t2 = array offset
    bge $t2, $t3, _initialize_entities_end  # while i < %num_entities
    add $t4, $t0, $t2
    add $t5, $t1, $t2

    # Randomly generate coordinates in the valid range and store them
    random_integer(%min_x, %max_x)
    move $t6, $v0
    random_integer(%min_y, %max_y)
    move $t7, $v0
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

    lw $t6, 0($t8)  # $t8 = entities_x[i]
    lw $t7, 0($t9)  # $t9 = entities_y[i]

    draw_entity($t6, $t7, %entity_width, %entity_height, %entity_colour)

    addi $t4, $t4, 4
    addi $t8, $t8, 4
    addi $t9, $t9, 4
    j _draw_entities_loop

_draw_entities_end:
.end_macro

# Randomly generates x and y-values for all platforms except the first, storing them in platform_x and platform_y
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
.macro initialize_platforms()
    initialize_entities(platforms_x, platforms_y, NUM_PLATFORMS, PLATFORM_MIN_X, PLATFORM_MAX_X, PLATFORM_MIN_Y, PLATFORM_MAX_Y)

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


#################### GAME ####################

.macro handle_keypress()
    li $t0, KEYSTROKE_ADDRESS
    lw $t1, 0($t0)
    bne $t1, 1, _handle_keypress_end

    lw $t1, 4($t0)  # ASCII value of key pressed

_handle_keypress_end:
.end_macro

main:
    fill_background(COLOUR_BACKGROUND)
    initialize_enemies()
    draw_enemies()
    # TODO: handle enemy collision with platform (e.g. draw platform on top of enemy)

    initialize_platforms()
    draw_platforms()

    load_word(player_x, $a0)
    load_word(player_y, $a1)

    draw_entity($a0, $a1, PLAYER_WIDTH, PLAYER_HEIGHT, COLOUR_PLAYER)

    # Exit
    li $v0, 10
    syscall
