.global main
.data
	a: .quad 0
	msg_in: .asciz "digite o valor de a:"
	fmt: .asciz "%lld"
	msg_out: .asciz "resultado: %lld\n"
.text
main:
	mov $msg_in, %rdi
	call printf
	mov $fmt, %rdi
	mov $a, %rsi
	call scanf
	
	cmpq $0, a
	jl bloco_if
	#bloco do else
	movq a, %rax
	movq $-1, %rbx
	imulq %rbx
	jmp fim_if
	
bloco_if:
	movq a, %rax
	movq $3, %rbx
	imulq %rbx
	addq $1, %rax
fim_if:
	movq $msg_out, %rdi
	movq %rax, %rsi
	call printf

	movq $60, %rax
	movq $0, %rdi
	syscall


	
	
