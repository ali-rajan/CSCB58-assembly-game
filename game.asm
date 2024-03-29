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

.eqv BASE_ADDRESS 0x10008000    # $gp

# Display dimensions in number of units (not pixels)
.eqv DISPLAY_WIDTH 64
.eqv DISPLAY_HEIGHT 64
.eqv DISPLAY_RIGHT 63   # DISPLAY_WIDTH - 1
.eqv DISPLAY_BOTTOM 63  # DISPLAY_HEIGHT - 1

.eqv PLAYER_WIDTH 3
.eqv PLAYER_HEIGHT 3

# Colours
.eqv RED 0xFF0000
.eqv GREEN 0x00FF00
.eqv BLUE 0x0000FF

.text

.globl main

j main


##### DRAWING #####

# Computes the framebuffer address of the unit (x, y)
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
    li $t3, BASE_ADDRESS

    mult $t1, $t2
    mflo $v0
    add $v0, $v0, $t0
    sll $v0, $v0, 2         # $v0 = (y * DISPLAY_WIDTH + x) * 4 = offset from base address
    add $v0, $v0, $t3       # $v0 = offset + BASE_ADDRESS
.end_macro

# Computes the framebuffer address of the unit (x, y)
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
    li $t3, BASE_ADDRESS

    mult %y_reg, $t2
    mflo $v0
    add $v0, $v0, %x_reg
    sll $v0, $v0, 2         # $v0 = (y * DISPLAY_WIDTH + x) * 4 = offset from base address
    add $v0, $v0, $t3       # $v0 = offset + BASE_ADDRESS
.end_macro

# Colours the given unit with the given colour
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

# Fills the screen with the given colour
# Parameters:
    # %colour: colour (immediate value)
# Uses:
#   $s0
#   $v0: unit_address calls
.macro fill_background(%colour)
    unit_address(DISPLAY_RIGHT, DISPLAY_BOTTOM)
    move $s0, $v0               # $s0 = addr(last unit to colour)
    unit_address(0, 0)   # $v0 = addr(current unit)

_fill_background_loop:
    bgt $v0, $s0, _fill_background_loop_end     # while the last unit is not reached
    colour_unit($v0, %colour)
    add $v0, $v0, 4                             # next unit is sizeof(word) ahead
    j _fill_background_loop

_fill_background_loop_end:
.end_macro

# Draws a rectangular entity with the specified attributes
# Parameters:
    # %x_reg:
    # %y_reg:
    # %width
    # %height
    # %colour:
# Uses:
    # %x_reg
    # %y_reg
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


##### GAME #####

main:
    fill_background(RED)
    li $a0, 0
    li $a1, 0
    draw_entity($a0, $a1, PLAYER_WIDTH, PLAYER_HEIGHT, GREEN)

    # Exit
    li      $v0,    10
    syscall
