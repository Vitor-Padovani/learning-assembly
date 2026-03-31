.global main

.section .data
    x:      .int    0
    y:      .int    0
    msg1:    .asciz  "\ntype a number: "
    msg2:    .asciz  "\nsum: %d\n"
    fmt_in: .asciz  "%d"

.section .text

main:
    sub $8, %rsp

    # printf
    lea msg1(%rip), %rdi
    xor %rax, %rax
    call printf

    # scanf
    lea fmt_in(%rip), %rdi
    lea x(%rip), %rsi
    xor %rax, %rax
    call scanf

    # printf
    lea msg1(%rip), %rdi
    xor %rax, %rax
    call printf

    # scanf
    lea fmt_in(%rip), %rdi
    lea y(%rip), %rsi
    xor %rax, %rax
    call scanf

    mov y(%rip), %rbx
    add %rbx, x(%rip)

    # printf
    lea msg2(%rip), %rdi
    mov x(%rip), %rsi
    xor %rax, %rax
    call printf

    add $8, %rsp
    xor %rax, %rax
    ret
