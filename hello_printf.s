.global _start
.text
_start:
	mov $msg, %rdi
	call printf
	
	mov $60, %rax
	mov $0, %rdi
	syscall
.data
	msg:	.asciz	"Ola mundo!\n"

