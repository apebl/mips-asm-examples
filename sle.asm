# sle.asm
#
# Calculate Ax = b (A: 5x5, x: 5x1)
#
# Note: The matrices are in the column-major order !!
#

## DATA ##
.data

# Matrix A
mat_A: .word 7 8 4 8 4
             1 8 1 8 4
             7 6 3 0 2
             9 5 7 4 1
             3 6 8 5 7

# Matrix x
mat_x: .word 4 2 6 6 5

# Result matrix
mat_b: .word 0 0 0 0 0

## MACROS ##
.include "macros.asm"
.eqv ROWS 5
.eqv COLS 5
.eqv ROWS_IDX 4
.eqv COLS_IDX 4

# Gets the address at (x, y) of the matrix.
#
# @param $mat The base address of the matrix
# @param $x cols **index** (starts from 0)
# @param $y rows **index** (starts from 0)
# @result $v0 The address
.macro getaddr (%mat, %x, %y)
    mul $v0, %x, COLS
    add $v0, $v0, %y
    mul $v0, $v0, 4 # 1 word = 4 bytes
    la $a0, %mat
    add $v0, $v0, $a0
.end_macro

# Gets the value at (x, y) of the matrix.
#
# @param $mat The base address of the matrix
# @param $x cols **index** (starts from 0)
# @param $y rows **index** (starts from 0)
# @result $v0 The value
.macro getval (%mat, %x, %y)
    getaddr(%mat, %x, %y)
    lw $v0, 0($v0)
.end_macro

# Sets the value at (x, y) of the matrix.
#
# @param $mat The base address of the matrix
# @param $x cols **index** (starts from 0)
# @param $y rows **index** (starts from 0)
# @param $val Value register
.macro setval (%mat, %x, %y, %val)
    getaddr(%mat, %x, %y)
    sw %val, 0($v0)
.end_macro

.macro calc ()
    # $t2 = A($t0,$t1) * x(0,$t0)
    getval(mat_A, $t0, $t1)
    move $t2, $v0
    getval(mat_x, $zero, $t0)
    mul $t2, $t2, $v0

    # b(0,$t1) = b(0,$t1) + $t2
    getval(mat_b, $zero, $t1)
    add $t2, $t2, $v0
    setval(mat_b, $zero, $t1, $t2)
.end_macro

# Prints %t1(index) row of the result matrix.
.macro print ()
    print_str("  | ")
    mul $a0, $t1, 4
    la $a1, mat_b
    add $a0, $a0, $a1
    lw $a0, 0($a0)
    print_int($a0)
    print_str(" | \n")
.end_macro

## TEXT (PROGRAM) ##
.text
.globl main

main:
    # Loop 0 ~ COLS_IDX
    # $t0: loop counter (col)
    li $t0, 0
loop:
    for($t1, 0, ROWS_IDX, calc)
    add $t0, $t0, 1
    ble $t0, COLS_IDX, loop

    print_str("Result:\n")
    # $t1: nested loop counter (row)
    for($t1, 0, ROWS_IDX, print)
    exit(0)
