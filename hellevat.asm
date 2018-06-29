; ------------------------------ Elevador 2018/01 ------------------------------
; Alunos: Bruno Teixeira Jeveaux
;         Laila Sindra Ribeiro
; Turma: 1
; -------------------------------------------------------------------------------
segment code
..start:
    mov     ax,data
    mov     ds,ax
    mov     ax,stack
    mov     ss,ax
    mov     sp,stacktop
; tabela de interrupção
    xor     ax,ax
    mov     es,ax
    mov     ax,[es:int9*4]
    mov     [offset_dos],ax
    mov     ax,[es:int9*4+2]
    mov     [cs_dos],ax
    cli
    mov     [es:int9*4+2],cs
    mov     word[es:int9*4],inttec
    sti
; salvar modo de video atual
    mov     ah,0Fh              ; captura o modo de video atual
    int     10h
    mov     [modo_anterior],al
; alterar modo de video para gráfico 640x480 16 cores
    mov     al,12h
    mov     ah,0
    int     10h
; calibração
    mov     dx,319h
    mov     al,0
    out     dx,al
    call    desenha_calibrando
    call    subir
espera:
    call    verifica_tecsaida
    cmp     byte[flag_espaco],1
    jne     espera
    call    verifica_tecsaida
    call    ajusta_4andar
    mov     byte[flag_calibrando],0
; deixa o fundo preto
    call    background
    call    desenha_menu
    mov     byte[andar_atual],4
loop_teste:
    call    atualiza_menu
    test    byte[flag_emergencia],1
    jnz     trata_emergencia
    jmp     continua_loop_teste
    trata_emergencia:   ; fica aqui enquanto não sair da emergencia
    call    parar                       ; para o motor
    test    byte[flag_emergencia],1
    jnz     trata_emergencia
    cmp     byte[direcao_movimento],0   ; se o motor estava parado mesmo, apenas segue o loop
    je      continua_loop_teste
    cmp     byte[direcao_movimento],1   ; se o motor estava subindo, manda subir e segue o loop
    jne     continua_sai_emergencia
    call    subir                       
    jmp     continua_loop_teste
    continua_sai_emergencia:
    call    descer                      ; se o motor estava descendo, manda descer e segue o loop
    continua_loop_teste:

    call    ler_botoes
    call    verifica_pedido
    cmp     byte[flag_pedidos],1
    jne     loop_teste  ; se não tiver pedidos, continua verificando
    call    atualiza_fila  ; se tiver, atualiza fila
    call    atende_pedidos ; move o motor
    call    ajusta_andar  ; lê sensor e ajusta o andar atual
    mov     al,byte[andar_atual]
    cmp     al,byte[andar_desejado] ; verifica se chegou no andar desejado
    jne     loop_teste   ; se não chegou no andar desejado, repete todo o procedimento
    cmp     byte[sensor],0
    jne     loop_teste
    ; chegou no andar desejado
    call    parar ; para o motor
    mov     byte[mov_anterior],0
    call    zera_flags ; zera as flags (interna e externa) de pedidos do andar específico
    call    ler_botoes
    call    reseta_direcoes ; tem que ser antes de verifica_pedido
    call    verifica_pedido
    cmp     byte[flag_pedidos],0
    jne     chama_delay
    mov     byte[direcao_movimento],0 ; se não há pedidos, agora tá parado
    chama_delay:
    call    atualiza_menu
    mov     al,00000001b
    mov     dx,319h
    out     dx,al           ; acende led interno
    call    delay
    mov     al,0
    out     dx,al           ; apaga led interno
    cmp     byte[vai_subir],1
    jne     verifica_se_vai_descer
    mov     byte[direcao_movimento],1
    jmp     end_loop_teste
    verifica_se_vai_descer:
    cmp     byte[vai_descer],1
    jne     end_loop_teste
    mov     byte[direcao_movimento],2
    end_loop_teste:
    mov     byte[vai_subir],0
    mov     byte[vai_descer],0
    jmp     loop_teste
    
    
    
reseta_direcoes:
    cmp     byte[andar_atual],1
    jne     continua_verifica_4_andar
    mov     byte[direcao_movimento],1
    jmp     fim_reseta_direcoes
    continua_verifica_4_andar:
    cmp     byte[andar_atual],4
    jne     continua_verifica_2_andar
    mov     byte[direcao_movimento],2
    jmp     fim_reseta_direcoes
    fim_reseta_direcoes_jump_curto:
    jmp     fim_reseta_direcoes
    continua_verifica_2_andar:
    cmp     byte[andar_atual],2
    jne     continua_verifica_3_andar
    cmp     byte[direcao_movimento],1
    je      verifica_se_ha_pedidos_acima_2
    ; se chegou aqui então ele tá descendo, tem que verificar se tem algum pedido abaixo do atual
    test    byte[flag_interna],00000001b
    jnz      fim_reseta_direcoes_jump_curto
    test    byte[flag_externa],00000001b
    jnz      fim_reseta_direcoes_jump_curto
    ; se não tiver nenhum pedido abaixo do andar atual, então tem que verificar se tem algum pedido acima (para que haja mudança de direção)
    test    byte[flag_interna],00001100b
    jnz      muda_se_ha_ce_acima_2
    test    byte[flag_externa],00111000b
    jz      fim_reseta_direcoes_jump_curto
    ; se chegou aqui, então o elevador estava descendo, não há pedidos abaixo do andar atual mas há pedidos acima, então tem que mudar de direção
    muda_se_ha_ce_acima_2:
    mov     byte[direcao_movimento],1
    jmp     fim_reseta_direcoes
    verifica_se_ha_pedidos_acima_2:
    ; se chegou aqui, então ele tá subindo, tem que verificar se tem algum pedido acima do atual
    test    byte[flag_interna],00001100b
    jnz      fim_reseta_direcoes
    test    byte[flag_externa],00111000b
    jnz      fim_reseta_direcoes
    ; se não tiver nenhum pedido acima do andar atual, então tem que verificar se tem algum pedido abaixo (para que haja mudança de direção)
    test    byte[flag_interna],00000001b
    jnz      muda_se_ha_ce_abaixo_2
    test    byte[flag_externa],00000001b
    jz      fim_reseta_direcoes
    ; se chegou aqui, então o elevador estava subindo, não há pedidos acima do andar atual mas há pedidos abaixo, então tem que mudar de direção
    muda_se_ha_ce_abaixo_2:
    mov     byte[direcao_movimento],2
    jmp     fim_reseta_direcoes

    continua_verifica_3_andar:
    cmp     byte[andar_atual],3
    jne     fim_reseta_direcoes
    cmp     byte[direcao_movimento],1
    je      verifica_se_ha_pedidos_acima_3
    ; se chegou aqui então ele tá descendo, tem que verificar se tem algum pedido abaixo do atual
    test    byte[flag_interna],00000011b
    jnz      fim_reseta_direcoes
    test    byte[flag_externa],00000111b
    jnz      fim_reseta_direcoes
    ; se não tiver nenhum pedido abaixo do andar atual, então tem que verificar se tem algum pedido acima (para que haja mudança de direção)
    test    byte[flag_interna],00001000b
    jnz      muda_se_ha_ce_acima_3
    test    byte[flag_externa],00100000b
    jz      fim_reseta_direcoes
    ; se chegou aqui, então o elevador estava descendo, não há pedidos abaixo do andar atual mas há pedidos acima, então tem que mudar de direção
    muda_se_ha_ce_acima_3:
    mov     byte[direcao_movimento],1
    jmp     fim_reseta_direcoes
    verifica_se_ha_pedidos_acima_3:
    ; se chegou aqui, então ele tá subindo, tem que verificar se tem algum pedido acima do atual
    test    byte[flag_interna],00001000b
    jnz      fim_reseta_direcoes
    test    byte[flag_externa],00100000b
    jnz      fim_reseta_direcoes
    ; se não tiver nenhum pedido acima do andar atual, então tem que verificar se tem algum pedido abaixo (para que haja mudança de direção)
    test    byte[flag_interna],00000011b
    jnz     muda_se_ha_ce_abaixo_3
    test    byte[flag_externa],00000111b
    jz      fim_reseta_direcoes
    ; se chegou aqui, então o elevador estava subindo, não há pedidos acima do andar atual mas há pedidos abaixo, então tem que mudar de direção
    muda_se_ha_ce_abaixo_3:
    mov     byte[direcao_movimento],2
    jmp     fim_reseta_direcoes

    fim_reseta_direcoes:
    ret
    
; saída do programa
sai:
    call    parar
    mov     ah,0                ; set video mode
    mov     al,[modo_anterior]  ; modo anterior
    int     10h
    ; retorna tabela de interrupção do DOS
    cli
    xor     ax,ax
    mov     es,ax
    mov     ax,[cs_dos]
    mov     [es:int9*4+2],ax
    mov     ax,[offset_dos]
    mov     [es:int9*4],ax
    sti
    ; sai
    mov     ax,4c00h
    int     21h

inttec:
    push    ax
    in      al,kb_data
    mov     byte[tecla],al
    in      al,kb_ctl
    or      al,80h
    out     kb_ctl,al
    and     al,7fh
    out     kb_ctl,al
    mov     al,eoi
    out     pictrl,al
    mov     al,byte[tecla]
    cmp     al,tec_q                ; tecla q no teclado
    ;je      sai
    je      set_saida
    jmp     continua_inttec
    set_saida:
    pop     ax
    pop     ax
    pop     ax
    jmp     sai
    mov     byte[flag_saida],1
    jmp     sai_inttec
    continua_inttec:
    ; verifica se esta calibrando
    test    byte[flag_calibrando],1
    jz      verifica_numeros
    cmp     al,tec_espaco           ; tecla espaco
    jne     sai_inttec
    mov     byte[flag_espaco],1
    jmp     sai_inttec
    ; se nao estava calibrando, verifica as teclas de numeros e botão de emergencia
    verifica_numeros:
    cmp     al,tec_esc        ; tecla esc
    je      tecla_esc
    test    byte[flag_emergencia],1 ; se esta em emergencia, não armazena chamadas
    jnz     sai_inttec
    cmp     al,byte[tec_um]         ; tecla um
    je      tecla_um
    cmp     al,byte[tec_um+1]
    je      tecla_um
    cmp     al,byte[tec_dois]       ; tecla dois
    je      tecla_dois
    cmp     al,byte[tec_dois+1]
    je      tecla_dois
    cmp     al,byte[tec_tres]       ; tecla tres
    je      tecla_tres
    cmp     al,byte[tec_tres+1]
    je      tecla_tres
    cmp     al,byte[tec_quatro]     ; tecla quatro
    je      tecla_quatro
    cmp     al,byte[tec_quatro+1]
    je      tecla_quatro
    jmp     sai_inttec
    tecla_esc:
    test    byte[flag_emergencia],1
    jz      modo_emergencia
    mov     byte[flag_emergencia],0 ; se estava em emergência, agora não está mais
    jmp     sai_inttec
    modo_emergencia:
    mov     byte[flag_emergencia],1 ; se não estava em emergência, agora está
    jmp     sai_inttec
    tecla_um:
    or      byte[flag_interna],00000001b
    jmp     sai_inttec
    tecla_dois:
    or      byte[flag_interna],00000010b
    jmp     sai_inttec
    tecla_tres:
    or      byte[flag_interna],00000100b
    jmp     sai_inttec
    tecla_quatro:
    or      byte[flag_interna],00001000b
    sai_inttec:
    pop     ax
    iret
; **************************************** Fim do programa principal ****************************************

; --------------- Procedimentos ---------------

; ***** line *****
; desenha uma linha
; push x1; push y1; push x2; push y2; call line;  (x<639, y<479)
line:
    push    bp
    mov     bp,sp
    pushf               ; coloca os flags na pilha
    push    ax
    push    bx
    push    cx
    push    dx
    push    si
    push    di
    mov     ax,[bp+10]   ; resgata os valores das coordenadas
    mov     bx,[bp+8]    ; resgata os valores das coordenadas
    mov     cx,[bp+6]    ; resgata os valores das coordenadas
    mov     dx,[bp+4]    ; resgata os valores das coordenadas
    cmp     ax,cx
    je      line2
    jb      line1
    xchg    ax,cx
    xchg    bx,dx
    jmp     line1
line2:                  ; deltax=0
    cmp     bx,dx       ;subtrai dx de bx
    jb      line3
    xchg    bx,dx       ;troca os valores de bx e dx entre eles
line3:                  ; dx > bx
    push    ax
    push    bx
    call    plot_xy
    cmp     bx,dx
    jne     line31
    jmp     fim_line
line31:
    inc     bx
    jmp     line3
line1:                  ;deltax <>0
    ; comparar módulos de deltax e deltay sabendo que cx>ax
    ; cx > ax
    push    cx
    sub     cx,ax
    mov     [deltax],cx
    pop     cx
    push    dx
    sub     dx,bx
    ja      line32
    neg     dx
line32:
    mov     [deltay],dx
    pop     dx
    push    ax
    mov     ax,[deltax]
    cmp     ax,[deltay]
    pop     ax
    jb      line5
    ; cx > ax e deltax>deltay
    push    cx
    sub     cx,ax
    mov     [deltax],cx
    pop     cx
    push    dx
    sub     dx,bx
    mov     [deltay],dx
    pop     dx
    mov     si,ax
line4:
    push    ax
    push    dx
    push    si
    sub     si,ax   ;(x-x1)
    mov     ax,[deltay]
    imul    si
    mov     si,[deltax]     ;arredondar
    shr     si,1
    ; se numerador (DX)>0 soma se <0 subtrai
    cmp     dx,0
    jl      ar1
    add     ax,si
    adc     dx,0
    jmp     arc1
ar1:
    sub     ax,si
    sbb     dx,0
arc1:
    idiv    word [deltax]
    add     ax,bx
    pop     si
    push    si
    push    ax
    call    plot_xy
    pop     dx
    pop     ax
    cmp     si,cx
    je      fim_line
    inc     si
    jmp     line4

line5:
    cmp     bx,dx
    jb      line7
    xchg    ax,cx
    xchg    bx,dx
line7:
    push    cx
    sub     cx,ax
    mov     [deltax],cx
    pop     cx
    push    dx
    sub     dx,bx
    mov     [deltay],dx
    pop     dx
    mov     si,bx
line6:
    push    dx
    push    si
    push    ax
    sub     si,bx           ;(y-y1)
    mov     ax,[deltax]
    imul    si
    mov     si,[deltay]     ;arredondar
    shr     si,1
; se numerador (DX)>0 soma se <0 subtrai
    cmp     dx,0
    jl      ar2
    add     ax,si
    adc     dx,0
    jmp     arc2
ar2:
    sub     ax,si
    sbb     dx,0
arc2:
    idiv    word [deltay]
    mov     di,ax
    pop     ax
    add     di,ax
    pop     si
    push    di
    push    si
    call    plot_xy
    pop     dx
    cmp     si,dx
    je      fim_line
    inc     si
    jmp     line6
fim_line:
    pop     di
    pop     si
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    popf
    pop     bp
    ret     8
; ##### end_line #####

; ***** plot_xy *****
plot_xy:
    push    bp
    mov     bp,sp
    pushf
    push    ax
    push    bx
    push    cx
    push    dx
    push    si
    push    di
    mov     ah,0ch
    mov     al,[cor]
    mov     bh,0
    mov     dx,479
    sub     dx,[bp+4]
    mov     cx,[bp+6]
    int     10h
    pop     di
    pop     si
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    popf
    pop     bp
    ret     4
; ##### end_plot_xy #####

; ***** cursor *****
; registrador dh (0-29) (linha)     dl (0-79) (coluna)
cursor:
    pushf
    push    ax
    push    bx
    push    dx
    mov     ah,2
    mov     bh,0
    int     10h
    pop     dx
    pop     bx
    pop     ax
    popf
    ret
; ##### end_cursor #####

; ***** caracter *****
; escreve caracter em al na posição do cursor
; cor definida na variavel cor
caracter:
    pushf
    push    ax
    push    bx
    push    cx
    push    dx
    push    si
    push    di
    push    bp
    mov     ah,9
    mov     bh,0
    mov     cx,1
    mov     bl,0ffh
    or      bl,byte[cor]
    int     10h
    pop     bp
    pop     di
    pop     si
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    popf
    ret
; ##### end_caracter #####

; ***** desenha_linhas *****
; desenha linhas a partir de posições gravadas num vetor (x11,y11,x21,y21,...,x1n,y1n,x2n,y2n), onde cada par de pontos x1i,y1i x2i,y2i indica o inicio e fim da linha
; di deve conter o endereço do vetor de posições
desenha_linhas:
    mov     cx,0
desenha_linhas_1:
    mov     ax,[di]
    add     di,2
    cmp     ax,'$'
    je      fim_desenha_linhas
    push    ax
    inc     cx
    cmp     cx,4
    jne     desenha_linhas_1
    call    line
    mov     cx,0
    jmp     desenha_linhas_1
fim_desenha_linhas:
    ret
; ##### end_desenha_linhas #####

; ***** escrever *****
; escrever algo da memoria
; di aponta para o vetor com os caracteres
escrever:
    mov     al,byte[di]
    inc     di
    cmp     al,'$'
    je      fim_escrever
    call    caracter
    inc     dl          ; ajusta a posição da coluna
    call    cursor
    jmp     escrever
fim_escrever:
    ret
; ##### fim_escrever #####

; ***** verifica_tecsaida *****
; verifica se a tecla Q foi apertada
verifica_tecsaida:
    cmp     byte[flag_saida],1
    jne     sai_verifica_tecsaida
    jmp sai
    sai_verifica_tecsaida:
    ret
; ##### end_verifica_tecsaida #####

; ***** desenha_calibrando *****
; desenha a tela de calibracao
desenha_calibrando:
    mov     byte[cor],branco_intenso
    mov     di,coo_borda
    call    desenha_linhas
    ; ajustando cursor, dh -> linha; dl -> coluna
    ; escreve calibrando
    mov     dh,4
    mov     dl,29
    call    cursor
    mov     di,str_calibrando
    call    escrever
    ; escreve aperta espaco
    mov     dh,5
    mov     dl,25
    call    cursor
    mov     di,str_apertaespaco
    call    escrever
    ; escreve sair do programa
    mov     dh,18
    mov     dl,2
    call    cursor
    mov     di,str_parasair
    call    escrever
    ; escreve projeto final
    mov     dh,20
    mov     dl,2
    call    cursor
    mov     di,str_projetofinal
    call    escrever
    ; escreve nome bruno
    mov     dh,21
    mov     dl,2
    call    cursor
    mov     di,str_nomebruno
    call    escrever
    ; escreve nome laila
    mov     dh,22
    mov     dl,2
    call    cursor
    mov     di,str_nomelaila
    call    escrever
    ret
; ##### end_desenha_calibrando #####

; ***** background *****
; deixa o fundo preto
background:
    mov     ax,0A000h           ; endereço da memoria de video
    mov     es,ax               ; ES aponta para memoria de video
    mov     dx,03C4h            ; dx = indexregister
    mov     ax,0F02h            ; INDEX = MASK MAP,
    out     dx,ax               ; escreve em todos os bitplanes.
    mov     di,0
    mov     cx,38400            ; (640 * 480)/8 = 38400
    mov     ax,000h             ; coloca preto nos bits.
    rep     stosb               ; preenche a tela
    mov     ah,4ch              ; volta
    ret
; ##### end_background #####

; ***** desenha_seta_inferior *****
; essa função desenha o botão de chamadas para descer. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha da seta
; call desenha_seta_inferior
desenha_seta_inferior:    ;led a ser aceso está em al ; mov al,LED ; call acende_button_led
    push    ax
    push    bx
    push    cx
    push    dx
    push    di
    mov     byte[cor],branco_intenso
    ; a reta subirá 20 pixels para cima e para os lados, assim:
    ; desenha a parte inferior direita da seta
    push    ax
    push    bx
    add     ax,20
    push    ax
    add     bx,20
    push    bx
    call    line ; desenha a parte inferior direita da seta
    ; desenha a parte mediana direita da seta
    push    ax
    push    bx
    sub     ax,10
    push    ax
    push    bx ; em bx já está a altura, então só push y2
    call    line ; desenha a parte mediana direita da seta
    ; desenha a parte superior direita da seta
    push    ax
    push    bx
    push    ax ; em ax já está a posição, então só push x2
    add     bx,20
    push    bx
    call    line ; desenha a parte superior direita da seta
    ; desenha a parte superior central da seta
    push    ax
    push    bx
    sub     ax,20
    push    ax
    push    bx ; em bx já está a altura, então só push y2
    call    line ; desenha a parte superior central da seta
    ; desenha a parte superior esquerda da seta
    push    ax
    push    bx
    push    ax ; em ax já está a posição, então só push x2
    sub     bx,20
    push    bx
    call    line ; desenha a parte superior esquerda da seta
    ; desenha a parte mediana esquerda da seta
    push    ax
    push    bx
    sub     ax,10
    push    ax
    push    bx ; em bx já está a altura, então só push y2
    call    line ; desenha a parte mediana esquerda da seta
    ; desenha a parte inferior esquerda da seta
    push    ax
    push    bx
    add     ax,20
    push    ax
    sub     bx,20
    push    bx
    call    line ; desenha a parte inferior esquerda da seta
    ; retorna
    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret
; ##### end_desenha_seta_inferior #####

; ***** desenha_seta_superior *****
; essa função desenha o botão de chamadas para subir. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha da seta
; call desenha_seta_superior
desenha_seta_superior:
    push    ax
    push    bx
    push    cx
    push    dx
    push    di
    mov byte[cor],branco_intenso
    ; a reta descerá 20 pixels para cima e para os lados, assim:
    ; desenha a parte inferior direita da seta
    push    ax ; push x1 para a função line
    push    bx ; push y1 para a função line
    sub     ax,20
    push    ax ; push x2 para a função line
    sub     bx,20
    push    bx ; push y2 para a função line
    call    line ; desenha a parte inferior direita da seta
    ; desenha a parte mediana direita da seta
    push    ax
    push    bx
    add     ax,10
    push    ax
    push    bx ; em bx já está a altura, então só push y2
    call    line ; desenha a parte mediana direita da seta
    ; desenha a parte superior direita da seta
    push    ax
    push    bx
    push    ax ; em ax já está a posição, então só push x2
    sub     bx,20
    push    bx
    call line ; desenha a parte superior direita da seta
    ; desenha a parte superior central da seta
    push    ax
    push    bx
    add     ax,20
    push    ax
    push    bx ; em bx já está a altura, então só push y2
    call line ; desenha a parte superior central da seta
    ; desenha a parte superior esquerda da seta
    push    ax
    push    bx
    push    ax ; em ax já está a posição, então só push x2
    add     bx,20
    push    bx
    call    line ; desenha a parte superior esquerda da seta
    ; desenha a parte mediana esquerda da seta
    push    ax
    push    bx
    add     ax,10
    push    ax
    push    bx ; em bx já está a altura, então só push y2
    call    line ; desenha a parte mediana esquerda da seta
    ; desenha a parte inferior esquerda da seta
    push    ax
    push    bx
    sub     ax,20
    push    ax
    add     bx,20
    push    bx
    call    line ; desenha a parte inferior esquerda da seta
    ; retorno
    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret
; ##### end_desenha_seta_superior #####

; ***** desenha_seta_central_interna *****
; essa função desenha o botão de chamadas para ????. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha SUPERIOR da seta
; call desenha_seta_central_interna
desenha_seta_central_interna:
    push    ax
    push    bx
    push    cx
    push    dx
    push    di

    mov byte[cor],branco_intenso
    push    ax ; guarda a coordenada X da ponta superior, pois vamos utilizá-la
    push    bx ; guarda a coordenada Y da ponta superior, pois vamos utilizá-la
    call desenha_seta_superior
    pop     bx
    pop     ax ; recupera as coordenadas x e y
    push    ax ; guarda a coordenada X da ponta superior, pois vamos utilizá-la
    push    bx ; guarda a coordenada Y da ponta superior, pois vamos utilizá-la
    sub     bx,60 ; assim teremos as coordenadas x e y da seta inferior
    call desenha_seta_inferior
    pop     bx
    pop     ax ; recupera as coordenadas x e y

    ; limpa a linha superior
    mov     byte[cor],preto
    sub     bx,20
    sub     ax,9
    push    ax ; push x1
    push    bx  ; push y1
    add     ax,18
    push    ax ; push x2
    push    bx ; push y2
    call    line
    ; limpa a linha inferior
    sub     bx,20
    push    ax ; push x1
    push    bx ; push y1
    sub     ax,18
    push    ax ; push x2
    push    bx ; push y2
    call    line
    ; retorno
    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret
; ##### fim_desenha_seta_central_interna #####

; ***** desenha_seta_central_externa *****
; essa função desenha o botão de chamadas para ????. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha SUPERIOR da seta
; call desenha_seta_central_externa
desenha_seta_central_externa:
    push    ax
    push    bx
    push    cx
    push    dx
    push    di
    mov     byte[cor],branco_intenso
    call    desenha_seta_superior
    sub     bx,84 ; assim teremos as coordenadas x e y da seta inferior
    call    desenha_seta_inferior
    ; retorno
    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret
; ##### end_desenha_seta_central_externa #####

; ***** desenha_menu *****
; desenha o menu
desenha_menu:
    mov     byte[cor],branco_intenso
    mov     di,coo_borda
    call    desenha_linhas
    ; ajustando cursor, dh -> linha; dl -> coluna
    ; escreve andar atual
    mov     dh,3
    mov     dl,4
    call    cursor
    mov     di,str_andar_atual
    call    escrever
    mov     dh,3 ; linha
    mov     dl,17 ; coluna
    call    cursor
    mov     al,'0'
    add     al,4
    call    caracter
    ; escreve estado do elevador
    mov     dh,4
    mov     dl,4
    call    cursor
    mov     di,str_estado_elevador
    call    escrever
    mov     di,str_parado
    mov     dh,4
    mov     dl,24
    call    cursor
    call    escrever
    ; escreve modo_operacao
    mov     dh,5
    mov     dl,4
    call    cursor
    mov     di,str_modo_operacao
    call    escrever
    mov     di,str_funcionando
    mov     dh,5
    mov     dl,22
    call    cursor
    call    escrever
    ; escreve para sair...
    mov     dh,23
    mov     dl,3
    call    cursor
    mov     di,str_parasair
    call    escrever
    ; escreve projeto final
    mov     dh,25
    mov     dl,3
    call    cursor
    mov     di,str_projetofinal
    call    escrever
    ; escreve nome bruno
    mov     dh,26
    mov     dl,3
    call    cursor
    mov     di,str_nomebruno
    call    escrever
    ; escreve nome laila
    mov     dh,27
    mov     dl,3
    call    cursor
    mov     di,str_nomelaila
    call    escrever
    ; desenhas as linhas das casinhas
    mov     di,coo_casinhas
    call    desenha_linhas
    ; desenha as setas
    ; seta do andar 4 interna
    mov     ax,444
    mov     bx,404
    call    desenha_seta_inferior
    ; seta do andar 3 interna
    mov     ax,444
    mov     bx,362
    call    desenha_seta_central_interna
    ; seta do andar 2 interna
    mov     ax,444
    mov     bx,270
    call    desenha_seta_central_interna
    ; seta do andar 1 interna
    mov     ax,444
    mov     bx,168
    call    desenha_seta_superior
    ; seta do andar 4 externa
    mov     ax,567
    mov     bx,404
    call    desenha_seta_inferior
    ; seta do andar 3 externa
    mov     ax,567
    mov     bx,374
    call    desenha_seta_central_externa
    ; seta do andar 2 externa
    mov     ax,567
    mov     bx,282
    call    desenha_seta_central_externa
    ; seta do andar 1 externa
    mov     ax,567
    mov     bx,168
    call    desenha_seta_superior
    ; escreve chamadas internas
    mov     dh,25
    mov     dl,52
    call    cursor
    mov     di,str_chamadas
    call    escrever
    mov     dh,26
    mov     dl,52
    call    cursor
    mov     di,str_internas
    call    escrever
    ; escreve chamadas externas
    mov     dh,25
    mov     dl,67
    call    cursor
    mov     di,str_chamadas
    call    escrever
    mov     dh,26
    mov     dl,67
    call    cursor
    mov     di,str_externas
    call    escrever
    ret
; ##### end_desenha_menu #####

; ***** pinta_seta *****
; essa função pinta o botão de chamadas. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha da seta
; mov dx,DIRECAO            ; -1 para pintar seta superior e 1 para pintar seta inferior
; call pinta_seta
pinta_seta:
    push    ax
    push    bx
    push    cx
    push    dx
    push    di

    add     bx,dx
    push    ax
    push    bx
    call    plot_xy

    mov     cx,18
    mov     di,1
    pintando_seta:
    add     bx,dx
    sub     ax,di
    push    ax ; push x1
    push    bx  ; push y1

    add     ax,di
    add     ax,di
    push    ax ; push x2
    push    bx  ; push y2
    call    line
    sub     ax,di ; volta à posição central
    inc     di
    loop    pintando_seta

    mov     cx,20
    ; pinta o retângulo da seta
    pintando:
    add     bx,dx
    sub     ax,9
    push    ax ; push x1
    push    bx ; push y1
    add     ax,18
    push    ax ; push x2
    push    bx ; push y2
    sub     ax,9
    call    line
    loop    pintando

    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret
; ##### end_pinta_seta #####

; ***** pinta_seta_dupla_interna *****
; essa função pinta o botão de chamadas interna. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha SUPERIOR da seta
; call pinta_seta_dupla_interna
pinta_seta_dupla_interna:
    push    ax
    push    bx
    push    cx
    push    dx
    push    di
    mov     dx,-1
    call    pinta_seta
    sub     bx,60
    mov     dx,1
    call    pinta_seta

    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret
; ##### end_pinta_seta_dupla_interna #####

; ***** atualiza_menu *****
; essa função atualiza o menu. Para utilizar a função, faça:
; call atualiza_menu
atualiza_menu:
    push    ax
    push    bx
    push    cx
    push    dx
    push    di
    jmp     testa_seta_interna
    testa_seta_externa_curto:
    jmp     testa_seta_externa_2
    testa_seta_interna:
    ; verifica se deve pintar alguma seta interna
    mov     ah,byte[flag_interna_old]
    mov     al,byte[flag_interna]
    cmp     ah,al
    je      testa_seta_externa_curto
    ; testa se deve pintar a primeira seta interna
    mov     bh,ah
    mov     bl,al
    and     bh,00000001b
    and     bl,00000001b
    cmp     bl,bh
    je      testa_seta_dois
    mov     byte[cor],vermelho
    cmp     bl,0
    jne     continua_pinta_seta_1
    mov     byte[cor],preto
    continua_pinta_seta_1:
    push    ax
    mov     ax,[coo_seta_int_1]
    mov     bx,[coo_seta_int_1+2]
    mov     dx,-1
    call    pinta_seta
    pop     ax
    ; testa se deve pintar a segunda seta interna
    testa_seta_dois:
    mov     bh,ah
    mov     bl,al
    and     bh,00000010b
    and     bl,00000010b
    cmp     bl,bh
    je      testa_seta_tres
    mov     byte[cor],vermelho
    cmp     bl,0
    jne     continua_pinta_seta_2
    mov     byte[cor],preto
    continua_pinta_seta_2:
    push    ax
    mov     ax,[coo_seta_int_2]
    mov     bx,[coo_seta_int_2+2]
    call    pinta_seta_dupla_interna
    pop     ax
    ; testa se deve pintar a terceira seta interna
    testa_seta_tres:
    mov     bh,ah
    mov     bl,al
    and     bh,00000100b
    and     bl,00000100b
    cmp     bl,bh
    je      testa_seta_quatro
    mov     byte[cor],vermelho
    cmp     bl,0
    jne     continua_pinta_seta_3
    mov     byte[cor],preto
    continua_pinta_seta_3:
    push    ax
    mov     ax,[coo_seta_int_3]
    mov     bx,[coo_seta_int_3+2]
    call    pinta_seta_dupla_interna
    pop     ax
    ; testa se deve pintar a quarta seta interna
    testa_seta_quatro:
    mov     bh,ah
    mov     bl,al
    and     bh,00001000b
    and     bl,00001000b
    cmp     bl,bh
    je      testa_seta_externa
    mov     byte[cor],vermelho
    cmp     bl,0
    jne     continua_pinta_seta_4
    mov     byte[cor],preto
    continua_pinta_seta_4:
    push    ax
    mov     ax,[coo_seta_int_4]
    mov     bx,[coo_seta_int_4+2]
    mov     dx,1
    call    pinta_seta
    pop     ax
    testa_seta_externa:     
    mov     byte[flag_interna_old],al
    jmp     testa_seta_externa_2
    continua_atualiza_curto_2:
    jmp     continua_atualiza_2
    testa_seta_externa_2:
    ; verifica se deve pintar alguma seta externa
    mov     ah,byte[flag_externa_old]
    mov     al,byte[flag_externa]
    cmp     ah,al
    je      continua_atualiza_curto_2
    ; testa se deve pintar a primeira seta externa
    mov     bh,ah
    mov     bl,al
    and     bh,00000001b
    and     bl,00000001b
    cmp     bl,bh
    je      testa_seta_dois_ext
    mov     byte[cor],azul
    cmp     bl,0
    jne     continua_pinta_seta_1_ext
    mov     byte[cor],preto
    continua_pinta_seta_1_ext:
    push    ax
    mov     ax,[coo_seta_ext_1]
    mov     bx,[coo_seta_ext_1+2]
    mov     dx,-1
    call    pinta_seta
    pop     ax
    ; testa se deve pintar a segunda seta externa
    testa_seta_dois_ext:
    mov     bh,ah
    mov     bl,al
    and     bh,00000010b
    and     bl,00000010b
    cmp     bl,bh
    je      testa_seta_tres_ext
    mov     byte[cor],vermelho
    cmp     bl,0
    jne     continua_pinta_seta_2_ext
    mov     byte[cor],preto
    continua_pinta_seta_2_ext:
    push    ax
    mov     ax,[coo_seta_ext_2]
    mov     bx,[coo_seta_ext_2+2]
    mov     dx,1
    call    pinta_seta
    pop     ax
    ; testa se deve pintar a terceira seta externa
    testa_seta_tres_ext:
    mov     bh,ah
    mov     bl,al
    and     bh,00000100b
    and     bl,00000100b
    cmp     bl,bh
    je      testa_seta_quatro_ext
    mov     byte[cor],azul
    cmp     bl,0
    jne     continua_pinta_seta_3_ext
    mov     byte[cor],preto
    continua_pinta_seta_3_ext:
    push    ax
    mov     ax,[coo_seta_ext_3]
    mov     bx,[coo_seta_ext_3+2]
    mov     dx,-1
    call    pinta_seta
    pop     ax
    ; testa se deve pintar a quarta seta interna
    testa_seta_quatro_ext:
    mov     bh,ah
    mov     bl,al
    and     bh,00001000b
    and     bl,00001000b
    cmp     bl,bh
    je      testa_seta_cinco_ext
    mov     byte[cor],vermelho
    cmp     bl,0
    jne     continua_pinta_seta_4_ext
    mov     byte[cor],preto
    continua_pinta_seta_4_ext:
    push    ax
    mov     ax,[coo_seta_ext_4]
    mov     bx,[coo_seta_ext_4+2]
    mov     dx,1
    call    pinta_seta
    pop     ax
    testa_seta_cinco_ext:
    mov     bh,ah
    mov     bl,al
    and     bh,00010000b
    and     bl,00010000b
    cmp     bl,bh
    je      testa_seta_seis_ext
    mov     byte[cor],azul
    cmp     bl,0
    jne     continua_pinta_seta_5_ext
    mov     byte[cor],preto
    continua_pinta_seta_5_ext:
    push    ax
    mov     ax,[coo_seta_ext_5]
    mov     bx,[coo_seta_ext_5+2]
    mov     dx,-1
    call    pinta_seta
    pop     ax
    testa_seta_seis_ext:
    mov     bh,ah
    mov     bl,al
    and     bh,00100000b
    and     bl,00100000b
    cmp     bl,bh
    je      continua_atualiza
    mov     byte[cor],vermelho
    cmp     bl,0
    jne     continua_pinta_seta_6_ext
    mov     byte[cor],preto
    continua_pinta_seta_6_ext:
    push    ax
    mov     ax,[coo_seta_ext_6]
    mov     bx,[coo_seta_ext_6+2]
    mov     dx,1
    call    pinta_seta
    pop     ax
continua_atualiza:
    mov     byte[flag_externa_old],al
continua_atualiza_2:
    ; LIMPA ANDAR ANTERIOR
    mov     al,byte[andar_anterior]
    cmp     al,byte[andar_atual]
    je      checa_estado_anterior
    mov     dh,3 ; linha
    mov     dl,17 ; coluna
    call    cursor
    mov     al,'0'
    add     al,byte[andar_anterior]
    call    caracter ; quando escreve de novo ele inverte a cor (branco pra preto)
    mov     al,'0'
    add     al,byte[andar_atual]
    call    caracter
    mov     al,byte[andar_atual]
    mov     byte[andar_anterior],al
checa_estado_anterior:
    ; ESCREVE ESTADO DO ELEVADOR
    xor     ah,ah
    mov     al,byte[mov_anterior]
    ;mov     al,byte[direcao_movimento]
    cmp     al,0    ; parado
    je      escreve_parado
    cmp     al,1    ; subindo
    je      escreve_subindo
    cmp     al,2    ; descendo
    je      escreve_descendo
    cmp     al,3    ; parado
    je      escreve_parado
    escreve_parado:
    mov     di,str_parado
    jmp     termina_escrever
    escreve_subindo:
    mov     di,str_subindo
    jmp     termina_escrever
    escreve_descendo:
    mov     di,str_descendo
    termina_escrever:
    ; LIMPA ESTADO DO ELEVADOR
    mov     ax,word[ptr_str_estado_anterior]
    cmp     ax,di
    je      checa_modo_elevador
    push    di
    mov     di,word[ptr_str_estado_anterior]
    mov     dh,4
    mov     dl,24
    call    cursor
    call    escrever
    ; aqui escreve
    pop     di
    mov     word[ptr_str_estado_anterior],di    
    mov     dh,4
    mov     dl,24
    call    cursor
    call    escrever
checa_modo_elevador:
    ; ESCREVE MODO DO ELEVADOR
    mov     di,str_funcionando
    test    byte[flag_emergencia],1
    jz      termina_atualizar
    mov     di,str_emergencia ; se der 1, significa que está em emergência
    termina_atualizar:
    ; LIMPA MODO DO ELEVADOR
    mov     ax,word[ptr_str_modo_anterior]
    cmp     ax,di
    je      retorno_atualiza_menu
    push    di
    mov     di,word[ptr_str_modo_anterior]
    mov     dh,5
    mov     dl,22
    call    cursor
    call    escrever
    ; escreve o atual
    pop     di
    mov     word[ptr_str_modo_anterior],di
    mov     dh,5
    mov     dl,22
    call    cursor
    call    escrever
    ; retorno
retorno_atualiza_menu:
    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret
; ##### end_atualiza_menu #####

; ***** subir *****
; move motor para cima
subir:
    mov     byte[motoracao],1
    call    move_motor
    ret
; ##### end_subir #####

; ***** descer *****
; move motor para baixo
; call descer
descer:
    mov     byte[motoracao],2
    call    move_motor
    ret
; ##### end_descer #####

; ***** parar *****
; para o motor
parar:
    mov     byte[motoracao],0
    call    move_motor
    ret
; ##### end_parar #####

; ***** move_motor *****
; salve em motoracao o comando desejado para o motor (0 parado, 1 subida, 2 descida, 3 parado)
; mov byte[motoracao],VALOR ; call move_motor
move_motor:
    push    ax
    push    dx              ; salva o contexto;
    mov     al,byte[motoreleds]
    mov     ah,byte[motoracao]
    shl     ah,6            ; shifta o dado para termos: XX000000
    and     al,00111111b    ; zera os bits 6 e 7 dos motores para dar o comando
    or      al,ah           ; mantém os bits 0 a 5 e dá o comando desejado
    mov     byte[motoreleds],al
    mov     dx,318h
    out     dx,al
    ; recupera o contexto
    pop     dx
    pop     ax
    ret
; ##### fim_move_motor #####

; ***** ler_sensor *****
; Diz se o sensor de andar estava em buraco ou obstruido com debounce (ler 40 vezes seguidas o mesmo valor)
; call ler_sensor
ler_sensor:
    push    ax
    push    cx
    push    dx
    pushf
    xor     ah,ah
    mov     cx,40
    mov     dx,319h
    loop_leitura:
    mov     byte[sensor],ah         ; salva o último valor lido em sensor (no primeiro loop salva 0, mas não tem problema)
    in      al,dx
    mov     ah,1
    test    al,01000000b            ; supõe que é 1
    jnz     continua_ler_sensor
    mov     ah,0                    ; se for 0, coloca 0
    continua_ler_sensor:
    cmp     byte[sensor],ah
    je      leitura_igual
    mov     cx,40                   ; se a leitura não for igual 40 vezes seguidas, le de novo
    jmp     loop_leitura
    leitura_igual:
    dec     cx
    cmp     cx,0
    jne     loop_leitura
    sai_ler_sensor:
    popf
    pop     dx
    pop     cx
    pop     ax
    ret
; ##### fim_ler_sensor #####

; ***** ajusta_4andar *****
; desce enquanto o sensor estiver obstruido
; call ajusta_4andar
ajusta_4andar:
    pushf
    call    descer
    loop_ajusta:
    call    ler_sensor
    cmp     byte[sensor],0      ; se ler obstruido continua descendo
    jne     loop_ajusta
    call    parar               ; se ler buraco, para o motor no 4 andar
    ; retorno
    popf
    ret
; ##### fim_ajusta_4andar #####

; ***** ajusta_andar *****
; verifica se esta subindo ou descendo e decrementa ou incrementa o andar
; se sensor mudar de 0 para 1 e estiver descendo, decrementa o andar
; se sensor mudar de 1 para 0 e estiver subindo, incrementa o andar
; call ajusta_andar
ajusta_andar:
    push    ax
    pushf
    mov     ah,byte[sensor]     ; ah guarda a última leitura
    call    ler_sensor          ; atualiza leitura do sensor
    cmp     byte[motoracao],2   ; verifica se esta descendo
    je      descendo_ajusta
    cmp     byte[motoracao],1       ; se não esta descendo, verifica se esta subindo
    jne     retorno_ajusta          ; se não esta descendo nem subindo (parado), apenas sai da funcao
    ; se esta subindo:
    cmp     ah,0                ; se esta subindo e a ultima leitura do sensor foi 1, analisa se a leitura atual foi zero. Se a ultima leitura foi zero, sai.
    je      retorno_ajusta
    cmp     byte[sensor],0      ; se a leitura atual for 0, incrementa andar. Se for 1 ainda, sai.
    jne     retorno_ajusta
    ; como esta subindo e foi verificada transição de 1 para 0, incrementa o andar
    mov     al,byte[andar_atual]
    inc     al
    mov     byte[andar_atual],al
    jmp     retorno_ajusta
    ; se esta descendo:
    descendo_ajusta:
    cmp     ah,0                ; se esta descendo e a ultima leitura do sensor foi 0, analisa se a leitura atual foi 1. Se a ultima leitura foi 1, sai.
    jne     retorno_ajusta
    cmp     byte[sensor],0      ; se a leitura atual for 1, decrementa andar. Se for 0 ainda, sai.
    je      retorno_ajusta
    ; como esta descendo e foi verificada transição de 0 para 1, decrementa o andar
    mov     al,byte[andar_atual]
    dec     al
    mov     byte[andar_atual],al
    jmp     retorno_ajusta
    ; retorno
    retorno_ajusta:
    popf
    pop     ax
    ret
; ##### fim_ajusta_andar #####

; ***** ler_botoes *****
; le os botoes e setta flags de chamadas externas
; call ler_botoes
ler_botoes:
    push    ax
    push    cx
    push    dx
    pushf
    mov     cx,30
    mov     ah,0
    mov     dx,319h
    debouncer_le_botoes:
    in      al,dx
    cmp     ah,al
    je      continua_deb_botoes
    mov     ah,al
    mov     cx,30
    loop    debouncer_le_botoes
    continua_deb_botoes:
    loop    debouncer_le_botoes
    and     al,00111111b
    mov     dl,byte[flag_externa]
    or      dl,al
    mov     byte[flag_externa],dl
    and     dl,00111111b ; aqui tem todos os leds q devem ser acesos
    and     byte[motoreleds],11000000b ; zero os leds
    or      byte[motoreleds],dl ; renovo os leds
    mov     al,byte[motoreleds]
    mov     dx,318h
    out     dx,al
    popf
    pop     dx
    pop     cx
    pop     ax
    ret
; ##### fim_ler_botoes #####

; ***** zera_flags *****
; verifica quais chamadas atendeu
; call zera_flags
zera_flags:
    push    ax
    push    bx
    pushf
    cmp     byte[andar_atual],1
    jne     testa_andar_2
    mov     al,11111110b
    mov     bl,11111110b
    jmp     zera_chamadas
testa_andar_2:
    cmp     byte[andar_atual],2
    jne     testa_andar_3
    mov     al,11111101b


    ; se a direção do movimento do elevador era de descida, o elevador vai zerar o led de descida de qualquer maneira, independente se há ou nao chamadas para
    ; baixo. O led de subida só será zerado se não houver chamadas para baixo (porque significa que ele vai subir)
    ; se a direção do movimento do elevador era de subida, o elevador vai zerar o led de subida de qualquer maneira, independente se há ou nao chamadas para cima. O led de 
    ; descida só será zerado se não houver chamadas para cima (porque significa que ele vai descer)
    mov     bl,11111111b;
    cmp     byte[direcao_movimento],2
    jne     zera_flags_verifica_subida
    ; se chegou aqui, o elevador estava descendo
    test    byte[flag_interna],1
    jnz     zera_somente_descida_2
    test    byte[flag_externa],1
    jnz     zera_somente_descida_2
    ; se chegou aqui, é porque não tem chamada interna e nem externa abaixo do segundo andar... entao pode zerar os dois!
    jmp     zera_os_dois
    zera_somente_descida_2:
    mov     bl,11111101b
    jmp     zera_chamadas

    zera_flags_verifica_subida:
    cmp     byte[direcao_movimento],1
    jne     zera_chamadas
    ; se chegou aqui, o elevador estava subindo
    test    byte[flag_interna],00001100b
    jnz     zera_somente_subida_2
    test    byte[flag_externa],00111000b
    jnz     zera_somente_subida_2
    ; se chegou aqui, é pq nao tem chamada interna e nem externa acima do segundo andar... zera tudo!
    jmp     zera_os_dois
    zera_somente_subida_2:
    mov     bl,11111011b
    jmp     zera_chamadas
    zera_os_dois:
    mov     bl,11111001b ; zera as duas flags do segundo andar
    jmp     zera_chamadas

testa_andar_3:
    cmp     byte[andar_atual],3
    jne     testa_andar_4
    mov     al,11111011b
    mov     bh,byte[flag_externa]
    mov     bl,11100111b ; zera as duas flags do terceiro andar para calcular o novo andar desejado
    and     byte[flag_externa],bl
    call    atualiza_fila ; atualiza fila para saber se o elevador vai subir ou descer
    mov     byte[flag_externa],bh
    mov     bh,byte[andar_desejado]
    cmp     bh,byte[andar_atual]
    ja      zera_3_bsubida ; se o andar desejado está acima do atual, então o elevador vai subir... então zera botão de subida
    jb      zera_3_bdescida; se o andar desejado está abaixo do atual, então o elevador vai descer... então zera botão de descida
    ; se chegou aqui, então o elevador não tinha chamadas além dessa atual... zera os dois botões!
    mov     bl,11100111b ; zera as duas flags do terceiro andar
    jmp     zera_chamadas
    zera_3_bsubida:
    mov     bl,byte[flag_externa_old]
    mov     byte[flag_externa],bl
    mov     bl,11101111b ; zera flag de subida
    mov     byte[vai_subir],1
    jmp     zera_chamadas
    zera_3_bdescida:
    mov     bl,byte[flag_externa_old]
    mov     byte[flag_externa],bl
    mov     bl,11110111b ; zera flag de descida
    mov     byte[vai_descer],1
    jmp     zera_chamadas
testa_andar_4:  
    mov     al,11110111b
    mov     bl,11011111b
zera_chamadas:
    and     byte[flag_interna],al
    and     byte[flag_externa],bl
    popf
    pop     bx
    pop     ax
    ret
; ##### end_zera_flags #####

; ***** verifica_pedido *****
; verifica se houve algum pedido e setta a flag_pedidos
; call verifica_pedido
verifica_pedido:
    test    byte[flag_interna],00001111b ; verifica se algum botão interno foi apertado
    jnz     set_pedidos
    test    byte[flag_externa],00111111b ; verifica se algum botão externo foi apertado
    jnz     set_pedidos
    mov     byte[flag_pedidos],0
    ret
    set_pedidos:
    mov     byte[flag_pedidos],1
    ret
; ##### end_verifica_pedido #####

; ***** atende_pedidos *****
; verifica se o motor deve subir ou descer para atender um pedido e envia o movimento
; call atende_pedidos
atende_pedidos:
    push    ax
    mov     al,byte[andar_atual]
    cmp     al,byte[andar_desejado]
    ja      desce_motor
    jb      sobe_motor
    ; aqui o andar atual é igual ao andar desejado
    jmp     fim_atende
    desce_motor:
    call    descer
    mov     byte[mov_anterior],2
    mov     byte[direcao_movimento],2
    jmp     fim_atende
    sobe_motor:
    call    subir
    mov     byte[mov_anterior],1
    mov     byte[direcao_movimento],1
    fim_atende:
    pop     ax
    ret
; ##### fim_atende_pedidos #####

; ***** atualiza_fila ***** --------> ESTA INCOMPLETA
; analisa as flags de pedido e decide qual o andar_desejado que o elevador irá
; call atualiza_fila
atualiza_fila:
    jmp     verifica_ci
    verifica_ce_aux:
    jmp     verifica_ce
    verifica_ci:
    test    byte[flag_interna],00001111b ; verifica se algum botão interno foi apertado
    jz      verifica_ce_aux ; significa que não tem chamada interna. então verifica se há chamadas externas
    cmp     byte[direcao_movimento],0
    je      att_andar_des   ; se não havia chamadas anteriormente, então atende a primeira que encontrar
    jmp     verifica_descendo_subindo ; se havia chamadas, tem que verificar se o elevador estava subindo ou descendo
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
    verifica_descendo_subindo:
    cmp     byte[direcao_movimento],1 ; verifica se a direção do elevador é de subida
    jne     atende_menor_abaixo_da_atual ; se não está subindo, está descendo... procede lógica de descida
    ; se chegou aqui, então a direção é de subida. o novo andar desejado é igual ao menor das chamadas internas acima da atual
    ; nao faz sentido testar o primeiro andar, pois se o elevador está subindo e foi chamado o primeiro andar, não pode descer no meio do caminho para o segundo andar
    ; testa, então, o segundo andar:
    test    byte[flag_interna],2
    jz      verifica_ci_tres
    cmp     byte[andar_atual],2
    jae      verifica_ci_tres ; na subida tem que ser above equal, pois na subida o andar atual = 2 significa que ele já passou do segundo e tá indo pro terceiro andar
    ; se está abaixo (no primeiro andar), e há uma chamada no segundo, então atende
    mov     byte[andar_desejado],2
    jmp     verifica_ce ; segundo andar é mais prioritário que o terceiro e quarto
    verifica_ci_tres:
    test    byte[flag_interna],4
    jz      verifica_ci_quatro
    cmp     byte[andar_atual],3
    jae      verifica_ci_quatro ; na subida tem que ser above equal, pois na subida o andar atual = 3 significa que ele já passou do terceiro e tá indo pro quarto andar
    ; se está abaixo então atende
    mov     byte[andar_desejado],3
    jmp     verifica_ce ; terceiro andar é mais prioritário que o quarto
    verifica_ci_quatro:
    test    byte[flag_interna],8
    ;jz      atende_menor_abaixo_da_atual        ; se não há pedidos e deu jz aqui, então deu erro??
    jz      verifica_ce
    cmp     byte[andar_atual],4
    jae      atende_menor_abaixo_da_atual ; na subida tem que ser above equal, pois na subida o andar atual = 4 significa que ele está no quarto andar! (mudar sentido de movimento?)
    ; se está abaixo então atende
    mov     byte[andar_desejado],4 ; acho que não precisa... pois se ele tá acima do terceiro andar e subindo, já tá indo pro quarto andar. mas tá feito
    jmp     verifica_ce ; termina verificação de subida para chamadas internas
    atende_menor_abaixo_da_atual:
    ; se chegou aqui, então a direção é de descida. o novo andar desejado é igual ao menor das chamadas internas abaixo da atual (mais próximo abaixo)
    ; nao faz sentido testar o quarto andar, pois se o elevador está descendo e foi chamado o quarto andar, não pode subir no meio do caminho para o terceiro andar
    ; testa, então, o terceiro andar:
    test    byte[flag_interna],4
    jz      verifica_ci_descida_dois
    cmp     byte[andar_atual],3
    jb      verifica_ci_descida_dois ; na descida tem que ser below, pois na descida o andar atual = 3 significa que ele ainda não chegou no terceiro
    ; se está acima (no quarto andar), e há uma chamada no terceiro, então atende
    mov     byte[andar_desejado],3
    jmp     verifica_ce ; terceiro andar é mais prioritário que o segundo e primeiro
    verifica_ci_descida_dois:
    test    byte[flag_interna],2
    jz      verifica_ci_descida_um
    cmp     byte[andar_atual],2
    jb      verifica_ci_descida_um ; na descida tem que ser below, pois na descida o andar atual = 2 significa que ele ainda não chegou no segundo
    ; se está acima então atende
    mov     byte[andar_desejado],2
    jmp     verifica_ce ; segundo andar é mais prioritário que o primeiro
    verifica_ci_descida_um:
    test    byte[flag_interna],1
    jz      verifica_ce             ; se não há pedidos e deu jz aqui, deu algum erro??
    cmp     byte[andar_atual],1
    jb      verifica_ce ; na descida tem que ser below, pois na descida o andar atual = 1 significa que ele já tá indo pro primeiro! (mudar sentido de movimento?)
    ; se está acima então atende
    mov     byte[andar_desejado],1 ; acho que não precisa, pois ele já tá indo pro primeiro andar. mas tá feito
    verifica_ce:
    jmp continua_verifica_ce
    aux_fim_atualiza:
    jmp     fim_atualiza
    continua_verifica_ce:
    test    byte[flag_externa],00111111b ; verifica se algum botão externo foi apertado ; ordem dos bits: X S B6 B4 B2 B5 B3 B1 <- tá errado
    jz      aux_fim_atualiza ; significa que não tem chamada externa, então sai
    cmp     byte[direcao_movimento],0
    jne      verif_desc_sob   ; se não estava parado, verifica se tava subindo ou descendo
    test    byte[flag_interna],00001111b ; verifica se algum botão interno foi apertado. há prioridade na primeira execução
    jnz      aux_fim_atualiza   ; se havia alguma chamada interna no mesmo tempo, apenas sai e executa
    jmp     ext_att_andar_des ; se tava parado e não havia chamada interna, entao atende a primeira externa
    verif_desc_sob:
    jmp     ext_verifica_descendo_subindo ; se havia chamadas, tem que verificar se o elevador estava subindo ou descendo
    ext_att_andar_des:
    test    byte[flag_externa],1 ; B1
    jnz     ext_set_um
    test    byte[flag_externa],2 ; B2
    jnz     ext_set_dois_descendo
    test    byte[flag_externa],4 ; B3
    jnz     ext_set_dois_subindo
    test    byte[flag_externa],8 ; B4
    jnz     ext_set_tres_descendo
    test    byte[flag_externa],16 ; B5
    jnz     ext_set_tres_subindo
    test    byte[flag_externa],32 ; B6
    jnz     ext_set_quatro
    jmp     fim_atualiza
    ext_set_um:
    mov     byte[andar_desejado],1
    jmp     fim_atualiza
    ext_set_dois_descendo:
    mov     byte[andar_desejado],2
    jmp     fim_atualiza
    ext_set_dois_subindo:
    mov     byte[andar_desejado],2
    jmp     fim_atualiza
    ext_set_tres_descendo:
    mov     byte[andar_desejado],3
    jmp     fim_atualiza
    ext_set_tres_subindo:
    mov     byte[andar_desejado],3
    jmp     fim_atualiza
    ext_set_quatro:
    mov     byte[andar_desejado],4
    jmp     fim_atualiza

    ext_atende_menor_abaixo_da_atual_jump_curto:
    jmp     ext_atende_menor_abaixo_da_atual
    ext_verifica_descendo_subindo:
    cmp     byte[direcao_movimento],1 ; verifica se a direção do elevador é de subida
    jne     ext_atende_menor_abaixo_da_atual_jump_curto ; se não está subindo, está descendo... procede lógica de descida
    ; se chegou aqui, então a direção é de subida. o novo andar desejado é igual ao menor das chamadas externas acima da atual e abaixo do desejado atual (interna tem prioridade)
    ; nao faz sentido testar o primeiro andar, pois se o elevador está subindo e foi chamado o primeiro andar, não pode descer no meio do caminho para o segundo andar
    ; testa, então, o segundo andar:
    ;;;;;;;;; DESCIDA ;;;;;;;;;
    cmp     byte[andar_atual],1
    jne     ext_testa_andar_2
    test    byte[flag_interna],00001110b
    jnz     ext_continua_botoes_subida
    test    byte[flag_externa],00010100b
    jz      ext_verifica_botoes_descida

    ext_testa_andar_2:
    cmp     byte[andar_atual],2
    jne     ext_testa_andar_3
    test    byte[flag_interna],00001100b
    jnz     ext_continua_botoes_subida
    test    byte[flag_externa],00010000b
    jz      ext_verifica_botoes_descida

    ext_testa_andar_3:
    cmp     byte[andar_atual],3
    jne     ext_continua_botoes_subida
    test    byte[flag_interna],00001000b
    jnz     ext_continua_botoes_subida
    test    byte[flag_externa],00100000b
    jnz     ext_verifica_botoes_descida
    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    ext_continua_botoes_subida:
    test    byte[flag_externa],4 ; botão de subida apenas... nao se atende descida quando está subindo
    jz      verifica_ce_tres
    cmp     byte[andar_atual],2
    jae     verifica_ce_tres ; na subida tem que ser above equal, pois na subida o andar atual = 2 significa que ele já passou do segundo e tá indo pro terceiro andar
    ; se está abaixo (no primeiro andar), e há uma chamada no segundo, então atende
    mov     byte[andar_desejado],2
    jmp     fim_atualiza ; segundo andar é mais prioritário que o terceiro e quarto
    verifica_ce_tres:
    test    byte[flag_externa],16
    jz      verifica_ce_quatro
    cmp     byte[andar_atual],3
    jae     verifica_ce_quatro ; na subida tem que ser above equal, pois na subida o andar atual = 3 significa que ele já passou do terceiro e tá indo pro quarto andar
    ; se está abaixo então atende
    mov     byte[andar_desejado],3
    jmp     fim_atualiza ; terceiro andar é mais prioritário que o quarto
    verifica_ce_quatro:
    test    byte[flag_externa],32
    jz      fim_atualiza_jump_curto        ; se não há pedidos e deu jz aqui, então deu erro??
    cmp     byte[andar_atual],4
    jae     ext_atende_menor_abaixo_da_atual ; na subida tem que ser above equal, pois na subida o andar atual = 4 significa que ele está no quarto andar! (mudar sentido de movimento?)
    ; se está abaixo então atende
    jmp     fim_atualiza ; termina verificação de subida para chamadas internas
    fim_atualiza_jump_curto:
    jmp     fim_atualiza
    ext_verifica_botoes_descida:
    ; teoricamente, ele tá aqui se não há pedidos de subida e nem pedidos internos de subida
    test    byte[flag_externa],00100000b ; verifica se o botão do 4 andar tá apertado
    jz      ext_verifica_botoes_descida_andar_3
    mov     byte[andar_desejado],4
    jmp     fim_atualiza
    ext_verifica_botoes_descida_andar_3:
    test    byte[flag_externa],00001000b ; verifica se o botão do 3 andar tá apertado
    jz      ext_verifica_botoes_descida_andar_2
    mov     byte[andar_desejado],3
    jmp     fim_atualiza
    ext_verifica_botoes_descida_andar_2:
    test    byte[flag_externa],00000010b ; verifica se o botão do 2 andar tá apertado
    jz      fim_atualiza_jump_curto
    mov     byte[andar_desejado],2
    jmp     fim_atualiza
    ext_atende_menor_abaixo_da_atual:
    ; se chegou aqui, então a direção é de descida. o novo andar desejado é igual ao menor das chamadas externas abaixo da atual e acima do desejado atual (mais próximo abaixo)
    ; nao faz sentido testar o quarto andar, pois se o elevador está descendo e foi chamado o quarto andar, não pode subir no meio do caminho para o terceiro andar
    ; testa, então, o terceiro andar:
    ;;;;;;;;; SUBIDA ;;;;;;;;;
    cmp     byte[andar_atual],1
    jne     ext_testa_andar_2_outro
    test    byte[flag_interna],00000001b
    jnz     ext_continua_botoes_descida
    test    byte[flag_externa],00000001b
    jnz     ext_verifica_botoes_subida

    ext_testa_andar_2_outro:
    cmp     byte[andar_atual],2
    jne     ext_testa_andar_3_outro
    test    byte[flag_interna],00000011b
    jnz     ext_continua_botoes_descida
    test    byte[flag_externa],00000010b
    jz      ext_verifica_botoes_subida

    ext_testa_andar_3_outro:
    cmp     byte[andar_atual],3
    jne     ext_continua_botoes_descida
    test    byte[flag_interna],00000111b
    jnz     ext_continua_botoes_descida
    test    byte[flag_externa],00001010b
    jz      ext_verifica_botoes_subida
    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    ext_continua_botoes_descida:
    test    byte[flag_externa],8 ; botão de descida apenas... nao se atende subida quando o elevador está descendo
    jz      verifica_ce_descida_dois
    cmp     byte[andar_atual],3
    jb      verifica_ce_descida_dois ; na descida tem que ser below, pois na descida o andar atual = 3 significa que ele ainda não chegou no terceiro
    ; se está acima (no quarto andar), e há uma chamada no terceiro, então atende
    mov     byte[andar_desejado],3
    jmp     fim_atualiza ; terceiro andar é mais prioritário que o segundo e primeiro
    verifica_ce_descida_dois:
    test    byte[flag_externa],2
    jz      verifica_ce_descida_um
    cmp     byte[andar_atual],2
    jb      verifica_ce_descida_um ; na descida tem que ser below, pois na descida o andar atual = 2 significa que ele ainda não chegou no segundo
    ; se está acima então atende
    mov     byte[andar_desejado],2
    jmp     fim_atualiza ; segundo andar é mais prioritário que o primeiro
    verifica_ce_descida_um:
    test    byte[flag_externa],1
    jz      fim_atualiza        ; se não há pedidos e deu jz aqui, deu algum erro!
    cmp     byte[andar_atual],1
    jb      fim_atualiza ; AAAAAAAAAAAA na descida tem que ser below, pois na descida o andar atual = 1 significa que ele já tá indo pro primeiro! (mudar sentido de movimento?)
    ; se está acima então atende
    jmp     fim_atualiza ; termina verificação de subida para chamadas internas
    ext_verifica_botoes_subida:
    ; teoricamente, ele tá aqui se não há pedidos de descida e nem pedidos internos de descida
    test    byte[flag_externa],00000001b ; verifica se o botão do 1 andar tá apertado
    jz      ext_verifica_botoes_subida_andar_2
    mov     byte[andar_desejado],1
    jmp     fim_atualiza
    ext_verifica_botoes_subida_andar_2:
    test    byte[flag_externa],00000100b ; verifica se o botão do 2 andar tá apertado
    jz      ext_verifica_botoes_subida_andar_3
    mov     byte[andar_desejado],2
    jmp     fim_atualiza
    ext_verifica_botoes_subida_andar_3:
    test    byte[flag_externa],00010000b ; verifica se o botão do 3 andar tá apertado
    jz      fim_atualiza
    mov     byte[andar_desejado],3
    jmp     fim_atualiza
    fim_atualiza:
    ret
; ##### fim_atualiza_fila #####

; ***** delay *****
; delay para abertura da porta do elevador
delay:
    push    cx
    mov     cx,01010h ; <- velocidade para testes
    del2:
    push    cx
    mov     cx,0FFFFh
    del1:
    loop    del1
    pop     cx
    call    ler_botoes
    call    atualiza_menu
    loop    del2 
    pop     cx
    ret
;
; --------------- Segmento de Dados ---------------
segment data
; --------------- Variáveis para desenhar ---------------
; cores
cor     db      branco
                                    ;   I R G B COR
preto           equ     0           ;   0 0 0 0 preto
azul            equ     1           ;   0 0 0 1 azul
verde           equ     2           ;   0 0 1 0 verde
cyan            equ     3           ;   0 0 1 1 cyan
vermelho        equ     4           ;   0 1 0 0 vermelho
magenta         equ     5           ;   0 1 0 1 magenta
marrom          equ     6           ;   0 1 1 0 marrom
branco          equ     7           ;   0 1 1 1 branco
cinza           equ     8           ;   1 0 0 0 cinza
azul_claro      equ     9           ;   1 0 0 1 azul claro
verde_claro     equ     10          ;   1 0 1 0 verde claro
cyan_claro      equ     11          ;   1 0 1 1 cyan claro
rosa            equ     12          ;   1 1 0 0 rosa
magenta_claro   equ     13          ;   1 1 0 1 magenta claro
amarelo         equ     14          ;   1 1 1 0 amarelo
branco_intenso  equ     15          ;   1 1 1 1 branco intenso
; modo gráfico anterior
modo_anterior   db      0
; posicionamento, usadas por line
linha           dw      0
coluna          dw      0
deltax          dw      0
deltay          dw      0
; coordenadas de desenho - pontos a serem enviados para a função line, para evitar código looongo
coo_borda       dw      10,10,630,10,630,10,630,470,630,470,10,470,10,470,10,10,'$'
coo_casinhas    dw      384,10,384,470,507,10,507,470,384,102,630,102,384,194,630,194,384,286,630,286,384,378,630,378,'$'
coo_limpeza     dw      131,380,300,437,'$'
coo_seta_int_4  dw      444,404,'$'
coo_seta_int_3  dw      444,362,'$'
coo_seta_int_2  dw      444,270,'$'
coo_seta_int_1  dw      444,168,'$'
coo_seta_ext_1  dw      567,168,'$'
coo_seta_ext_2  dw      567,198,'$'
coo_seta_ext_3  dw      567,282,'$'
coo_seta_ext_4  dw      567,290,'$'
coo_seta_ext_5  dw      567,374,'$'
coo_seta_ext_6  dw      567,404,'$'
; --------------- Variáveis de controle --------------
motoreleds      db      00000000b   ; bits 7 e 6 são os motores 0 0 Parado; 0 1 Sobe; 1 0 Desce; 1 1 Parado
motoracao       db      0
andar_atual     db      4
andar_anterior  db      4
andar_desejado  db      4
mov_anterior    db      0           ; indica sentido de movimento do elevador 0 parado; 1 subindo; 2 descendo, sendo que se parar pra atender um andar, mas ainda tiver pedidos, não é considerado parado.
direcao_movimento db    0
vai_subir       db      0
vai_descer      db      0
; --------------- Variáveis de mensagens ---------------
str_apertaespaco    db      'Aperte ESPACO no quarto andar','$'
str_calibrando      db      'Calibrando elevador...','$'
str_nomebruno       db      'Nome: Bruno Teixeira Jeveaux','$'
str_nomelaila       db      'Nome: Laila Sindra Ribeiro','$'
str_parasair        db      'Para sair do programa, pressione Q','$'
str_projetofinal    db      'Projeto Final de Sistemas Embarcados 2018-1','$'
str_andar_atual     db      'Andar atual: ','$'
str_estado_elevador db      'Estado do elevador: ','$'
str_modo_operacao   db      'Modo de operacao: ','$'
str_chamadas        db      'Chamadas','$'
str_internas        db      'INTERNAS','$'
str_externas        db      'EXTERNAS','$'
str_parado          db      'Parado','$'
str_subindo         db      'Subindo','$'
str_descendo        db      'Descendo','$'
str_funcionando     db      'Funcionando','$'
str_emergencia      db      'Emergencia','$'
ptr_str_estado_anterior dw str_parado
ptr_str_modo_anterior   dw str_funcionando
; --------------- Leitura do sensor ---------------
sensor          db      0           ; 0 -> buraco, 1 -> ostruido
; --------------- flags ---------------
flag_calibrando db      1           ; indica que está calibrando
flag_espaco     db      0           ; indica se apertou espaco
flag_saida      db      0           ; indica se apertou Q
flag_interna    db      00000000b   ; indica se apertou algum andar interno. bit 0,1,2,3 => 1,2,3,4 andar, respectivamente.
flag_interna_old db     00000000b   ; guarda as anteriores para não pintar toda hora.
flag_externa_old db     00000000b   ; guarda as anteriores para não pintar toda hora.
flag_externa    db      00000000b   ; indica se apertou algum botao externo. bit 0,1,2,3,4,5 => s1,d2,s2,d3,s3,d4, respectivamente.
flag_emergencia db      0           ; indica se está em modo emergência
flag_pedidos    db      0           ; indica se há algum pedido
; --------------- Variáveis de interrupção ---------------
int9            equ     9h
offset_dos      resw    1
cs_dos          resw    1
kb_data         equ     60h         ; porta de leitura do teclado
kb_ctl          equ     61h         ; porta de reset para pedir nova interrupção
pictrl          equ     20h
eoi             equ     20h
p_i             dw      0           ; ponteiro p/ interrupção (qnd pressiona tecla)
tecla           resb    1
tec_q           equ     10h
tec_espaco      equ     39h
tec_um          db      02h,4fh     ; teclas 1 no teclado
tec_dois        db      03h,50h     ; teclas 2 no teclado
tec_tres        db      04h,51h     ; teclas 3 no teclado
tec_quatro      db      05h,4bh     ; teclas 4 no teclado
tec_esc         equ     01h         ; teclas esc no teclado
; --------------- Segmento da pilha ---------------
segment stack stack
    resb 512
stacktop:
