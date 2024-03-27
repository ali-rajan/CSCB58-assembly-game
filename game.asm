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

# Colours the given unit with the given colour
# Parameters:
    # %addr_reg: register storing the address of the unit to colour
    # %colour: colour (immediate value)
# Uses:
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

.macro draw_player()

.end_macro


##### GAME #####

main:
    fill_background(RED)

    unit_address(0, 0)
    colour_unit($v0, GREEN)

# Exit
    li      $v0,    10
    syscall
