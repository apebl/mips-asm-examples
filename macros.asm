# macros.asm
#

# Terminates the program.
#
# @param $val Exit status
.macro exit (%val)
    li $a0, %val
    li $v0, 17 # Code for syscall: exit2
    syscall
.end_macro

# Prints the given integer.
#
# @param %val May be either an immediate value or register name
.macro print_int (%val)
    add $a0, $zero, %val
    li $v0, 1 # Code for syscall: print integer
    syscall
.end_macro

# Prints the given character.
#
# @param %val A character literal
.macro print_char (%val)
    li $a0, %val
    li $v0, 11 # Code for syscall: print character
    syscall
.end_macro

# Prints the string of the given address.
#
# @param %pstr A pointer to a string
.macro print_stra (%pstr)
    la $a0, %pstr
    li $v0, 4 # Code for syscall: print string
    syscall
.end_macro

# Prints the given string.
#
# @param %str A string literal
.macro print_str (%str)
    .data
printstr_label: .asciiz %str
    .text
    print_stra(printstr_label)
.end_macro

# Reads an integer.
#
# @result $v0 The integer read
.macro read_int ()
    li $v0, 5 # Code for syscall: read integer
    syscall
.end_macro

# Repeats the given macro with values of the %ireg register from %from to %to
#
# @param %ireg A register to iterate (Counter)
# @param %from Start value
# @param %to End value
# @param %macro The name of the macro to repeat
.macro for (%ireg, %from, %to, %macro)
    add %ireg, $zero, %from
forloop_label:
    %macro()
    add %ireg, %ireg, 1
    ble %ireg, %to, forloop_label
.end_macro

# Saves the register on the stack.
#
# @param %reg A register to save
.macro backup (%reg)
    addi $sp, $sp, -4
    sw %reg, 0($sp)
.end_macro

# Restores saved register from the stack, in opposite order.
#
# @param %reg A register to save
.macro restore (%reg)
    lw %reg, 0($sp)
    addi $sp, $sp, 4
.end_macro
