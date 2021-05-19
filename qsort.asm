# qsort.asm
#
# Implement Quick sort algorithm
#

## DATA ##
.data

# The current length of the array
len: .word 0
# The capacity of the array
cap: .word 0

## MACROS ##
.include "macros.asm"
.eqv INITIAL_CAP 10
.eqv ARRAY_GROWTH_STEP 10

# Gets the address to (base + idx*(-4))
#
# @param %base The base address register
# @param %idx Index (either an immediate value or register name)
# @result $v0 The address
.macro getaddr (%base, %idx)
    add $v0, $zero, %idx
    mul $v0, $v0, -4 # 1 word = 4 bytes
    add $v0, $v0, %base
.end_macro

# Gets the value of the address (base + idx*(-4))
#
# @param %base The base address register
# @param %idx Index (either an immediate value or register name)
# @result $v0 The value of the address
.macro getval (%base, %idx)
    getaddr(%base, %idx)
    lw $v0, 0($v0)
.end_macro

# Sets the value to the address (base + idx*(-4))
#
# @param %base The base address register
# @param %idx Index (either an immediate value or register name)
# @param %val register of new value
# @param $v0 The value of the address
.macro setval (%base, %idx, %val)
    getaddr(%base, %idx)
    sw %val, 0($v0)
.end_macro

# Gets the current size of the array
#
# @result $v0 The current size
.macro getsize ()
    la $a0, len
    getval($a0, 0)
.end_macro

# Sets the current size of the array
#
# @param %size new value register
.macro setsize (%size)
    la $a0, len
    setval($a0, 0, %size)
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

# Gets the capacity of the array
#
# @result $v0 The current size
.macro getcap ()
    la $a0, cap
    getval($a0, 0)
.end_macro

# Sets the capacity of the array
#
# @param %cap new value register
.macro setcap (%cap)
    la $a0, cap
    setval($a0, 0, %cap)
.end_macro

# Initialize an array on the stack.
#
# @param %reg The array register (Do not use $a0, $a1)
# @param %cap The capacity of the new array (either an immediate value or register name)
.macro init_array (%reg, %cap)
    add %reg, $sp, -4 # %reg = $sp - 4
    resize_array(%reg, %cap)
.end_macro

# Resizes the array.
#
# @param %reg The array register (Do not use $a0, $a1)
# @param %addcap Additional capacity (either an immediate value or register name)
.macro resize_array (%reg, %addcap)
    add $a1, $zero, %addcap # $a1 = %addcap
    mul $a0, $a1, -4        # 1 word = 4 bytes
    add $sp, $sp, $a0       # Stack grows
    getcap()
    add $a1, $a1, $v0
    setcap($a1)             # Update capacity
.end_macro

# Swaps the given two array elements using the temp register
#
# @param %arr Array register
# @param %idxa Index A
# @param %idxb Index B
# @param %tmp A temp register
.macro arrswap (%arr, %idxa, %idxb, %tmp)
    getval(%arr, %idxb)
    move %tmp, $v0              # %tmp = arr[b]

    getval(%arr, %idxa)
    move $a0, $v0               # $a0 = array[a]
    setval(%arr, %idxb, $a0)    # array[b] = array[a]

    setval(%arr, %idxa, %tmp)   # array[a] = %tmp
.end_macro

## TEXT (PROGRAM) ##
.text
.globl main

main:
    init_array($s0, INITIAL_CAP)            # Init array $s0
loop:
    print_str("> Input: ")
    read_int()
    move $s1, $v0                           # $s1 = The integer read
try_append:
    move $a0, $s0                           # Argument 0: The address to the array
    move $a1, $s1                           # Argument 1: The integer read
    jal append                              # Call append
    beq $v0, 1, else                        # Check result code

    getsize()
    add $a2, $v0, -1                        # Argument 2: The last index of the array
    li $a1, 0                               # Argument 1: 0
    move $a0, $s0                           # Argument 0: The address to the array
    jal sort                                # Call sort

    move $a0, $s0                           # Argument 0: The address to the array
    jal print_arr                           # Call print_err
    j loop                                  # Loop
else:                                       # if capacity exceeded
    resize_array($s0, ARRAY_GROWTH_STEP)    # Expand array
    j try_append                            # Retry

# Appends an item into the array.
#
# @param $a0 The address to the array
# @param %a1 An item to add
# @result $v0 result code -- 0: success, 1: failed; capacity exceeded
append:
    backup($s0)
    backup($s1)
    backup($s2)
    backup($s3)

    move $s0, $a0           # $s0 = array address
    move $s1, $a1           # $s1 = item to add

    getsize()
    move $s2, $v0           # $s2 = the current length of the array
    getcap()
    move $s3, $v0           # $s3 = the capacity of the array

    # Check array capacity
    blt $s2, $s3, do_append # goto do_append if size < cap
    li $v0, 1               # $v0 (result code) = 1 (capacity exceeded)
    j append_return
do_append:
    setval($s0, $s2, $s1)   # Append the item to the array
    inc_size()              # Update length
    li $v0, 0               # $v0 (result code) = 0 (success)
append_return:
    restore($s3)
    restore($s2)
    restore($s1)
    restore($s0)
    jr $ra                  # return

# Prints the array.
#
# @param $a0 The address to the array
print_arr:
    backup($s0)
    backup($s1)
    backup($s2)

    move $s0, $a0               # $s0 = the address to the array
    getsize()
    move $s1, $v0               # $s1 = the current length of the array

    print_str(":: Array: (size: ")
    print_int($s1)
    print_str(") [ ")
    ble $s1, 0, printarr_end    # pass if empty
    li $s2, 0                   # $s2 is a loop counter
printarr_loop:
    getval($s0, $s2)
    print_int($v0)
    print_str(" ")
    add $s2, $s2, 1
    blt $s2, $s1, printarr_loop # repeat if $s2 < len
printarr_end:
    print_str("]\n")
    restore($s2)
    restore($s1)
    restore($s0)
    jr $ra

# Sorts the array in descending order.
#
# @param $a0 The address to the array
# @param $a1 low (stating index)
# @param $a2 high (ending index)
sort:
    backup($ra)
    backup($s0)
    backup($s1)
    backup($s2)
    backup($s3)

    move $s0, $a0           # $s0 = the address to the array
    move $s1, $a1           # $s1 = low
    move $s2, $a2           # $s2 = high
    bge $s1, $s2, sort_end  # go sort_end if low >= high
do_sort:
    move $a0, $s0           # Argument 0: The address to the array
    move $a1, $s1           # Argument 1: low
    move $a2, $s2           # Argument 2: high
    jal partition           # Call partition
    move $s3, $v0           # $s3 = pivot

    move $a0, $s0           # Argument 0: The address to the array
    move $a1, $s1           # Argument 1: low
    add $a2, $s3, -1        # Argument 2: pivot - 1
    jal sort                # Call sort
    move $a0, $s0           # Argument 0: The address to the array
    add $a1, $s3, 1         # Argument 1: pivot + 1
    move $a2, $s2           # Argument 2: high
    jal sort                # Call sort
sort_end:
    restore($s3)
    restore($s2)
    restore($s1)
    restore($s0)
    restore($ra)
    jr $ra

# @param $a0 The address to the array
# @param $a1 low (stating index)
# @param $a2 high (ending index)
# @result $v0 pivot
partition:
    backup($s0)
    backup($s1)
    backup($s2)
    backup($s3)
    backup($s4)
    backup($s5)
    backup($s6)

    move $s0, $a0               # $s0 = the address to the array
    move $s1, $a1               # $s1 = low
    move $s2, $a2               # $s2 = high

    add $s3, $s1, $s2
    li $a0, 2
    div $s3, $a0
    mflo $s3                    # $s3 = mid = (low + right) / 2
    arrswap($s0, $s1, $s3, $s6) # arrswap(arr, low, mid, $s6)

    getval($s0, $s1)
    move $s3, $v0               # $s3 = pivot = array[low]
    move $s4, $s1               # $s4 = i counter = low
    move $s5, $s2               # $s5 = j counter = high

partition_loop:
    bge $s4, $s5, partition_end             # break if i >= j
    partition_loop2:
        getval($s0, $s5)
        move $s6, $v0                       # $s6 = array[j]
        ble $s3, $s6, partition_loop3       # break if pivot <= array[j]
        add $s5, $s5, -1                    # j -= 1
        j partition_loop2
    partition_loop3:
        bge $s4, $s5, partition_loop3_end   # break if i >= j
        getval($s0, $s4)
        move $s6, $v0                       # $s6 = array[i]
        bgt $s3, $s6, partition_loop3_end   # break if pivot > array[i]
        add $s4, $s4, 1                     # i += 1
        j partition_loop3
partition_loop3_end:
    arrswap($s0, $s4, $s5, $s6)             # arrswap(arr, i, j, $s6)
    j partition_loop

partition_end:
    getval($s0, $s4)
    move $s6, $v0           # $s6 = array[i]
    setval($s0, $s1, $s6)   # array[low] = array[i]
    setval($s0, $s4, $s3)   # array[i] = pivot
    move $v0, $s4           # $v0 = i

    restore($s6)
    restore($s5)
    restore($s4)
    restore($s3)
    restore($s2)
    restore($s1)
    restore($s0)
    jr $ra
