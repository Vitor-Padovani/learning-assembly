.global main

.section .data
	msg_op1:	.asciz "Type the first operand:\n"
	msg_opt:	.asciz "Type the operator (+, -, *, /, ^, r, a, !, c):\n"
	msg_op2:	.asciz "Type the second operand:\n"
	msg_cont:	.asciz "Continue? (y/n):\n"

	fmt_opn_in:		.asciz "%lf"
	fmt_char_in:	.asciz " %c"
	fmt_result: 	.asciz "-> %g\n"

	msg_div_zero:	.asciz "Error: Division by zero not allowed\n"
    msg_neg_sqrt:   .asciz "Error: Negative squre root not allowed\n"
    msg_fact_inv:   .asciz "Error: Factorial requires a non-negative integer\n"
    msg_arr_inv:    .asciz "Error: Arrangement requires non-negative integers with n >= r\n"
    msg_comb_inv:   .asciz "Error: Combination needs non-negative integers and n >= r\n"
    msg_inv_zero:   .asciz "Error: Not allowed to invert zero\n"

    const_one:      .double 1.0

.section .bss
	.comm	op1,	8
	.comm	op2,	8
	.comm	opt,	1

.section .text
// ========== OPERATIONS ========== //
op_sum:
    push %rbp
    mov %rsp, %rbp
    addsd %xmm1, %xmm0
	mov %rbp, %rsp
    pop %rbp
    ret

op_subtraction:
    push %rbp
    mov %rsp, %rbp
    subsd %xmm1, %xmm0
	mov %rbp, %rsp
    pop %rbp
    ret

op_mult:
    push %rbp
    mov %rsp, %rbp
    mulsd %xmm1, %xmm0
	mov %rbp, %rsp
    pop %rbp
    ret

op_div:
    push %rbp
    mov %rsp, %rbp

	// Verifies division by zero
    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm1
    jne .div_allowed

    lea msg_div_zero(%rip), %rdi
    xor %rax, %rax
    call printf
    xor %rax, %rax
    jmp .div_finish

	.div_allowed:
		divsd %xmm1, %xmm0
		mov $1, %rax

	.div_finish:
		mov %rbp, %rsp
		pop %rbp
		ret

//                             ALLOWED TO USE LIBC POW??? accepts negative exponent?
op_pow:
    push %rbp
    mov %rsp, %rbp

    # Converts exponent to integer
    cvttsd2si %xmm1, %rcx

    movsd const_one(%rip), %xmm1
    test %rcx, %rcx
    jz .pow_finish

.pow_loop:
    mulsd %xmm0, %xmm1
    dec %rcx
    jnz .pow_loop

.pow_finish:
    movsd %xmm1, %xmm0

    pop %rbp
    ret

op_sqrt:
    push %rbp
    mov %rsp, %rbp

	// Verifies negative square root
    xorpd %xmm1, %xmm1
    ucomisd %xmm0, %xmm1
    jbe .sqrt_allowed

    lea msg_neg_sqrt(%rip), %rdi
    xor %rax, %rax
    call printf
    xor %rax, %rax
    jmp .sqrt_finish

	.sqrt_allowed:
		sqrtsd  %xmm0, %xmm0
		mov     $1, %rax

	.sqrt_finish:
		pop     %rbp
		ret

factorial:
    push %rbp
    mov %rsp, %rbp

    # Converts a double to integer
    cvttsd2si %xmm0, %rcx
    mov $1, %rax

    cmp $1, %rcx
    jle .fact_done

.fact_loop:
    imul %rcx, %rax
    dec %rcx
    cmp $1, %rcx
    jg .fact_loop

.fact_done:
    # Converts an integer to double
    cvtsi2sd %rax, %xmm0
    mov %rbp, %rsp
	pop %rbp
    ret

op_fact:
    push %rbp
    mov %rsp, %rbp

    # n >= 0?
    xorpd %xmm1, %xmm1
    ucomisd %xmm1, %xmm0
    jb .fact_error

    # n is integer? compare n with (double)(int)n
    cvttsd2si %xmm0, %rax
    cvtsi2sd %rax, %xmm1
    ucomisd %xmm1, %xmm0
    jne .fact_error

    call factorial
    mov $1, %rax
    jmp .fact_end

.fact_error:
    lea msg_fact_inv(%rip), %rdi
    xor %rax, %rax
    call printf
    xor %rax, %rax

.fact_end:
    mov %rbp, %rsp
	pop %rbp
    ret

op_arr:
    push %rbp
    mov %rsp, %rbp
    push %r12 # r12 = n (callee-saved)
    push %r13 # r13 = r (callee-saved)

    movsd %xmm0, -8(%rbp) # save n temporarily
    movsd %xmm1, -16(%rbp) # save r temporarily

    # n >= 0?
    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jb .arr_error

    # r >= 0?
    ucomisd %xmm2, %xmm1
    jb .arr_error

    # n is integer?
    cvttsd2si %xmm0, %rax
    cvtsi2sd %rax, %xmm2
    ucomisd %xmm2, %xmm0
    jne .arr_error

    # r is integer?
    movsd -16(%rbp), %xmm0
    cvttsd2si %xmm0, %rax
    cvtsi2sd %rax, %xmm2
    ucomisd %xmm2, %xmm0
    jne .arr_error

    # n >= r?
    movsd -8(%rbp), %xmm0
    movsd -16(%rbp), %xmm1
    ucomisd %xmm0, %xmm1 # r vs n
    ja .arr_error

    # store n and r as integers
    cvttsd2si %xmm0, %r12 # r12 = n
    cvttsd2si %xmm1, %r13 # r13 = r

    # compute n!
    cvtsi2sd %r12, %xmm0
    call factorial
    movsd %xmm0, -8(%rbp) # save n!

    # compute (n-r)!
    mov %r12, %rax
    sub %r13, %rax # rax = n - r
    cvtsi2sd %rax, %xmm0
    call factorial # xmm0 = (n-r)!

    # A(n,r) = n! / (n-r)!
    movsd -8(%rbp), %xmm1 # xmm1 = n!
    divsd %xmm0, %xmm1
    movsd %xmm1, %xmm0

    mov $1, %rax
    jmp .arr_end

.arr_error:
    lea msg_arr_inv(%rip), %rdi
    xor %rax, %rax
    call printf
    xor %rax, %rax

.arr_end:
    pop %r13
    pop %r12
    mov %rbp, %rsp
	pop %rbp
    ret

op_comb:
    push %rbp
    mov %rsp, %rbp
    push %r12 # r12 = n (callee-saved)
    push %r13 # r13 = r (callee-saved)

    movsd %xmm0, -8(%rbp)    # save n
    movsd %xmm1, -16(%rbp)   # save r

    # n >= 0?
    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jb .comb_error

    # r >= 0?
    ucomisd %xmm2, %xmm1
    jb .comb_error

    # n is integer?
    cvttsd2si %xmm0, %rax
    cvtsi2sd %rax, %xmm2
    ucomisd %xmm2, %xmm0
    jne .comb_error

    # r is integer?
    movsd -16(%rbp), %xmm0
    cvttsd2si %xmm0, %rax
    cvtsi2sd %rax, %xmm2
    ucomisd %xmm2, %xmm0
    jne .comb_error

    # n >= r?
    movsd -8(%rbp), %xmm0
    movsd -16(%rbp), %xmm1
    ucomisd %xmm0, %xmm1 # r vs n
    ja .comb_error

    # store n and r as integers
    cvttsd2si %xmm0, %r12 # r12 = n
    cvttsd2si %xmm1, %r13 # r13 = r

    # compute n!
    cvtsi2sd %r12, %xmm0
    call factorial
    movsd %xmm0, -8(%rbp) # save n!

    # compute r!
    cvtsi2sd %r13, %xmm0
    call factorial
    movsd %xmm0, -16(%rbp) # save r!

    # compute (n-r)!
    mov %r12, %rax
    sub %r13, %rax # rax = n - r
    cvtsi2sd %rax, %xmm0
    call factorial # xmm0 = (n-r)!

    # C(n,r) = n! / (r! * (n-r)!)
    movsd -16(%rbp), %xmm1 # xmm1 = r!
    mulsd %xmm0, %xmm1 # xmm1 = r! * (n-r)!
    movsd -8(%rbp), %xmm0 # xmm0 = n!
    divsd %xmm1, %xmm0

    mov $1, %rax
    jmp .comb_end

.comb_error:
    lea msg_comb_inv(%rip), %rdi
    xor %rax, %rax
    call printf
    xor %rax, %rax

.comb_end:
    pop %r13
    pop %r12
    mov %rbp, %rsp
	pop %rbp
    ret

op_inv:
    push %rbp
    mov %rsp, %rbp

    xorpd %xmm1, %xmm1
    ucomisd %xmm1, %xmm0 # op1 == 0?
    jne .inv_ok

    lea msg_inv_zero(%rip), %rdi
    xor %rax, %rax
    call printf
    xor %rax, %rax
    jmp .inv_end

.inv_ok:
    movsd const_one(%rip), %xmm1
    divsd %xmm0, %xmm1 # 1.0 / op1
    movsd %xmm1, %xmm0
    mov $1, %rax

.inv_end:
    mov %rbp, %rsp
	pop %rbp
    ret

// ========== MAIN FUNCTIONS ========== //
show_result:
    push %rbp
    mov %rsp, %rbp
    lea fmt_result(%rip), %rdi
	call printf
	mov %rbp, %rsp
	pop %rbp
	ret

// Asks for the 2nd operand
read_op2:
	push %rbp
	mov %rsp, %rbp

	lea msg_op2(%rip), %rdi
	xor %rax, %rax
	call printf

	lea fmt_opn_in(%rip), %rdi
	lea op2(%rip), %rsi
	xor %rax, %rax
	call scanf

	mov %rbp, %rsp
	pop %rbp
	ret

main:
	sub $8, %rsp

.main_loop:

	// Asks for the 1st operand
	lea msg_op1(%rip), %rdi
	xor %rax, %rax
	call printf

	lea fmt_opn_in(%rip), %rdi
	lea op1(%rip), %rsi
	xor %rax, %rax
	call scanf

	// Asks for the operator
	lea msg_opt(%rip), %rdi
	xor %rax, %rax
	call printf

	lea fmt_char_in(%rip), %rdi
	lea opt(%rip), %rsi
	xor %rax, %rax
	call scanf

	mov opt(%rip), %eax

	// Comparations
	cmpb $'+', %al
	je .case_sum
	cmpb $'-', %al
	je .case_sub
	cmpb $'*', %al
	je .case_mult
	cmpb $'/', %al
	je .case_div
	cmpb $'^', %al
	je .case_pow
	cmpb $'r', %al
	je .case_sqrt
    cmpb $'a', %al
	je .case_arr
    cmpb $'!', %al
	je .case_fact
    cmpb $'c', %al
	je .case_comb
    cmpb $'i', %al
	je .case_inv

# Asks if the user wants to repeat or finish
.main_repeat:
    lea msg_cont(%rip), %rdi
    xor %rax, %rax
    call printf

    lea fmt_char_in(%rip), %rdi
    lea opt(%rip), %rsi
    xor %rax, %rax
    call scanf

	mov opt(%rip), %eax
    cmpb $'y', %al
    je .main_loop

	add $8, %rsp
	xor %rax, %rax
	ret

// ========== CASES ========== //
.case_sum:
	call read_op2
    movsd op1(%rip), %xmm0
    movsd op2(%rip), %xmm1
    call op_sum
    call show_result
    jmp .main_repeat

.case_sub:
	call read_op2
    movsd op1(%rip), %xmm0
    movsd op2(%rip), %xmm1
    call op_subtraction
    call show_result
    jmp .main_repeat

.case_mult:
    call read_op2
    movsd op1(%rip), %xmm0
    movsd op2(%rip), %xmm1
    call op_mult
    call show_result
    jmp .main_repeat

.case_div:
    call read_op2
    movsd op1(%rip), %xmm0
    movsd op2(%rip), %xmm1
    call op_div
    test %rax, %rax
    jz .main_repeat
    call show_result
    jmp .main_repeat

.case_pow:
    call read_op2
    movsd op1(%rip), %xmm0
    movsd op2(%rip), %xmm1
    call op_pow
    call show_result
    jmp .main_repeat

.case_sqrt:
    movsd op1(%rip), %xmm0
    call op_sqrt
    test %rax, %rax
    jz .main_repeat
    call show_result
    jmp .main_repeat

.case_arr:
    call read_op2
    movsd op1(%rip), %xmm0
    movsd op2(%rip), %xmm1
    call op_arr
    test %rax, %rax
    jz .main_repeat
    call show_result
    jmp .main_repeat

.case_fact:
    movsd op1(%rip), %xmm0
    call op_fact
    test %rax, %rax
    jz .main_repeat
    call show_result
    jmp .main_repeat

.case_comb:
    call read_op2
    movsd op1(%rip), %xmm0
    movsd op2(%rip), %xmm1
    call op_comb
    test %rax, %rax
    jz .main_repeat
    call show_result
    jmp .main_repeat

.case_inv:
    movsd op1(%rip), %xmm0
    call op_inv
    test %rax, %rax
    jz .main_repeat
    call show_result
    jmp .main_repeat
