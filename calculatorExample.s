# =============================================================================
# Calculadora em Assembly x86-64 (AT&T / GAS)
# Disciplina: Programacao para Interfaceamento de Hardware e Software
# UEM - Universidade Estadual de Maringa
# =============================================================================
# Convencao de alinhamento de pilha (System V AMD64 ABI):
#   - No momento do CALL, rsp deve estar alinhado em 16 bytes.
#   - O CALL empurra o endereco de retorno (8 bytes), quebrando o alinhamento.
#   - O PUSH %rbp dentro da funcao empurra mais 8 bytes -> pilha volta a 16.
#   - Logo, apos "push %rbp; mov %rsp, %rbp", rsp ja esta alinhado.
#   - Para alocar espaco local, use multiplos de 16 (ou 8 se a funcao nao
#     chamar outra funcao com SSE; use 16 para seguranca).
# =============================================================================

.global main

# -----------------------------------------------------------------------------
# Secao de dados
# -----------------------------------------------------------------------------
.section .data

    msg_operando1:  .asciz  "Digite o primeiro operando: "
    msg_operador:   .asciz  "Digite o operador (+, -, *, /, ^, c, a, !, i, r, l, p): "
    msg_operando2:  .asciz  "Digite o segundo operando: "
    msg_continuar:  .asciz  "Deseja continuar? (s/n): "

    fmt_lf_in:      .asciz  "%lf"
    fmt_char_in:    .asciz  " %c"
    fmt_result:     .asciz  "Resultado: %g\n"

    msg_div_zero:   .asciz  "Erro: divisao por zero nao e permitida.\n"
    msg_neg_sqrt:   .asciz  "Erro: raiz quadrada de numero negativo nao e permitida.\n"
    msg_inv_zero:   .asciz  "Erro: inverso de zero nao e permitido.\n"
    msg_log_inv:    .asciz  "Erro: logaritmando deve ser > 0 e base positiva diferente de 1.\n"
    msg_fat_inv:    .asciz  "Erro: fatorial exige inteiro nao-negativo.\n"
    msg_comb_inv:   .asciz  "Erro: combinacao exige inteiros nao-negativos com n >= r.\n"
    msg_arr_inv:    .asciz  "Erro: arranjo exige inteiros nao-negativos com n >= r.\n"
    msg_op_inv:     .asciz  "Erro: operador invalido.\n"

    const_one:      .double 1.0

# -----------------------------------------------------------------------------
# Secao BSS
# -----------------------------------------------------------------------------
.section .bss
    .comm   op1,       8
    .comm   op2,       8
    .comm   operador,  1
    .comm   resposta,  1

# =============================================================================
# SECAO DE TEXTO
# =============================================================================
.section .text

# -----------------------------------------------------------------------------
# fatorial: calcula n! iterativamente em aritmetica inteira
#   Entrada: xmm0 = n (double, inteiro nao-negativo)
#   Saida  : xmm0 = n! como double
#   Nao chama outras funcoes -> sem alocacao local necessaria
# -----------------------------------------------------------------------------
fatorial:
    push    %rbp
    mov     %rsp, %rbp

    cvttsd2si %xmm0, %rax      # rax = (int64) n
    cmp     $1, %rax
    jle     .fat_base           # 0! = 1! = 1

    mov     %rax, %rcx          # rcx = contador = n
    mov     $1, %rax            # rax = acumulador

.fat_loop:
    imul    %rcx, %rax          # acumulador *= contador
    dec     %rcx
    cmp     $1, %rcx
    jg      .fat_loop

    jmp     .fat_fim

.fat_base:
    mov     $1, %rax            # resultado = 1

.fat_fim:
    cvtsi2sd %rax, %xmm0        # converte resultado para double
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_soma: xmm0 = op1 + op2
# -----------------------------------------------------------------------------
op_soma:
    push    %rbp
    mov     %rsp, %rbp
    addsd   %xmm1, %xmm0
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_subtracao: xmm0 = op1 - op2
# -----------------------------------------------------------------------------
op_subtracao:
    push    %rbp
    mov     %rsp, %rbp
    subsd   %xmm1, %xmm0
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_multiplicacao: xmm0 = op1 * op2
# -----------------------------------------------------------------------------
op_multiplicacao:
    push    %rbp
    mov     %rsp, %rbp
    mulsd   %xmm1, %xmm0
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_divisao: xmm0 = op1 / op2
#   rax: 1=sucesso, 0=erro (divisao por zero)
# -----------------------------------------------------------------------------
op_divisao:
    push    %rbp
    mov     %rsp, %rbp

    xorpd   %xmm2, %xmm2
    ucomisd %xmm2, %xmm1       # op2 == 0.0?
    jne     .div_ok

    lea     msg_div_zero(%rip), %rdi
    xor     %rax, %rax
    call    printf
    xor     %rax, %rax
    jmp     .div_fim

.div_ok:
    divsd   %xmm1, %xmm0
    mov     $1, %rax

.div_fim:
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_exponenciacao: xmm0 = pow(op1, op2)  (usa libc)
# -----------------------------------------------------------------------------
op_exponenciacao:
    push    %rbp
    mov     %rsp, %rbp
    # Ao entrar aqui: rsp esta em 16n (push rbp = -8 de call, +8 de push = ok)
    call    pow
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_raiz: xmm0 = sqrt(op1)
#   rax: 1=sucesso, 0=erro (negativo)
# -----------------------------------------------------------------------------
op_raiz:
    push    %rbp
    mov     %rsp, %rbp

    xorpd   %xmm1, %xmm1
    ucomisd %xmm0, %xmm1       # 0.0 vs op1: se 0 < op1, jbe nao pula
    jbe     .raiz_ok

    lea     msg_neg_sqrt(%rip), %rdi
    xor     %rax, %rax
    call    printf
    xor     %rax, %rax
    jmp     .raiz_fim

.raiz_ok:
    sqrtsd  %xmm0, %xmm0
    mov     $1, %rax

.raiz_fim:
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_inverso: xmm0 = 1.0 / op1
#   rax: 1=sucesso, 0=erro (op1==0)
# -----------------------------------------------------------------------------
op_inverso:
    push    %rbp
    mov     %rsp, %rbp

    xorpd   %xmm1, %xmm1
    ucomisd %xmm1, %xmm0       # op1 == 0?
    jne     .inv_ok

    lea     msg_inv_zero(%rip), %rdi
    xor     %rax, %rax
    call    printf
    xor     %rax, %rax
    jmp     .inv_fim

.inv_ok:
    movsd   const_one(%rip), %xmm1
    divsd   %xmm0, %xmm1       # 1.0 / op1
    movsd   %xmm1, %xmm0
    mov     $1, %rax

.inv_fim:
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_logaritmo: xmm0 = log_base(op1) = ln(op1)/ln(base)
#   Entrada: xmm0=op1 (logaritmando), xmm1=op2 (base)
#   rax: 1=sucesso, 0=erro
#   Aloca 16 bytes para salvar op1 e op2 antes de chamar log()
# -----------------------------------------------------------------------------
op_logaritmo:
    push    %rbp
    mov     %rsp, %rbp
    sub     $16, %rsp           # espaco para salvar op1 (8) e op2 (8)

    movsd   %xmm0, -8(%rbp)    # salva op1
    movsd   %xmm1, -16(%rbp)   # salva op2 (base)

    # Valida op1 > 0
    xorpd   %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jbe     .log_erro

    # Valida base > 0
    ucomisd %xmm2, %xmm1
    jbe     .log_erro

    # Valida base != 1.0
    movsd   const_one(%rip), %xmm3
    ucomisd %xmm3, %xmm1
    je      .log_erro

    # ln(op1)
    movsd   -8(%rbp), %xmm0
    call    log
    movsd   %xmm0, -8(%rbp)    # salva ln(op1)

    # ln(base)
    movsd   -16(%rbp), %xmm0
    call    log                 # xmm0 = ln(base)

    # resultado = ln(op1) / ln(base)
    movsd   -8(%rbp), %xmm1
    divsd   %xmm0, %xmm1
    movsd   %xmm1, %xmm0

    mov     $1, %rax
    jmp     .log_fim

.log_erro:
    lea     msg_log_inv(%rip), %rdi
    xor     %rax, %rax
    call    printf
    xor     %rax, %rax

.log_fim:
    mov     %rbp, %rsp
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_fatorial: wrapper com validacao + chamada a fatorial
#   Entrada: xmm0 = n
#   rax: 1=sucesso, 0=erro (n<0 ou nao inteiro)
# -----------------------------------------------------------------------------
op_fatorial:
    push    %rbp
    mov     %rsp, %rbp
    sub     $16, %rsp

    movsd   %xmm0, -8(%rbp)    # salva n

    # n >= 0?
    xorpd   %xmm1, %xmm1
    ucomisd %xmm1, %xmm0
    jb      .fat_op_erro

    # n e inteiro? (trunc(n) == n)
    call    trunc
    movsd   -8(%rbp), %xmm1
    ucomisd %xmm1, %xmm0
    jne     .fat_op_erro

    movsd   -8(%rbp), %xmm0
    call    fatorial
    mov     $1, %rax
    jmp     .fat_op_fim

.fat_op_erro:
    lea     msg_fat_inv(%rip), %rdi
    xor     %rax, %rax
    call    printf
    xor     %rax, %rax

.fat_op_fim:
    mov     %rbp, %rsp
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_combinacao: C(n,r) = n! / (r! * (n-r)!)
#   Entrada: xmm0=n, xmm1=r
#   rax: 1=sucesso, 0=erro
# -----------------------------------------------------------------------------
op_combinacao:
    push    %rbp
    mov     %rsp, %rbp
    push    %r12               # callee-saved: r12 = n
    push    %r13               # callee-saved: r13 = r
    sub     $16, %rsp          # espaco local: -8(rbp)=n!, -16(rbp)=r!

    # Armazena n e r em r12/r13 via pilha
    movsd   %xmm0, -8(%rbp)   # usa como temporario para validacao
    movsd   %xmm1, -16(%rbp)

    # n >= 0?
    xorpd   %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jb      .comb_erro

    # r >= 0?
    ucomisd %xmm2, %xmm1
    jb      .comb_erro

    # n e inteiro?
    call    trunc
    movsd   -8(%rbp), %xmm1
    ucomisd %xmm1, %xmm0
    jne     .comb_erro

    # r e inteiro?
    movsd   -16(%rbp), %xmm0
    call    trunc
    movsd   -16(%rbp), %xmm1
    ucomisd %xmm1, %xmm0
    jne     .comb_erro

    # n >= r?
    movsd   -8(%rbp), %xmm0
    movsd   -16(%rbp), %xmm1
    ucomisd %xmm0, %xmm1      # r vs n
    ja      .comb_erro

    # Converte para inteiros em r12 e r13
    movsd   -8(%rbp), %xmm0
    cvttsd2si %xmm0, %r12     # r12 = n
    movsd   -16(%rbp), %xmm0
    cvttsd2si %xmm0, %r13     # r13 = r

    # Calcula n!
    cvtsi2sd %r12, %xmm0
    call    fatorial
    movsd   %xmm0, -8(%rbp)   # salva n!

    # Calcula r!
    cvtsi2sd %r13, %xmm0
    call    fatorial
    movsd   %xmm0, -16(%rbp)  # salva r!

    # Calcula (n-r)!
    mov     %r12, %rax
    sub     %r13, %rax         # rax = n - r
    cvtsi2sd %rax, %xmm0
    call    fatorial           # xmm0 = (n-r)!

    # C(n,r) = n! / (r! * (n-r)!)
    movsd   -16(%rbp), %xmm1  # xmm1 = r!
    mulsd   %xmm0, %xmm1      # xmm1 = r! * (n-r)!
    movsd   -8(%rbp), %xmm0   # xmm0 = n!
    divsd   %xmm1, %xmm0

    mov     $1, %rax
    jmp     .comb_fim

.comb_erro:
    lea     msg_comb_inv(%rip), %rdi
    xor     %rax, %rax
    call    printf
    xor     %rax, %rax

.comb_fim:
    add     $16, %rsp
    pop     %r13
    pop     %r12
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_arranjo: A(n,r) = n! / (n-r)!
#   Entrada: xmm0=n, xmm1=r
#   rax: 1=sucesso, 0=erro
# -----------------------------------------------------------------------------
op_arranjo:
    push    %rbp
    mov     %rsp, %rbp
    push    %r12
    push    %r13
    sub     $16, %rsp

    movsd   %xmm0, -8(%rbp)
    movsd   %xmm1, -16(%rbp)

    # n >= 0?
    xorpd   %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jb      .arr_erro

    # r >= 0?
    ucomisd %xmm2, %xmm1
    jb      .arr_erro

    # n e inteiro?
    call    trunc
    movsd   -8(%rbp), %xmm1
    ucomisd %xmm1, %xmm0
    jne     .arr_erro

    # r e inteiro?
    movsd   -16(%rbp), %xmm0
    call    trunc
    movsd   -16(%rbp), %xmm1
    ucomisd %xmm1, %xmm0
    jne     .arr_erro

    # n >= r?
    movsd   -8(%rbp), %xmm0
    movsd   -16(%rbp), %xmm1
    ucomisd %xmm0, %xmm1
    ja      .arr_erro

    movsd   -8(%rbp), %xmm0
    cvttsd2si %xmm0, %r12     # r12 = n
    movsd   -16(%rbp), %xmm0
    cvttsd2si %xmm0, %r13     # r13 = r

    # Calcula n!
    cvtsi2sd %r12, %xmm0
    call    fatorial
    movsd   %xmm0, -8(%rbp)   # salva n!

    # Calcula (n-r)!
    mov     %r12, %rax
    sub     %r13, %rax
    cvtsi2sd %rax, %xmm0
    call    fatorial           # xmm0 = (n-r)!

    # A(n,r) = n! / (n-r)!
    movsd   -8(%rbp), %xmm1   # xmm1 = n!
    divsd   %xmm0, %xmm1
    movsd   %xmm1, %xmm0

    mov     $1, %rax
    jmp     .arr_fim

.arr_erro:
    lea     msg_arr_inv(%rip), %rdi
    xor     %rax, %rax
    call    printf
    xor     %rax, %rax

.arr_fim:
    add     $16, %rsp
    pop     %r13
    pop     %r12
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# eh_primo: testa se n e primo por tentativa de divisao ate sqrt(n)
#   Entrada: rdi = n
#   Saida  : rax = 1 (primo) ou 0 (nao primo)
#   Usa r12 e r13 (callee-saved)
# -----------------------------------------------------------------------------
eh_primo:
    push    %rbp
    mov     %rsp, %rbp
    push    %r12
    push    %r13

    cmp     $2, %rdi
    jl      .ep_nao_primo      # n < 2: nao primo
    cmp     $2, %rdi
    je      .ep_primo           # n == 2: primo

    # Par > 2: nao e primo
    test    $1, %rdi
    jz      .ep_nao_primo

    mov     %rdi, %r13         # r13 = n
    mov     $3, %r12           # r12 = divisor atual = 3

.ep_loop:
    mov     %r12, %rax
    imul    %r12, %rax         # rax = divisor^2
    cmp     %r13, %rax
    jg      .ep_primo           # divisor^2 > n: e primo

    mov     %r13, %rax
    xor     %rdx, %rdx
    div     %r12               # rdx = n % divisor
    test    %rdx, %rdx
    jz      .ep_nao_primo      # divisivel: nao e primo

    add     $2, %r12           # proximo divisor impar
    jmp     .ep_loop

.ep_primo:
    mov     $1, %rax
    jmp     .ep_fim
.ep_nao_primo:
    xor     %rax, %rax
.ep_fim:
    pop     %r13
    pop     %r12
    pop     %rbp
    ret

# -----------------------------------------------------------------------------
# op_proximo_primo: proximo primo >= n
#   Entrada: xmm0 = n
#   Saida  : xmm0 = resultado
# -----------------------------------------------------------------------------
op_proximo_primo:
    push    %rbp
    mov     %rsp, %rbp
    push    %r12
    push    %r13               # empurra 2 callee-saved: pilha alinhada

    call    ceil               # xmm0 = ceil(n)
    cvttsd2si %xmm0, %r12     # r12 = candidato inteiro

    cmp     $2, %r12
    jge     .pp_testa
    mov     $2, %r12           # candidato minimo = 2

.pp_testa:
    mov     %r12, %rdi
    call    eh_primo
    test    %rax, %rax
    jnz     .pp_achou

    inc     %r12
    jmp     .pp_testa

.pp_achou:
    cvtsi2sd %r12, %xmm0

    pop     %r13
    pop     %r12
    pop     %rbp
    ret

# =============================================================================
# PROCEDIMENTOS DE ENTRADA/SAIDA
# =============================================================================

# Le um double via scanf e armazena em op1; retorna valor em xmm0
ler_operando:
    push    %rbp
    mov     %rsp, %rbp
    lea     fmt_lf_in(%rip), %rdi
    lea     op1(%rip), %rsi
    xor     %rax, %rax
    call    scanf
    movsd   op1(%rip), %xmm0
    pop     %rbp
    ret

# Exibe prompt, le um double, armazena em op2 e retorna em xmm0
ler_segundo_operando:
    push    %rbp
    mov     %rsp, %rbp
    lea     msg_operando2(%rip), %rdi
    xor     %rax, %rax
    call    printf
    lea     fmt_lf_in(%rip), %rdi
    lea     op2(%rip), %rsi
    xor     %rax, %rax
    call    scanf
    movsd   op2(%rip), %xmm0
    pop     %rbp
    ret

# Exibe o double em xmm0 no formato "Resultado: %g\n"
exibir_resultado:
    push    %rbp
    mov     %rsp, %rbp
    lea     fmt_result(%rip), %rdi
    mov     $1, %rax           # 1 argumento SSE para printf
    call    printf
    pop     %rbp
    ret

# =============================================================================
# FUNCAO PRINCIPAL
# =============================================================================
main:
    push    %rbp
    mov     %rsp, %rbp
    push    %r12               # callee-saved (reservado para uso futuro)
    push    %r13               # push par -> pilha ainda alinhada em 16

.main_loop:

    # Le e exibe prompt do primeiro operando
    lea     msg_operando1(%rip), %rdi
    xor     %rax, %rax
    call    printf

    call    ler_operando
    movsd   %xmm0, op1(%rip)

    # Le e exibe prompt do operador
    lea     msg_operador(%rip), %rdi
    xor     %rax, %rax
    call    printf

    lea     fmt_char_in(%rip), %rdi
    lea     operador(%rip), %rsi
    xor     %rax, %rax
    call    scanf

    movzbl  operador(%rip), %eax   # rax = char do operador

    # Despacho baseado no operador lido
    cmp     $'+', %eax
    je      .caso_soma
    cmp     $'-', %eax
    je      .caso_subtracao
    cmp     $'*', %eax
    je      .caso_multiplicacao
    cmp     $'/', %eax
    je      .caso_divisao
    cmp     $'^', %eax
    je      .caso_exponenciacao
    cmp     $'c', %eax
    je      .caso_combinacao
    cmp     $'a', %eax
    je      .caso_arranjo
    cmp     $'l', %eax
    je      .caso_logaritmo
    cmp     $'!', %eax
    je      .caso_fatorial
    cmp     $'i', %eax
    je      .caso_inverso
    cmp     $'r', %eax
    je      .caso_raiz
    cmp     $'p', %eax
    je      .caso_primo

    # Operador desconhecido
    lea     msg_op_inv(%rip), %rdi
    xor     %rax, %rax
    call    printf
    jmp     .main_pergunta

    # ------ Operacoes binarias ------

.caso_soma:
    call    ler_segundo_operando
    movsd   op1(%rip), %xmm0
    movsd   op2(%rip), %xmm1
    call    op_soma
    call    exibir_resultado
    jmp     .main_pergunta

.caso_subtracao:
    call    ler_segundo_operando
    movsd   op1(%rip), %xmm0
    movsd   op2(%rip), %xmm1
    call    op_subtracao
    call    exibir_resultado
    jmp     .main_pergunta

.caso_multiplicacao:
    call    ler_segundo_operando
    movsd   op1(%rip), %xmm0
    movsd   op2(%rip), %xmm1
    call    op_multiplicacao
    call    exibir_resultado
    jmp     .main_pergunta

.caso_divisao:
    call    ler_segundo_operando
    movsd   op1(%rip), %xmm0
    movsd   op2(%rip), %xmm1
    call    op_divisao
    test    %rax, %rax
    jz      .main_pergunta
    call    exibir_resultado
    jmp     .main_pergunta

.caso_exponenciacao:
    call    ler_segundo_operando
    movsd   op1(%rip), %xmm0
    movsd   op2(%rip), %xmm1
    call    op_exponenciacao
    call    exibir_resultado
    jmp     .main_pergunta

.caso_combinacao:
    call    ler_segundo_operando
    movsd   op1(%rip), %xmm0
    movsd   op2(%rip), %xmm1
    call    op_combinacao
    test    %rax, %rax
    jz      .main_pergunta
    call    exibir_resultado
    jmp     .main_pergunta

.caso_arranjo:
    call    ler_segundo_operando
    movsd   op1(%rip), %xmm0
    movsd   op2(%rip), %xmm1
    call    op_arranjo
    test    %rax, %rax
    jz      .main_pergunta
    call    exibir_resultado
    jmp     .main_pergunta

.caso_logaritmo:
    call    ler_segundo_operando
    movsd   op1(%rip), %xmm0
    movsd   op2(%rip), %xmm1
    call    op_logaritmo
    test    %rax, %rax
    jz      .main_pergunta
    call    exibir_resultado
    jmp     .main_pergunta

    # ------ Operacoes unarias ------

.caso_fatorial:
    movsd   op1(%rip), %xmm0
    call    op_fatorial
    test    %rax, %rax
    jz      .main_pergunta
    call    exibir_resultado
    jmp     .main_pergunta

.caso_inverso:
    movsd   op1(%rip), %xmm0
    call    op_inverso
    test    %rax, %rax
    jz      .main_pergunta
    call    exibir_resultado
    jmp     .main_pergunta

.caso_raiz:
    movsd   op1(%rip), %xmm0
    call    op_raiz
    test    %rax, %rax
    jz      .main_pergunta
    call    exibir_resultado
    jmp     .main_pergunta

.caso_primo:
    movsd   op1(%rip), %xmm0
    call    op_proximo_primo
    call    exibir_resultado

    # Pergunta se o usuario deseja continuar
.main_pergunta:
    lea     msg_continuar(%rip), %rdi
    xor     %rax, %rax
    call    printf

    lea     fmt_char_in(%rip), %rdi
    lea     resposta(%rip), %rsi
    xor     %rax, %rax
    call    scanf

    movzbl  resposta(%rip), %eax
    cmp     $'s', %eax
    je      .main_loop         # 's' = continuar

    # Qualquer outra resposta encerra
    pop     %r13
    pop     %r12
    pop     %rbp
    xor     %rax, %rax
    ret
