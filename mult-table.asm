# mult-table.asm
#
# Print out multiplication tables from 2 to 9
#

## MACROS ##
.include "macros.asm"

.macro inner_loop ()
    print_str(" - ")
    print_int($t0)
    print_char('x')
    print_int($t1)
    print_str(" = ")
    mul $a0, $t0, $t1
    print_int($a0)
    print_char('\n')
.end_macro

## TEXT (PROGRAM) ##
.text
.globl main

main:
    # Loop 2 ~ 9
    # $t0: loop counter
    li $t0, 2
loop:
    print_int($t0)
    print_str(" times table:\n")
    # $t1: nested loop counter
    for($t1, 1, 9, inner_loop)
    add $t0, $t0, 1
    ble $t0, 9, loop
    exit(0)
