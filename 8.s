// Faça um algoritmo que leia um número e informe se ele é par ou ímpar.
.global main

.section .data
    msg1:   .asciz  "Type a number: "
    msg2:   .asciz  "It's odd\n"
    msg3:   .asciz  "It's even\n"
    fmt:    .asciz  "%d"

.section .bss
    .comm   num,    4

.section .text
main:
    sub $8, %rsp

    // Printf
    lea msg1(%rip), %rdi
    xor %rax, %rax
    call printf

    // Scanf
    lea fmt(%rip), %rdi
    lea num(%rip), %rsi
    xor %rax, %rax
    call scanf

    // div
    mov num(%rip), %eax
    mov $2, %ecx
    idiv %ecx

    // if
    cmp $0, %edx
    je even
odd:
    lea msg2(%rip), %rdi
    jmp finish
even:
    lea msg3(%rip), %rdi
finish:
    xor %rax, %rax
    call printf

    // finish
    add $8, %rsp
    xor %rax, %rax
    ret
