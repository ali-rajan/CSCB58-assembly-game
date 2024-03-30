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

# Dimensions in number of units (not pixels)
# Note: on my screen, each unit is 5 pixels in the MIPS Bitmap Display as the display is 320x320 instead of 256x256
# (measured using a screen ruler)
.eqv DISPLAY_WIDTH 64
.eqv DISPLAY_HEIGHT 64
.eqv DISPLAY_RIGHT 63   # DISPLAY_WIDTH - 1
.eqv DISPLAY_BOTTOM 63  # DISPLAY_HEIGHT - 1

.eqv PLAYER_WIDTH 3
.eqv PLAYER_HEIGHT 3
.eqv PLAYER_INITIAL_X 2
.eqv PLAYER_INITIAL_Y 29

.eqv PLATFORM_WIDTH 12
.eqv PLATFORM_THICKNESS 1
# Bounds on the x and y-values for platforms to be randomly generated with
.eqv PLATFORM_MIN_X 0
.eqv PLATFORM_MAX_X 52
.eqv PLATFORM_MIN_Y 0
.eqv PLATFORM_MAX_Y 63

# Colours
.eqv COLOUR_BACKGROUND 0x000000     # Black
.eqv COLOUR_PLATFORM 0x964B00       # Brown
.eqv COLOUR_PLAYER 0xFF0000         # Red

.eqv NUM_PLATFORMS 5

.data

player_x: .word PLAYER_INITIAL_X
player_y: .word PLAYER_INITIAL_Y

# Coordinates of the platforms
platforms_x: .word 0:NUM_PLATFORMS
platforms_y: .word 0:NUM_PLATFORMS

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
.macro unit_address(%x, %y)
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
    # %x_reg
    # %y_reg
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


#################### DRAWING ####################

# Colours the given unit with the given colour.
# Parameters:
    # %addr_reg: register storing the address of the unit to colour
    # %colour: colour (immediate value)
# Uses:
#   %addr_reg
#   $t0
.macro colour_unit(%addr_reg, %colour)
    li $t0, %colour
    sw $t0, 0(%addr_reg)
.end_macro

# Fills the screen with the given colour.
# Parameters:
    # %colour: colour (immediate value)
# Uses:
    # $t0: colour_unit calls
    # $s0: colour_unit calls and macro
    # $s1
.macro fill_background(%colour)
    li $s0, DISPLAY_BASE_ADDRESS
    li $s1, DISPLAY_END_ADDRESS

_fill_background_loop:
    bgt $s0, $s1, _fill_background_loop_end     # while the last unit is not reached
    colour_unit($s0, %colour)
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
    # %x_reg: unit_address_reg calls
    # %y_reg: unit_address_reg calls
    # $t0: colour_unit calls
    # $t2: unit_address_reg calls
    # $t3: unit_address_reg calls
    # $v0: unit_address_reg calls
    # $s0
    # $s1
    # $s2
    # $s3
    # $s4
    # $s5
    # $s6
.macro draw_entity(%x_reg, %y_reg, %width, %height, %colour)
    unit_address_reg(%x_reg, %y_reg)
    move $s0, $v0   # $s0 = unit_address(start_x, start_y)

    add $s1, %x_reg, %width     # $s1 = end_x (inclusive)
    add $s2, %y_reg, %height
    addi $s2, $s2, -1           # $s2 = end_y (inclusive)
    unit_address_reg($s1, $s2)
    move $s3, $v0   # $s3 = unit_address(end_x, end_y)

    add $s4, %x_reg, %width     # $s4 = row_end_x
    move $s5, %y_reg            # $s5 = row_end_y
    unit_address_reg($s4, $s5)
    move $s6, $v0   # $s6 = addr(row end unit)

_draw_entity_loop:
    # $s0 stores addr(current unit)
    # %x_reg and %y_reg store the current row's start posiiton
    # $s4 stores the current row's end x-value
    bge		$s0, $s3, _draw_entity_loop_end         # while the last unit is not reached

    _draw_entity_row_loop:
        bge $s0, $s6, _draw_entity_row_loop_end     # while the last unit in the row is not reached
        colour_unit($s0, %colour)
        add $s0, $s0, 4                             # next unit is sizeof(word) ahead
        j _draw_entity_row_loop

    _draw_entity_row_loop_end:
        # Move to the next row
        addi %y_reg, %y_reg, 1
        unit_address_reg(%x_reg, %y_reg)
        move $s0, $v0
        # Update the row end position
        unit_address_reg($s4, %y_reg)
        move $s6, $v0

    j _draw_entity_loop

_draw_entity_loop_end:
.end_macro


#################### SPRITES ####################

# Randomly generates x and y-values for all platforms, storing them in platform_x and platform_y (respectively).
# Uses:
    # $t0
    # $t1
    # $t2
    # $t3
    # $t4
    # $t5
    # $t6
    # $t7
    # $v0: random_integer call
    # $a0: random_integer call
    # $a1: random_integer call
.macro initialize_platforms()
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
    # Place the first platform right below the player's initial position
    sw $t6, 0($t4)
    sw $t7, 0($t5)
    addi $t2, $t2, 4

_initialize_platforms_loop:                             # $t2 = array offset
    bge $t2, $t3, _initialize_platforms_loop_end        # while i < NUM_PLATFORMS
    add $t4, $t0, $t2
    add $t5, $t1, $t2

    # Randomly generate coordinates in the valid range and store them
    random_integer(PLATFORM_MIN_X, PLATFORM_MAX_X)
    move $t6, $v0
    random_integer(PLATFORM_MIN_Y, PLATFORM_MAX_Y)
    move $t7, $v0
    sw $t6, 0($t4)                                  # platforms_x[i] = random x-value
    sw $t7, 0($t5)                                  # platforms_y[i] = random y-value

    addi $t2, $t2, 4
    j _initialize_platforms_loop

_initialize_platforms_loop_end:
.end_macro

# TODO: save $s0 - $s6 in stack if this is called elsewhere that uses those registers
# Draws all the platforms based on their coordinates stored in platforms_x and platforms_y.
# Uses:
    # $t0: draw_entity > colour_unit calls
    # $t2: draw_entity > unit_address_reg calls
    # $t3: draw_entity > unit_address_reg calls
    # $t4
    # $t5
    # $t6
    # $t7
    # $t8
    # $t9
    # $v0: draw_entity > unit_address_reg calls
    # $s0: draw_entity calls
    # $s1: draw_entity calls
    # $s2: draw_entity calls
    # $s3: draw_entity calls
    # $s4: draw_entity calls
    # $s5: draw_entity calls
    # $s6: draw_entity calls
.macro draw_platforms()
    la $t8, platforms_x
    la $t9, platforms_y
    add $t4, $zero, $zero   # $t4 = array offset = sizeof(word) * i (for the index i)
    li $t5, NUM_PLATFORMS
    sll $t5, $t5, 2         # $t5 = NUM_PLATFORMS * sizeof(word)

_draw_platforms_loop:
    bge $t4, $t5, _draw_platforms_loop_end        # while i < NUM_PLATFORMS

    lw $t6, 0($t8)  # $t8 = platforms_x[i]
    lw $t7, 0($t9)  # $t9 = platforms_y[i]

    draw_entity($t6, $t7, PLATFORM_WIDTH, PLATFORM_THICKNESS, COLOUR_PLATFORM)

    addi $t4, $t4, 4
    addi $t8, $t8, 4
    addi $t9, $t9, 4
    j _draw_platforms_loop

_draw_platforms_loop_end:
.end_macro


#################### GAME ####################

main:
    fill_background(COLOUR_BACKGROUND)
    initialize_platforms()
    draw_platforms()

    load_word(player_x, $a0)
    load_word(player_y, $a1)

    draw_entity($a0, $a1, PLAYER_WIDTH, PLAYER_HEIGHT, COLOUR_PLAYER)

    # TODO: make platforms randomly spawn to the right and only draw pixels on screen


    # Exit
    li $v0, 10
    syscall
