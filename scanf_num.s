.global _start
.data
	num: .long	0
	fmt: .asciz	"%d"
	msg: .asciz	"valor digitado:%d\n"
	msg_input: .asciz "digite um valor:"
.text
_start:

	mov $msg_input, %rdi
	mov num, %rsi
	call printf
	
	mov $fmt, %rdi
	mov $num, %rsi
	call scanf
	
	mov $msg, %rdi
	mov num, %rsi
	call printf

	mov $60,%rax
	mov $0, %rdi
	syscall
 
