.global main

.section .data
    msg:    .asciz "Hello, world!\n"

.section .text
main:
    lea msg(%rip), %rdi
    xor %rax, %rax
    call printf

    mov $0, %eax
    ret
