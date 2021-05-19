# ary-stack.asm
#
# Implement Stack using an array (stack capacity: 10)
#

## DATA ##
.data

# Current length
len: .word 0
# Array (cap: 10)
arr: .word 0 0 0 0 0 0 0 0 0 0

## MACROS ##
.include "macros.asm"
.eqv CAPACITY 10

# Gets the address to (base + idx*4)
#
# @param %base The base address
# @param %idx Index (either an immediate value or register name)
# @result $v0 The address
.macro getaddr (%base, %idx)
    add $v0, $zero, %idx
    mul $v0, $v0, 4 # 1 word = 4 bytes
    la $a0, %base
    add $v0, $v0, $a0
.end_macro

# Gets the value of the address (base + idx*4)
#
# @param %base The base address
# @param %idx Index (either an immediate value or register name)
# @result $v0 The value of the address
.macro getval (%base, %idx)
    getaddr(%base, %idx)
    lw $v0, 0($v0)
.end_macro

# Sets the value to the address (base + idx*4)
#
# @param %base The base address
# @param %idx Index (either an immediate value or register name)
# @param %val register of new value
# @param $v0 The value of the address
.macro setval (%base, %idx, %val)
    getaddr(%base, %idx)
    sw %val, 0($v0)
.end_macro

# Gets the current size of the stack
#
# @result $v0 The current size
.macro getsize ()
    getval(len, 0)
.end_macro

# Sets the current size of the stack
#
# @param %size new value register
.macro setsize (%size)
    setval(len, 0, %size)
.end_macro

# Increases the current size by 1
.macro inc_size ()
    getsize()
    add $a1, $v0, 1
    setsize($a1)
.end_macro

# Decreases the current size by 1
.macro dec_size ()
    getsize()
    sub $a1, $v0, 1
    setsize($a1)
.end_macro

# Prints the stack.
.macro print_stack ()
    print_str(":: Stack: (size: ")
    getsize()
    move $t1, $v0                   # $t1 = the current length of the array
    print_int($t1)
    print_str(") [ ")
    ble $t1, 0, printstack_end      # goto printstack_end if len <= 0
    li $t0, 0
printstack_loop:
    getval(arr, $t0)
    print_int($v0)
    print_str(" ")
    add $t0, $t0, 1
    blt $t0, $t1, printstack_loop   # repeat if $t0 < len
printstack_end:
    print_str("]\n")
.end_macro

# Pushes an item into the stack.
#
# @param %val An item (either an immediate value or register name)
.macro push (%val)
    add $t0, $zero, %val    # $t0 = item
    getsize()
    li $t1, CAPACITY        # $t1 = CAPACITY
    blt $v0, $t1, do_push   # goto do_push if len < CAPACITY
    print_str(":: WARN: Stack capacity exceeded! Your input has been discarded\n")
    print_stack()
    j push_end
do_push:
    setval(arr, $v0, $t0)   # arr[len] = item
    inc_size()              # Update length
    print_stack()
push_end:
.end_macro

# Removes and gets an item from the stack.
#
# @result $v0 An pop
.macro pop ()
    getsize()
    sub $t0, $v0, 1     # $t0 = len - 1
    bgt $v0, 0, do_pop  # goto do_pop if not empty
    print_str(":: WARN: Stack is empty!\n")
    print_stack()
    j pop_end
do_pop:
    print_str(":: Popped item: ")
    getval(arr, $t0)    # get arr[len-1]
    print_int($v0)
    dec_size()          # Update length
    print_char('\n')
    print_stack()
pop_end:
.end_macro

## TEXT (PROGRAM) ##
.text
.globl main

main:
    print_str(":: Usage:\n")
    print_str("::  - Input a zero or positive number => push\n")
    print_str("::  - Input a negative number => pop\n")
loop:
    print_str("> Input: ")
    read_int()
    bge $v0, 0, push_input # goto push_input if the input is not a negative number
    pop()
    j loop
push_input:
    push($v0)
    j loop
