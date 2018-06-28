BRUUUNO, atualiza_menu, pintando setas internas.

; ***** atualiza_menu *****
; essa função atualiza o menu. Para utilizar a função, faça:
; call atualiza_menu
atualiza_menu:
    push    ax
    push    bx
    push    cx
    push    dx
    push    di
	jmp		testa_seta_interna
	continua_atualiza_curto:
	jmp 	continua_atualiza
	testa_seta_interna:
	; verifica se deve pintar alguma seta interna
	mov 	ah,byte[flag_interna_old]
	mov 	al,byte[flag_interna]
	cmp		ah,al
	je		continua_atualiza_curto
	; testa se deve pintar a primeira seta interna
	mov		bh,ah
	mov		bl,al
	and		bh,00000001b
	and		bl,00000001b
	cmp 	bl,bh
	je		testa_seta_dois
	mov 	byte[cor],vermelho
	cmp		bl,0
	jne		continua_pinta_seta_1
	mov 	byte[cor],preto
	continua_pinta_seta_1:
	push 	ax
	mov		ax,[coo_seta_int_1]
	mov		bx,[coo_seta_int_1+2]
	mov		dx,-1
	call	pinta_seta
	pop		ax
	; testa se deve pintar a segunda seta interna
	testa_seta_dois:
	mov		bh,ah
	mov		bl,al
	and		bh,00000010b
	and		bl,00000010b
	cmp 	bl,bh
	je		testa_seta_tres
	mov 	byte[cor],vermelho
	cmp		bl,0
	jne		continua_pinta_seta_2
	mov 	byte[cor],preto
	continua_pinta_seta_2:
	push 	ax
	mov		ax,[coo_seta_int_2]
	mov		bx,[coo_seta_int_2+2]
	call	pinta_seta_dupla_interna
	pop		ax
	; testa se deve pintar a terceira seta interna
	testa_seta_tres:
	mov		bh,ah
	mov		bl,al
	and		bh,00000100b
	and		bl,00000100b
	cmp 	bl,bh
	je		testa_seta_quatro
	mov 	byte[cor],vermelho
	cmp		bl,0
	jne		continua_pinta_seta_3
	mov 	byte[cor],preto
	continua_pinta_seta_3:
	push 	ax
	mov		ax,[coo_seta_int_3]
	mov		bx,[coo_seta_int_3+2]
	call	pinta_seta_dupla_interna
	pop		ax
	; testa se deve pintar a quarta seta interna
	testa_seta_quatro:
	mov		bh,ah
	mov		bl,al
	and		bh,00000010b
	and		bl,00000010b
	cmp 	bl,bh
	je		testa_seta_externa
	mov 	byte[cor],vermelho
	cmp		bl,0
	jne		continua_pinta_seta_4
	mov 	byte[cor],preto
	continua_pinta_seta_4:
	push 	ax
	mov		ax,[coo_seta_int_4]
	mov		bx,[coo_seta_int_4+2]
	mov		dx,1
	call	pinta_seta
	pop		ax
	mov		byte[flag_interna_old],al
	testa_seta_externa:
	
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha da seta
; mov dx,DIRECAO
	
	
	
	
	
continua_atualiza:	
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
