.global main

.section .data
num:        .quad 0
msg_in:     .asciz "digite o valor de a: "
fmt:        .asciz "%lld"
msg_out:    .asciz "resultado: %lld\n"

.section .text
main:
    sub $8, %rsp          # alinha o stack em 16 bytes

    # printf("digite o valor de num:")
    lea msg_in(%rip), %rdi
    xor %rax, %rax
    call printf

    # scanf("%lld", &num)
    lea fmt(%rip), %rdi
    lea num(%rip), %rsi
    xor %rax, %rax
    call scanf

    # carregar num em rax
    mov num(%rip), %rax

    # if (num < 0)
    cmp $0, %rax
    jl bloco_if

    # else: num = -num
    imul $-1, %rax # neg %rax
    jmp fim_if

bloco_if:
    # num = 3*num + 1
    imul $3, %rax
    add $1, %rax

fim_if:
    # printf
    lea msg_out(%rip), %rdi
    mov %rax, %rsi
    xor %rax, %rax
    call printf

    add $8, %rsp          # restaura o stack
    mov $0, %eax
    ret