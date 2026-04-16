// Faça um programa que receba um valor inteiro, calcule e mostre seu fatorial
.global main

.section .data
    msg1:   .asciz  "Type a number: "
    fmt:    .asciz  "%d"

.section .bss
    .comm   num,    8

.section .text
factorial:
    push %rbp
    mov %rsp, %rbp
    
    mov %rdi, %rax
loop:
    sub $1, %rdi

    mul %rdi

    cmp $1, %rdi
    jg loop
end_loop:

    mov %rbp, %rsp
    pop %rbp
    ret
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

    // Factorial
    mov num(%rip), %rdi
    call factorial

    // Printf
    lea fmt(%rip), %rdi
    mov %rax, %rsi
    xor %rax, %rax
    call printf

    // finish
    add $8, %rsp
    xor %rax, %rax
    ret
