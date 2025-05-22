# Data segment
.data
    space:          .asciiz " "
    result:         .asciiz "The product is: "
    endLine:        .asciiz "\n"
    .align 3        # Align to 8-byte boundary for 64-bit values
    dulieu1_low:    .word 0xFFFFFFFF       # Low 32 bits of first number
    dulieu1_high:   .word 0x00000000   # High 32 bits of first number
    dulieu2_low:    .word 0xFFFFFFFF      # Low 32 bits of second number
    dulieu2_high:   .word 0x00000000   # High 32 bits of second number
    result_0:       .word 0   # Lowest 32 bits of result
    result_1:       .word 0   # Second 32 bits of result  
    result_2:       .word 0   # Third 32 bits of result
    result_3:       .word 0   # Highest 32 bits of result
    str_dl1:        .asciiz "Du lieu 1 = "
    str_dl2:        .asciiz "Du lieu 2 = "
    str_product:    .asciiz "Tich = "
    str_newline:    .asciiz "\n"
    str_too_large:  .asciiz " (Gia tri qua lon de hien thi dang thap phan)"
    str_overflow:   .asciiz "Overflow occurred during multiplication.\n"

# Code segment    
.text
main:
    # Xuat thong tin (syscall)   
    li $v0, 4             
    la $a0, endLine       
    syscall

    # In du lieu 1
    li $v0, 4
    la $a0, str_dl1
    syscall
    
    # Hien thi so 64-bit thu nhat
    lw $a0, dulieu1_high
    li $v0, 34  # In s? d?ng hex
    syscall
    
    li $v0, 11
    li $a0, 'x'
    syscall
    
    lw $a0, dulieu1_low
    li $v0, 34  # In s? d?ng hex
    syscall
    

    
    la $a0, str_newline
    li $v0, 4
    syscall
    
    # In du lieu 2
    li $v0, 4
    la $a0, str_dl2
    syscall
    
    # Hien thi so 64-bit thu hai
    lw $a0, dulieu2_high
    li $v0, 34  # In s? d?ng hex
    syscall
    
    li $v0, 11
    li $a0, 'x'
    syscall
    
    lw $a0, dulieu2_low
    li $v0, 34  # In s? d?ng hex
    syscall
    
    la $a0, str_newline
    li $v0, 4
    syscall

    # Kiem tra dau cua hai so
    lw $t0, dulieu1_high
    lw $t1, dulieu2_high
    
    # Kiem tra so am va xu ly
    li $s6, 0       # Bien danh dau so am cho so thu nhat (1 neu am)
    li $s7, 0       # Bien danh dau so am cho so thu hai (1 neu am)
    
    # Kiem tra so thu nhat co am khong
    srl $t2, $t0, 31
    beqz $t2, check_second_number
    
    # So thu nhat am, lay bu 2
    li $s6, 1
    lw $t3, dulieu1_low
    lw $t4, dulieu1_high
    not $t3, $t3      # Lay bu 1
    not $t4, $t4
    addiu $t3, $t3, 1  # Cong 1 de lay bu 2
    sltiu $t5, $t3, 1   # Ki?m tra carry
    beqz $t5, store_neg_1
    addiu $t4, $t4, 1  # C?ng carry vào high word
store_neg_1:
    sw $t3, dulieu1_low
    sw $t4, dulieu1_high
    
check_second_number:
    # Kiem tra so thu hai co am khong
    srl $t2, $t1, 31
    beqz $t2, start_multiplication
    
    # So thu hai am, lay bu 2
    li $s7, 1
    lw $t3, dulieu2_low
    lw $t4, dulieu2_high
    nor $t3, $t3, $zero  # L?y bù 1 t?i ?u h?n dùng not
    nor $t4, $t4, $zero
    addiu $t3, $t3, 1    # Cong 1 de lay bu 2
    sltiu $t5, $t3, 1     # Ki?m tra carry
    addu $t4, $t4, $t5   # C?ng carry vào high word
store_neg_2:
    sw $t3, dulieu2_low
    sw $t4, dulieu2_high

start_multiplication:
    # Goi ham nhan 64-bit
    jal Mult64
    
    # Kiem tra dau cua ket qua
    xor $t0, $s6, $s7
    beqz $t0, check_overflow   # Neu dau giong nhau, ket qua duong
    
    # Ket qua am, lay bu 2
    lw $t1, result_0
    lw $t2, result_1
    not $t1, $t1     # Lay bu 1
    not $t2, $t2
    addiu $t1, $t1, 1  # Cong 1 de lay bu 2
    sltiu $t5, $t1, 1   # Ki?m tra carry
    beqz $t5, skip_carry_1
    addiu $t2, $t2, 1
skip_carry_1:
    sw $t1, result_0
    sw $t2, result_1
    
    # X? lý ph?n cao c?a k?t qu?
    lw $t3, result_2
    lw $t4, result_3
    not $t3, $t3
    not $t4, $t4
    sltiu $t5, $t2, 1   # Ki?m tra carry t? ph?n th?p
    beqz $t5, skip_carry_2
    addiu $t3, $t3, 1
    sltiu $t5, $t3, 1
    beqz $t5, skip_carry_2
    addiu $t4, $t4, 1
skip_carry_2:
    sw $t3, result_2
    sw $t4, result_3

check_overflow:
    # Special case for -2^63
    lw $t1, result_0
    lw $t2, result_1
    lw $t3, result_2
    lw $t4, result_3
    
    # Check if result is -2^63 (0x8000_0000_0000_0000)
    li $t5, 0
    bne $t1, $t5, not_min_int
    li $t5, 0x80000000
    bne $t2, $t5, not_min_int
    li $t5, 0
    bne $t3, $t5, not_min_int
    bne $t4, $t5, not_min_int
    
    # It's -2^63, which is valid
    j no_overflow
    
not_min_int:
    # Original overflow check logic
    lw $t0, result_1
    srl $t1, $t0, 31   # Bit d?u c?a result_1
    beqz $t1, check_positive_overflow
    
    # K?t qu? âm - t?t c? các bit trong result_2 và result_3 ph?i là 1
    li $t4, 0xFFFFFFFF
    lw $t2, result_2
    lw $t3, result_3
    bne $t2, $t4, overflow_detected
    bne $t3, $t4, overflow_detected
    j no_overflow
    
check_positive_overflow:
    # K?t qu? d??ng - t?t c? các bit trong result_2 và result_3 ph?i là 0
    lw $t2, result_2
    lw $t3, result_3
    bnez $t2, overflow_detected
    bnez $t3, overflow_detected
    
no_overflow:
    j print_result

overflow_detected:
    li $v0, 4
    la $a0, str_overflow
    syscall
    sw $zero, result_0
    sw $zero, result_1
    sw $zero, result_2
    sw $zero, result_3
    j print_result

print_result:
    # In ket qua
    li $v0, 4
    la $a0, str_product
    syscall
    
    # In dau am neu can
    xor $t0, $s6, $s7
    beqz $t0, print_result_value
    
    li $v0, 11
    li $a0, 45   # Ky tu '-'
    syscall
    
print_result_value:
    # In giá tr? k?t qu? d?ng hex
    lw $a0, result_3
    li $v0, 34  # In s? d?ng hex
    syscall
    
    li $v0, 11
    li $a0, 'x'
    syscall
    
    lw $a0, result_2
    li $v0, 34
    syscall
    
    li $v0, 11
    li $a0, 'x'
    syscall
    
    lw $a0, result_1
    li $v0, 34
    syscall
    
    li $v0, 11
    li $a0, 'x'
    syscall
    
    lw $a0, result_0
    li $v0, 34
    syscall
    
    j Kthuc

# Ham nhan hai so 64-bit
Mult64:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    sw $zero, result_0
    sw $zero, result_1
    sw $zero, result_2
    sw $zero, result_3
    
    lw $t0, dulieu1_low
    lw $t1, dulieu1_high
    or $t2, $t0, $t1
    beqz $t2, mult_complete
    
    lw $t0, dulieu2_low
    lw $t1, dulieu2_high
    or $t2, $t0, $t1
    beqz $t2, mult_complete
    
    lw $t0, dulieu1_low
    lw $t1, dulieu1_high
    li $t2, 0
    li $t3, 0x80000000
    bne $t0, $t2, check_second_min_int
    bne $t1, $t3, check_second_min_int
    
    lw $t0, dulieu2_low
    lw $t1, dulieu2_high
    li $t2, 0xFFFFFFFF
    bne $t0, $t2, check_second_min_int
    bne $t1, $t2, check_second_min_int
    
    j overflow_mult
    
check_second_min_int:
    lw $t0, dulieu2_low
    lw $t1, dulieu2_high
    li $t2, 0
    li $t3, 0x80000000
    bne $t0, $t2, check_second_one
    bne $t1, $t3, check_second_one
    
    lw $t0, dulieu1_low
    lw $t1, dulieu1_high
    li $t2, 0xFFFFFFFF
    bne $t0, $t2, check_second_one
    bne $t1, $t2, check_second_one
    
    j overflow_mult
    
overflow_mult:
    li $t0, 0
    li $t1, 0x80000000
    sw $t0, result_0
    sw $t1, result_1
    sw $zero, result_2
    sw $zero, result_3
    j mult_complete
    
check_second_one:
    lw $t0, dulieu2_low
    lw $t1, dulieu2_high
    li $t2, 1
    bne $t0, $t2, check_neg_one
    bnez $t1, check_neg_one
    
    # Special case: -2^63 * 1 should not trigger overflow
    lw $t0, dulieu1_low
    lw $t1, dulieu1_high
    li $t2, 0
    li $t3, 0x80000000
    bne $t0, $t2, normal_mult_by_one
    bne $t1, $t3, normal_mult_by_one
    
    # It's -2^63 * 1, store as special case
    sw $t0, result_0
    sw $t1, result_1
    sw $zero, result_2
    sw $zero, result_3
    j mult_complete
    
normal_mult_by_one:
    lw $t0, dulieu1_low
    lw $t1, dulieu1_high
    sw $t0, result_0
    sw $t1, result_1
    j extend_sign
    
check_neg_one:
    lw $t0, dulieu1_low
    lw $t1, dulieu1_high
    li $t2, 0xFFFFFFFF
    bne $t0, $t2, check_second_neg_one
    bne $t1, $t2, check_second_neg_one
    
    lw $t0, dulieu2_low
    lw $t1, dulieu2_high
    not $t0, $t0
    not $t1, $t1
    addiu $t0, $t0, 1
    sltiu $t2, $t0, 1
    beqz $t2, store_neg_result_1
    addiu $t1, $t1, 1
    
store_neg_result_1:
    sw $t0, result_0
    sw $t1, result_1
    j extend_sign
    
check_second_neg_one:
    lw $t0, dulieu2_low
    lw $t1, dulieu2_high
    li $t2, 0xFFFFFFFF
    bne $t0, $t2, continue_mult_setup
    bne $t1, $t2, continue_mult_setup
    
    lw $t0, dulieu1_low
    lw $t1, dulieu1_high
    not $t0, $t0
    not $t1, $t1
    addiu $t0, $t0, 1
    sltiu $t2, $t0, 1
    beqz $t2, store_neg_result_2
    addiu $t1, $t1, 1
store_neg_result_2:
    sw $t0, result_0
    sw $t1, result_1
    j extend_sign
    
continue_mult_setup:
    lw $s0, dulieu1_low    # A_low
    lw $s1, dulieu1_high   # A_high
    lw $s2, dulieu2_low    # B_low
    lw $s3, dulieu2_high   # B_high
    
    sw $zero, result_0
    sw $zero, result_1
    sw $zero, result_2
    sw $zero, result_3
    
    multu $s0, $s2
    mflo $t0
    mfhi $t1
    sw $t0, result_0
    sw $t1, result_1
    
    multu $s1, $s2
    mflo $t2
    mfhi $t3
    
    lw $t4, result_1
    addu $t4, $t4, $t2
    sw $t4, result_1
    
    sltu $t5, $t4, $t2
    addu $t3, $t3, $t5
    sw $t3, result_2
    
    multu $s0, $s3
    mflo $t2
    mfhi $t3
    
    lw $t4, result_1
    addu $t4, $t4, $t2
    sw $t4, result_1
    
    sltu $t5, $t4, $t2
    lw $t6, result_2
    addu $t6, $t6, $t3
    addu $t6, $t6, $t5
    sw $t6, result_2
    
    sltu $t5, $t6, $t3
    sw $t5, result_3
    
    multu $s1, $s3
    mflo $t2
    mfhi $t3
    
    lw $t4, result_2
    addu $t4, $t4, $t2
    sw $t4, result_2
    
    sltu $t5, $t4, $t2
    lw $t6, result_3
    addu $t6, $t6, $t3
    addu $t6, $t6, $t5
    sw $t6, result_3

extend_sign:
    lw $t0, result_0
    lw $t1, result_1
    lw $t2, result_2  
    lw $t3, result_3
    
    srl $t4, $t1, 31
    beqz $t4, pos_ext
    
    li $t5, 0xFFFFFFFF
    beq $t2, $t5, check_high_sign
    bne $t2, $t5, overflow_detected
    
check_high_sign:
    beq $t3, $t5, mult_complete
    bne $t3, $t5, overflow_detected
    
pos_ext:
    bnez $t2, overflow_detected
    bnez $t3, overflow_detected
    
    sw $zero, result_2
    sw $zero, result_3
    j mult_complete

mult_complete:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

Kthuc:
    li $v0, 10
    syscall
