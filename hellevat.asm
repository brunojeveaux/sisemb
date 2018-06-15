loop_teste:
    ;call    verifica_tecsaida
    call    ler_botoes
    call    verifica_pedido
    cmp     byte[pedidos],1
    jne     loop_teste  ; se não tiver pedidos, continua verificando
    call    atualiza_fila  ; se tiver, atualiza fila
    atendendo_pedidos:
    call    atende_pedidos ; move o motor
    call    ajusta_andar  ; lê botões e sensores e ajusta o andar atual
    mov     ax,byte[andar_atual]
    cmp     ax,byte[andar_desejado] ; verifica se chegou no andar desejado
    jne     loop_teste   ; se não chegou no andar desejado, repete todo o procedimento
    ; chegou no andar desejado
    call    parar ; para o motor
    call    zera_flags ; zera as flags (interna e externa) de pedidos do andar específico
    jmp     loop_teste



verifica_pedido:
    test byte[flag_interna],00001111b ; verifica se algum botão interno foi apertado
    jnz set_pedidos
    test byte[flag_externa],00111111b ; verifica se algum botão externo foi apertado
    jnz set_pedidos
    mov     byte[pedidos],0
    ret
    set_pedidos:
    mov     byte[pedidos],1
    ret

atende_pedidos:
    push    ax
    mov     ax,byte[andar_atual]
    cmp     ax,byte[andar_desejado]
    ja      desce_motor
    jb      sobe_motor
    ; aqui o andar atual é igual ao andar desejado
    jmp     fim_atende
    desce_motor:
    call    descer
    jmp     fim_atende
    sobe_motor:
    call    subir
    fim_atende:
    pop ax
    ret

atualiza_fila:
    cmp     byte[motoracao],0
    je      verifica_ci
    jmp     fim_atualiza ; se não estava parado, tem que verificar se está subindo ou descendo
    verifica_ci:
    test byte[flag_interna],00001111b ; verifica se algum botão interno foi apertado
    jz      fim_atualiza ; significa que não tem chamada interna. então verifica se há chamadas externas
    cmp     byte[mov_anterior],0
    je      att_andar_des   ; elevador está parado e não havia chamadas anteriormente, então atende a primeira que encontrar
    jmp     fim_atualiza ; se havia chamadas, tem que verificar se o elevador estava subindo ou descendo
    att_andar_des:
    test    byte[flag_interna],1
    jnz     set_um
    test    byte[flag_interna],2
    jnz     set_dois
    test    byte[flag_interna],4
    jnz     set_tres
    test    byte[flag_interna],8
    jnz     set_quatro
    jmp     fim_atualiza
    set_um:
    mov     byte[andar_desejado],1
    jmp     fim_atualiza
    set_dois:
    mov     byte[andar_desejado],2
    jmp     fim_atualiza
    set_tres:
    mov     byte[andar_desejado],3
    jmp     fim_atualiza
    set_quatro:
    mov     byte[andar_desejado],4
    jmp     fim_atualiza
    fim_atualiza:
    ret
