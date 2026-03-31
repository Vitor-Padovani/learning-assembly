.global main

.section .data
    num:    .long 0
    fmt:    .asciz "%d"
    msg:    .asciz "Type a number: "

.section .text

main:
    sub $8, %rsp # Stack aligment

    # Scanf
    lea fmt(%rip), %rdi
    lea num(%rip), %rsi
    xor %rax, %rax
    call scanf

    # Printf
    lea fmt(%rip), %rdi
    mov num(%rip), %rsi
    xor %rax, %rax
    call printf

    add $8, %rsp # Stack aligment
    mov $0, %rax
    ret
