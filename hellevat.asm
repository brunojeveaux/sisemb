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
    call    desenha_calibrando
    call    subir
espera:
    call    verifica_tecsaida
    cmp     byte[flag_espaco],1
    jne     espera
    call    verifica_tecsaida
    call    ajusta_4andar
	mov		byte[flag_calibrando],0
; deixa o fundo preto
    call    background
    call    desenha_menu
    mov     byte[andar_atual],4
    call    atualiza_menu

	
	
	
loop_teste:
    call    atualiza_menu
    call    verifica_tecsaida
    call    ler_botoes
    call    verifica_pedido
    cmp     byte[flag_pedidos],1
    jne     loop_teste  ; se não tiver pedidos, continua verificando
    call    atualiza_fila  ; se tiver, atualiza fila
    call    atende_pedidos ; move o motor
    jmp     loop_teste
    call    ajusta_andar  ; lê sensor e ajusta o andar atual
    mov     al,byte[andar_atual]
    cmp     al,byte[andar_desejado] ; verifica se chegou no andar desejado
    jne     loop_teste   ; se não chegou no andar desejado, repete todo o procedimento
    cmp     byte[cont_buraco],10
    jb      loop_teste
    ; chegou no andar desejado
    call    parar ; para o motor
    call    zera_flags ; zera as flags (interna e externa) de pedidos do andar específico
    jmp     loop_teste



verifica_pedido:
    test byte[flag_interna],00001111b ; verifica se algum botão interno foi apertado
    jnz set_pedidos
    test byte[flag_externa],00111111b ; verifica se algum botão externo foi apertado
    jnz set_pedidos
    mov     byte[flag_pedidos],0
    ret
    set_pedidos:
    mov     byte[flag_pedidos],1
    ret

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
	
	
	



; saída do programa
sai:
	call 	parar
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
	or		byte[flag_interna],00000001b
    jmp     sai_inttec
    tecla_dois:
	or		byte[flag_interna],00000010b
    jmp     sai_inttec
    tecla_tres:
	or		byte[flag_interna],00000100b
    jmp     sai_inttec
    tecla_quatro:
	or		byte[flag_interna],00001000b
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

    mov     byte[cor],vermelho
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
    ; LIMPA ANDAR ANTERIOR
    mov     dh,3 ; linha
    mov     dl,17 ; coluna
    call    cursor
    mov     al,'0'
    add     al,byte[andar_anterior]
    call    caracter ; quando escreve de novo ele inverte a cor (branco pra preto)
    mov     al,'0'
    add     al,byte[andar_atual]
    call    caracter
    ; LIMPA ESTADO DO ELEVADOR
    mov     di,word[ptr_str_estado_anterior]
    mov     dh,4
    mov     dl,24
    call    cursor
    call    escrever
    ; ESCREVE ESTADO DO ELEVADOR
    xor     ah,ah
    mov     al,byte[motoreleds]
    shr     ax,6
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
    mov     word[ptr_str_estado_anterior],di    
    mov     dh,4
    mov     dl,24
    call    cursor
    call    escrever
    ; LIMPA MODO DO ELEVADOR
    mov     di,word[ptr_str_modo_anterior]
    mov     dh,5
    mov     dl,22
    call    cursor
    call    escrever
    ; ESCREVE MODO DO ELEVADOR
    mov     di,str_funcionando
    test    byte[flag_emergencia],1
    jz      termina_atualizar
    mov     di,str_emergencia ; se der 1, significa que está em emergência
    termina_atualizar:
    mov     word[ptr_str_modo_anterior],di
    mov 	dh,5
    mov 	dl,22
    call 	cursor
    call 	escrever
    mov 	al,byte[andar_atual]
    mov 	byte[andar_anterior],al
    ; retorno
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
; Diz se o sensor de andar estava em buraco ou obstruido
; call ler_sensor
ler_sensor:
    push    ax
    push    dx
    pushf
    mov     dx,319h
    in      al,dx
    test    al,01000000b
    jz      sensor_0
    mov     byte[sensor],1
	jmp 	sai_ler_sensor
    sensor_0:
    mov     byte[sensor],0
	sai_ler_sensor:
    popf
    pop     dx
    pop     ax
    ret
; ##### fim_ler_sensor #####

; ***** ajusta_4andar *****
; desce enquanto não ver que o sensor da "buraco" 10 vezes seguidas
; call ajusta_4andar
ajusta_4andar:
    push    ax
    pushf
    call    descer
    xor     al,al   ; al contara numero de buracos
    xor     ah,ah   ; ah contara numero de obstruidos
    loop_ajusta:
    call    ler_sensor
    cmp     byte[sensor],0      ; se ler obstruido continua descendo
    je      buraco_ajusta4
    xor     al,al
    jmp     loop_ajusta
    buraco_ajusta4:             ; se ler buraco 20 vezes para o motor no 4 andar
    inc     al
    xor     ah,ah
    cmp     al,10
    jb      loop_ajusta
    call    parar
    ; retorno
    popf
    pop     ax
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
    call    ler_sensor
    cmp     byte[motoracao],2   ; verifica se esta descendo
    je      descendo_ajusta
    cmp     byte[motoracao],1   ; se não esta descendo, verifica se esta subindo
    jne     retorno_ajusta_curto        ; se não esta descendo nem subindo (parado), apenas sai da funcao
    ; se esta subindo:
    cmp     byte[sensor],0
    jne     verifica_obstruido
    cmp     byte[cont_obstruido],10
    jb      retorno_ajusta_curto
    ; se contou 10 ou mais obstruidos (1 com debounce), incrementa conta_buraco para contar 10 buracos (0 com debounce)
    mov     al,byte[cont_buraco]
    inc     al
    mov     byte[cont_buraco],al
    cmp     byte[cont_buraco],10
    jb      retorno_ajusta_curto
    ; como esta subindo e foi verificada transição de 1 para 0, incrementa o andar
    mov     al,byte[andar_atual]
    inc     al
    mov     byte[andar_atual],al
    mov     byte[cont_obstruido],0  ; zerar cont_obstruido
    jmp     retorno_ajusta
    ; se esta subindo e com sensor obstruido, conta 11 obstruidos (1 com debounce)
    verifica_obstruido:
    cmp     byte[cont_obstruido],10
    ja      retorno_ajusta_curto
    mov     al,byte[cont_obstruido]
    inc     al
    mov     byte[cont_obstruido],al
    retorno_ajusta_curto:
    jmp     retorno_ajusta
    ; se esta descendo:
    descendo_ajusta:
    cmp     byte[sensor],0
    je      verifica_buraco
    ;cmp     byte[cont_buraco],5
    ;jb      retorno_ajusta_curto
    ; se contou 10 ou mais buracos (0 com debounce), incrementa cont_obstruidos para contar 10 obstruidos (1 com debounce)
    mov     al,byte[cont_obstruido]
    inc     al
    mov     byte[cont_obstruido],al
    cmp     byte[cont_obstruido],10
    jb      retorno_ajusta_curto
    ; como esta descendo e foi verificada transição de 0 para 1, decrementa o andar
    mov     al,byte[andar_atual]
    dec     al
    mov     byte[andar_atual],al
    mov     byte[cont_buraco],0     ; zerar cont_buraco
    jmp     retorno_ajusta
    ; se esta descendo e com sensor no buraco, conta 11 buracos (0 com debounce)
    verifica_buraco:
    cmp     byte[cont_buraco],10
    ja      retorno_ajusta
    mov     al,byte[cont_buraco]
    inc     al
    mov     byte[cont_buraco],al
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
    push    dx
    pushf
    mov     dx,319h
    in      al,dx
	and		al,00111111b
	mov		dl,byte[flag_externa]
	or 		dl,al
	mov 	byte[flag_externa],dl
    popf
    pop     dx
    pop     ax
    ret
; ##### fim_ler_botoes #####

; ***** zera_flags *****
; verifica se atendeu a chamadas
; call zera_flags
zera_flags:
	push 	ax
	push 	bx
	pushf
	cmp 	byte[andar_atual],1
	jne 	testa_andar_2
	mov		al,11111110b
	mov		bl,11111110b
	jmp 	zera_chamadas
testa_andar_2:
	cmp 	byte[andar_atual],2
	jne 	testa_andar_3
	mov		al,11111101b
	mov		bl,11111101b
	cmp		byte[mov_anterior],1
	jne		zera_chamadas
	mov		bl,11111011b
	jmp		zera_chamadas
testa_andar_3:
	cmp 	byte[andar_atual],3
	jne 	testa_andar_4
	mov		al,11111011b
	mov		bl,11110111b
	cmp		byte[mov_anterior],1
	jne		zera_chamadas
	mov		bl,11101111b
	jmp		zera_chamadas
testa_andar_4:	
	mov		al,11110111b
zera_chamadas:
	and		byte[flag_interna],al
	and		byte[flag_externa],bl
	popf
	pop		bx
	pop		ax
	ret
; ##### end_zera_flags #####

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
; --------------- Variáveis de controle --------------
motoreleds      db      00000000b   ; bits 7 e 6 são os motores 0 0 Parado; 0 1 Sobe; 1 0 Desce; 1 1 Parado
motoracao       db      0
andar_atual     db      4
andar_anterior  db      4
andar_desejado  db      4
mov_anterior	db		0			; indica sentido de movimento do elevador 0 parado; 1 subindo; 2 descendo
; --------------- Variáveis de mensagens ---------------
str_apertaespaco    db     'Aperte ESPACO no quarto andar','$'
str_calibrando      db      'Calibrando elevador...','$'
str_nomebruno       db      'Nome: Bruno Teixeira Jeveaux','$'
str_nomelaila       db      'Nome: Laila Sindra Ribeiro','$'
str_parasair        db      'Para sair do programa, pressione Q','$'
str_projetofinal    db     'Projeto Final de Sistemas Embarcados 2018-1','$'
str_andar_atual     db      'Andar atual: ','$'
str_estado_elevador db  'Estado do elevador: ','$'
str_modo_operacao   db    'Modo de operacao: ','$'
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
entrada         db      00000000b   ; valores lidos da porta 319h (bit 6 é o sensor)
sensor          db      0           ; 0 -> buraco, 1 -> ostruido
cont_buraco     db      0           ; conta numero de buracos
cont_obstruido  db      0           ; conta numero de obstruidos
; --------------- flags ---------------
flag_calibrando db      1           ; indica que está calibrando
flag_espaco     db      0           ; indica se apertou espaco
flag_saida      db      0           ; indica se apertou Q
flag_interna    db      00000000b   ; indica se apertou algum andar interno. bit 0,1,2,3 => 1,2,3,4 andar, respectivamente.
flag_externa	db		00000000b	; indica se apertou algum botao externo. bit 0,1,2,3,4,5 => s1,d2,s2,d3,s3,d4, respectivamente.
flag_emergencia db      0           ; indica se está em modo emergência
flag_pedidos	db		0 			; indica se há algum pedido
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
