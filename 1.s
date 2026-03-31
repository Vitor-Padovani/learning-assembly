.global main

.section .data
    num:    .long 0
    fmt_in:  .asciz "%d"
    less_out: .asciz "\npredecessor: %d\n"
    more_out: .asciz "\nsucessor: %d\n"
    msg:    .asciz "\ntype a number: "

.section .text

main:
    sub $8, %rsp

    # printf("type a number: ")
    lea msg(%rip), %rdi
    xor %rax, %rax
    call printf

    # scanf("%d", &num)
    lea fmt_in(%rip), %rdi
    lea num(%rip), %rsi
    xor %rax, %rax
    call scanf

    sub $1, num(%rip)

    # printf("numero: %d\n", num)
    lea less_out(%rip), %rdi
    mov num(%rip), %rsi
    xor %rax, %rax
    call printf

    add $2, num(%rip)

    # printf("numero: %d\n", num)
    lea more_out(%rip), %rdi
    mov num(%rip), %rsi
    xor %rax, %rax
    call printf

    add $8, %rsp
    mov $0, %eax
    ret
