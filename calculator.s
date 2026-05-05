.global main

.section .data
	hello:		.asciz "Hello, world!\n"
	fmt_in:		.asciz "%d"
	fmt_out: 	.asciz "-> %d\n"

.section .bss
	.comm		num,	4

.section .text
main:
	sub $8, %rsp

	// Printf
	lea hello(%rip), %rdi
	xor %rax, %rax
	call printf

	// Scanf
	lea fmt_in(%rip), %rdi
	lea num(%rip), %rsi
	xor %rax, %rax
	call scanf

	add $8, %rsp
	xor %rax, %rax
	ret
