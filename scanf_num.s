.global main

.section .data
num:        .long 0
fmt:        .asciz "%d"
msg:        .asciz "valor digitado: %d\n"
msg_input:  .asciz "digite um valor: "

.section .text
main:

    # printf("digite um valor:")
    lea msg_input(%rip), %rdi
    xor %rax, %rax
    call printf

    # scanf("%d", &num)
    lea fmt(%rip), %rdi
    lea num(%rip), %rsi
    xor %rax, %rax
    call scanf

    # printf("valor digitado: %d\n", num)
    lea msg(%rip), %rdi
    mov num(%rip), %esi
    xor %rax, %rax
    call printf

    mov $0, %eax
    ret
