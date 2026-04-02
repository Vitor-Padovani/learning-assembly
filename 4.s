.global main

.section .data
    x:      .int 0
    y:      .int 0
    msg1:   .asciz "type a number: "
    msg2:   .asciz "div: %d\n"
    fmt_in: .asciz "%d"

.section .text

main:
    sub $8, %rsp

    lea msg1(%rip), %rdi
    xor %rax, %rax
    call printf

    lea fmt_in(%rip), %rdi
    lea x(%rip), %rsi
    xor %rax, %rax
    call scanf

    lea msg1(%rip), %rdi
    xor %rax, %rax
    call printf

    lea fmt_in(%rip), %rdi
    lea y(%rip), %rsi
    xor %rax, %rax
    call scanf

    mov x(%rip), %eax # SE COPIAR NO RAX EM VEZ DE ECX ELE INFERE QUE X NA MEMORIA É LONG E COPIA O QUE TÁ DO LADO DELE
    mov y(%rip), %ecx
    idiv %ecx

    lea msg2(%rip), %rdi
    mov %rax, %rsi
    xor %rax, %rax
    call printf

    add $8, %rsp
    xor %rax, %rax
    ret
