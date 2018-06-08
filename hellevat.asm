; ------------------------------ Elevador 2018/01 ------------------------------
; Alunos: Bruno Teixeira Jeveaux
;		  Laila Sindra Ribeiro
; Turma: 1
; -------------------------------------------------------------------------------
segment code
..start:
	mov		ax,data
	mov		ds,ax
	mov		ax,stack
	mov		ss,ax
	mov		sp,stacktop
; tabela de interrupção
	xor 	ax,ax
	mov		es,ax
	mov 	ax,[es:int9*4]
	mov 	[offset_dos],ax
	mov		ax,[es:int9*4+2]
	mov		[cs_dos],ax
	cli
	mov 	[es:int9*4+2],cs
	mov 	word[es:int9*4],inttec
	sti
; salvar modo de video atual
	mov  	ah,0Fh				; captura o modo de video atual
	int  	10h
	mov  	[modo_anterior],al
; alterar modo de video para gráfico 640x480 16 cores
    mov     al,12h
   	mov    	ah,0
    int    	10h
; calibração
	call 	desenha_calibrando
espera:
	cmp		byte[flag_espaco],1
	je		modo_operacao
	jmp 	espera
modo_operacao:
	mov		byte[flag_calibrando],0
; deixa o fundo preto
	call 	background


	mov ax,444
	mov bx,404
	call desenha_seta_inferior

	mov ax,444
	mov bx,362
	call desenha_seta_central_interna

	mov ax,444
	mov bx,270
	call desenha_seta_central_interna

	mov ax,444
	mov bx,168
	call desenha_seta_superior

	mov ax,567
	mov bx,404
	call desenha_seta_inferior

	mov ax,567
	mov bx,362
	call desenha_seta_central_interna

	mov ax,567
	mov bx,270
	call desenha_seta_central_interna

	mov ax,567
	mov bx,168
	call desenha_seta_superior

loop_teste:
	cmp		byte[flag_dois],1
	je		sai
	jmp 	loop_teste






; saída do programa
sai:
	mov  	ah,0   				; set video mode
	mov  	al,[modo_anterior] 	; modo anterior
	int  	10h
	; retorna tabela de interrupção do DOS
	cli
	xor 	ax,ax
	mov		es,ax
	mov 	ax,[cs_dos]
	mov 	[es:int9*4+2],ax
	mov 	ax,[offset_dos]
	mov 	[es:int9*4],ax
	sti
	; sai
	mov     ax,4c00h
	int     21h

inttec:
	push	ax
	in 		al,kb_data
	mov		byte[tecla],al
	in		al,kb_ctl
	or 		al,80h
	out		kb_ctl,al
	and		al,7fh
	out		kb_ctl,al
	mov		al,eoi
	out 	pictrl,al
	mov 	al,byte[tecla]
	cmp		al,tec_q				; tecla q no teclado
	je		sai
	; verifica se esta calibrando
	test	byte[flag_calibrando],1
	jz		verifica_numeros
	cmp		al,tec_espaco			; tecla espaco
	jne		sai_inttec
	mov		byte[flag_espaco],1
	jmp		sai_inttec
	; se nao estava calibrando, verifica as teclas de numeros
	verifica_numeros:
	cmp		al,byte[tec_um]			; tecla um
	je		tecla_um
	cmp		al,byte[tec_um+1]
	je 		tecla_um
	cmp		al,byte[tec_dois]		; tecla dois
	je		tecla_dois
	cmp		al,byte[tec_dois+1]
	je 		tecla_dois
	cmp		al,byte[tec_tres]		; tecla tres
	je		tecla_tres
	cmp		al,byte[tec_tres+1]
	je 		tecla_tres
	cmp		al,byte[tec_quatro]		; tecla quatro
	je		tecla_quatro
	cmp		al,byte[tec_quatro+1]
	je 		tecla_quatro
	jmp		sai_inttec
	tecla_um:
	mov		byte[flag_um],1
	jmp 	sai_inttec
	tecla_dois:
	mov		byte[flag_dois],1
	jmp 	sai_inttec
	tecla_tres:
	mov		byte[flag_tres],1
	jmp 	sai_inttec
	tecla_quatro:
	mov		byte[flag_quatro],1
	sai_inttec:
	pop		ax
	iret
; **************************************** Fim do programa principal ****************************************

; --------------- Procedimentos ---------------

; ***** line *****
; desenha uma linha
; push x1; push y1; push x2; push y2; call line;  (x<639, y<479)
line:
	push	bp
	mov		bp,sp
	pushf               ; coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	mov		ax,[bp+10]   ; resgata os valores das coordenadas
	mov		bx,[bp+8]    ; resgata os valores das coordenadas
	mov		cx,[bp+6]    ; resgata os valores das coordenadas
	mov		dx,[bp+4]    ; resgata os valores das coordenadas
	cmp		ax,cx
	je		line2
	jb		line1
	xchg	ax,cx
	xchg	bx,dx
	jmp		line1
line2:					; deltax=0
	cmp		bx,dx  		;subtrai dx de bx
	jb		line3
	xchg	bx,dx       ;troca os valores de bx e dx entre eles
line3:					; dx > bx
	push	ax
	push	bx
	call 	plot_xy
	cmp		bx,dx
	jne		line31
	jmp		fim_line
line31:
	inc		bx
	jmp		line3
line1:					;deltax <>0
	; comparar módulos de deltax e deltay sabendo que cx>ax
	; cx > ax
	push	cx
	sub		cx,ax
	mov		[deltax],cx
	pop		cx
	push	dx
	sub		dx,bx
	ja		line32
	neg		dx
line32:
	mov		[deltay],dx
	pop		dx

	push	ax
	mov		ax,[deltax]
	cmp		ax,[deltay]
	pop		ax
	jb		line5
	; cx > ax e deltax>deltay
	push	cx
	sub		cx,ax
	mov		[deltax],cx
	pop		cx
	push	dx
	sub		dx,bx
	mov		[deltay],dx
	pop		dx
	mov		si,ax
line4:
	push	ax
	push	dx
	push	si
	sub		si,ax	;(x-x1)
	mov		ax,[deltay]
	imul	si
	mov		si,[deltax]		;arredondar
	shr		si,1
	; se numerador (DX)>0 soma se <0 subtrai
	cmp		dx,0
	jl		ar1
	add		ax,si
	adc		dx,0
	jmp		arc1
ar1:
	sub		ax,si
	sbb		dx,0
arc1:
	idiv	word [deltax]
	add		ax,bx
	pop		si
	push	si
	push	ax
	call	plot_xy
	pop		dx
	pop		ax
	cmp		si,cx
	je		fim_line
	inc		si
	jmp		line4

line5:
	cmp		bx,dx
	jb 		line7
	xchg	ax,cx
	xchg	bx,dx
line7:
	push	cx
	sub		cx,ax
	mov		[deltax],cx
	pop		cx
	push	dx
	sub		dx,bx
	mov		[deltay],dx
	pop		dx
	mov		si,bx
line6:
	push	dx
	push	si
	push	ax
	sub		si,bx			;(y-y1)
	mov		ax,[deltax]
	imul	si
	mov		si,[deltay]		;arredondar
	shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
	cmp		dx,0
	jl		ar2
	add		ax,si
	adc		dx,0
	jmp		arc2
ar2:
	sub		ax,si
	sbb		dx,0
arc2:
	idiv	word [deltay]
	mov		di,ax
	pop		ax
	add		di,ax
	pop		si
	push	di
	push	si
	call	plot_xy
	pop		dx
	cmp		si,dx
	je		fim_line
	inc		si
	jmp		line6
fim_line:
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		8
; ##### end_line #####
; ***** plot_xy *****
plot_xy:
	push	bp
	mov		bp,sp
	pushf
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	mov     ah,0ch
	mov     al,[cor]
	mov     bh,0
	mov     dx,479
	sub		dx,[bp+4]
	mov     cx,[bp+6]
	int     10h
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		4
; ##### end_plot_xy #####

; ***** cursor *****
; registrador dh (0-29)	(linha)		dl (0-79) (coluna)
cursor:
	pushf
	push 	ax
	push 	bx
	push	dx
	mov    	ah,2
	mov    	bh,0
	int    	10h
	pop		dx
	pop		bx
	pop		ax
	popf
	ret
; ##### end_cursor #####

; ***** caracter *****
; escreve caracter em al na posição do cursor
; cor definida na variavel cor
caracter:
	pushf
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	mov     ah,9
	mov     bh,0
	mov     cx,1
	mov		bl,0ffh
	or      bl,byte[cor]
	int     10h
	pop		bp
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	ret
; ##### end_caracter #####

; ***** desenha_linhas *****
; desenha linhas a partir de posições gravadas num vetor (x11,y11,x21,y21,...,x1n,y1n,x2n,y2n), onde cada par de pontos x1i,y1i x2i,y2i indica o inicio e fim da linha
; di deve conter o endereço do vetor de posições
desenha_linhas:
	mov 	cx,0
desenha_linhas_1:
	mov 	ax,[di]
	add 	di,2
	cmp		ax,'$'
	je 		fim_desenha_linhas
	push 	ax
	inc 	cx
	cmp 	cx,4
	jne 	desenha_linhas_1
	call 	line
	mov 	cx,0
	jmp 	desenha_linhas_1
fim_desenha_linhas:
	ret
; ##### end_desenha_linhas #####

; ***** escrever *****
; escrever algo da memoria
; di aponta para o vetor com os caracteres
escrever:
	mov 	al,byte[di]
	inc 	di
	cmp		al,'$'
	je		fim_escrever
	call	caracter
	inc		dl			; ajusta a posição da coluna
	call	cursor
	jmp		escrever
fim_escrever:
	ret
; ##### fim_escrever #####

; ***** desenha_calibrando *****
; pinta os pontos dentro de um retangulo; cor na variavel cor
; di deve ter deve ter o endereço de um vetor com os cantos dos retangulos, inferior esquerdo (x1,y1) e superior direito (x2,y2), a serem pintados
desenha_calibrando:
	mov		byte[cor],branco_intenso
	mov 	di,coo_borda
	call 	desenha_linhas
	; ajustando cursor, dh -> linha; dl -> coluna
	; escreve calibrando
	mov		dh,4
	mov		dl,29
	call 	cursor
	mov 	di,str_calibrando
	call 	escrever
	; escreve aperta espaco
	mov 	dh,5
	mov		dl,25
	call 	cursor
	mov 	di,str_apertaespaco
	call 	escrever
	; escreve sair do programa
	mov 	dh,18
	mov		dl,2
	call 	cursor
	mov 	di,str_parasair
	call 	escrever
	; escreve projeto final
	mov 	dh,20
	mov		dl,2
	call 	cursor
	mov 	di,str_projetofinal
	call 	escrever
	; escreve nome bruno
	mov 	dh,21
	mov		dl,2
	call 	cursor
	mov 	di,str_nomebruno
	call 	escrever
	; escreve nome laila
	mov 	dh,22
	mov		dl,2
	call 	cursor
	mov 	di,str_nomelaila
	call 	escrever
	ret
; ##### end_desenha_calibrando #####

; ***** background *****
; deixa o fundo preto
background:
	mov 	ax,0A000h			; endereço da memoria de video
	mov 	es,ax 				; ES aponta para memoria de video
	mov 	dx,03C4h			; dx = indexregister
	mov 	ax,0F02h 			; INDEX = MASK MAP,
	out 	dx,ax 				; escreve em todos os bitplanes.
	mov 	di,0
	mov 	cx,38400 			; (640 * 480)/8 = 38400
	mov 	ax,000h 			; coloca preto nos bits.
	rep 	stosb 				; preenche a tela
	mov 	ah,4ch 				; volta
	ret
; ##### end_background #####

; ***** desenha_menu *****
; pinta os pontos dentro de um retangulo; cor na variavel cor
; di deve ter deve ter o endereço de um vetor com os cantos dos retangulos, inferior esquerdo (x1,y1) e superior direito (x2,y2), a serem pintados
desenha_menu:
	mov		byte[cor],branco_intenso
	mov 	di,coo_borda
	call 	desenha_linhas
	; ajustando cursor, dh -> linha; dl -> coluna
	; escreve calibrando
	mov		dh,4
	mov		dl,29
	call 	cursor
	mov 	di,str_calibrando
	call 	escrever
	; escreve aperta espaco
	mov 	dh,5
	mov		dl,25
	call 	cursor
	mov 	di,str_apertaespaco
	call 	escrever
	; escreve sair do programa
	mov 	dh,18
	mov		dl,2
	call 	cursor
	mov 	di,str_parasair
	call 	escrever
	; escreve projeto final
	mov 	dh,20
	mov		dl,2
	call 	cursor
	mov 	di,str_projetofinal
	call 	escrever
	; escreve nome bruno
	mov 	dh,21
	mov		dl,2
	call 	cursor
	mov 	di,str_nomebruno
	call 	escrever
	; escreve nome laila
	mov 	dh,22
	mov		dl,2
	call 	cursor
	mov 	di,str_nomelaila
	call 	escrever
	ret
; ##### end_desenha_calibrando #####


;**** desenha_seta_inferior ****
; essa função desenha o botão de chamadas para descer. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha da seta
; call desenha_seta_inferior
desenha_seta_inferior:    ;led a ser aceso está em al ; mov al,LED ; call acende_button_led
        push ax
        push bx
        push cx
        push dx
        push di

				mov byte[cor],branco_intenso
        ; a reta subirá 20 pixels para cima e para os lados, assim:
        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        add ax,20
        push ax ; push x2 para a função line
        add bx,20
        push bx ; push y2 para a função line
        call line ; desenha a parte inferior direita da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        sub ax,10
        push ax ; push x2 para a função line
        push bx ; em bx já está a altura, então só push y2
        call line ; desenha a parte mediana direita da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        push ax ; em ax já está a posição, então só push x2
        add bx,20
        push bx ; push y2 para a função line
        call line ; desenha a parte superior direita da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        sub ax,20
        push ax ; push x2 para a função line
        push bx ; em bx já está a altura, então só push y2
        call line ; desenha a parte superior central da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        push ax ; em ax já está a posição, então só push x2
        sub bx,20
        push bx ; push y2 para a função line
        call line ; desenha a parte superior esquerda da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        sub ax,10
        push ax ; push x2 para a função line
        push bx ; em bx já está a altura, então só push y2
        call line ; desenha a parte mediana esquerda da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        add ax,20
        push ax ; push x2 para a função line
        sub bx,20
        push bx ; push y2 para a função line
        call line ; desenha a parte inferior esquerda da seta

        pop di
        pop dx
        pop cx
        pop bx
        pop ax
        ret

;**** desenha_seta_inferior ****

;**** desenha_seta_superior ****
; essa função desenha o botão de chamadas para subir. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha da seta
; call desenha_seta_superior
desenha_seta_superior:
        push ax
        push bx
        push cx
        push dx
        push di
				mov byte[cor],branco_intenso
        ; a reta descerá 20 pixels para cima e para os lados, assim:
        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        sub ax,20
        push ax ; push x2 para a função line
        sub bx,20
        push bx ; push y2 para a função line
        call line ; desenha a parte inferior direita da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        add ax,10
        push ax ; push x2 para a função line
        push bx ; em bx já está a altura, então só push y2
        call line ; desenha a parte mediana direita da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        push ax ; em ax já está a posição, então só push x2
        sub bx,20
        push bx ; push y2 para a função line
        call line ; desenha a parte superior direita da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        add ax,20
        push ax ; push x2 para a função line
        push bx ; em bx já está a altura, então só push y2
        call line ; desenha a parte superior central da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        push ax ; em ax já está a posição, então só push x2
        add bx,20
        push bx ; push y2 para a função line
        call line ; desenha a parte superior esquerda da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        add ax,10
        push ax ; push x2 para a função line
        push bx ; em bx já está a altura, então só push y2
        call line ; desenha a parte mediana esquerda da seta

        push ax ; push x1 para a função line
        push bx ; push y1 para a função line
        sub ax,20
        push ax ; push x2 para a função line
        add bx,20
        push bx ; push y2 para a função line
        call line ; desenha a parte inferior esquerda da seta

        pop di
        pop dx
        pop cx
        pop bx
        pop ax
        ret

;**** desenha_seta_superior ****


;**** desenha_seta_central_interna ****
; essa função desenha o botão de chamadas para ????. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha SUPERIOR da seta
; call desenha_seta_central_interna
desenha_seta_central_interna:
        push ax
        push bx
        push cx
        push dx
        push di

				mov byte[cor],branco_intenso
				push ax ; guarda a coordenada X da ponta superior, pois vamos utilizá-la
				push bx ; guarda a coordenada Y da ponta superior, pois vamos utilizá-la
				call desenha_seta_superior
				pop bx
				pop ax ; recupera as coordenadas x e y
				push ax ; guarda a coordenada X da ponta superior, pois vamos utilizá-la
				push bx ; guarda a coordenada Y da ponta superior, pois vamos utilizá-la
				sub bx,60 ; assim teremos as coordenadas x e y da seta inferior
				call desenha_seta_inferior
				pop bx
				pop ax ; recupera as coordenadas x e y

				; limpa a linha superior
				mov byte[cor],preto
				sub bx,20
				sub ax,9
				push ax ; push x1
				push bx	; push y1
				add ax,18
				push ax ; push x2
				push bx ; push y2
				call line
				; limpa a linha inferior
				sub bx,20
				push ax ; push x1
				push bx ; push y1
				sub ax,18
				push ax ; push x2
				push bx ; push y2
				call line

				pop di
        pop dx
        pop cx
        pop bx
        pop ax
        ret

;**** desenha_seta_central_interna ****

;**** desenha_seta_central_externa ****
; essa função desenha o botão de chamadas para ????. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha SUPERIOR da seta
; call desenha_seta_central_externa
desenha_seta_central_externa:
        push ax
        push bx
        push cx
        push dx
        push di

				mov byte[cor],branco_intenso
				push ax ; guarda a coordenada X da ponta superior, pois vamos utilizá-la
				push bx ; guarda a coordenada Y da ponta superior, pois vamos utilizá-la
				call desenha_seta_superior
				pop bx
				pop ax ; recupera as coordenadas x e y
				push ax ; guarda a coordenada X da ponta superior, pois vamos utilizá-la
				push bx ; guarda a coordenada Y da ponta superior, pois vamos utilizá-la
				sub bx,84 ; assim teremos as coordenadas x e y da seta inferior
				call desenha_seta_inferior
				pop bx
				pop ax ; recupera as coordenadas x e y

				pop di
        pop dx
        pop cx
        pop bx
        pop ax
        ret

;**** desenha_seta_central_externa ****


; --------------- Segmento de Dados ---------------
segment data
; --------------- Variáveis para desenhar ---------------
; cores
cor		db		branco
									;	I R G B COR
preto			equ		0			;	0 0 0 0 preto
azul			equ		1			;	0 0 0 1 azul
verde			equ		2			;	0 0 1 0 verde
cyan			equ		3			;	0 0 1 1 cyan
vermelho		equ		4			;	0 1 0 0 vermelho
magenta			equ		5			;	0 1 0 1 magenta
marrom			equ		6			;	0 1 1 0 marrom
branco			equ		7			;	0 1 1 1 branco
cinza			equ		8			;	1 0 0 0 cinza
azul_claro		equ		9			;	1 0 0 1 azul claro
verde_claro		equ		10			;	1 0 1 0 verde claro
cyan_claro		equ		11			;	1 0 1 1 cyan claro
rosa			equ		12			;	1 1 0 0 rosa
magenta_claro	equ		13			;	1 1 0 1 magenta claro
amarelo			equ		14			;	1 1 1 0 amarelo
branco_intenso	equ		15			;	1 1 1 1 branco intenso
; modo gráfico anterior
modo_anterior	db		0
; posicionamento, usadas por line
linha   		dw 		0
coluna  		dw 		0
deltax			dw		0
deltay			dw		0
; coordenadas de desenho - pontos a serem enviados para a função line, para evitar código looongo
coo_borda		dw		10,10,630,10,630,10,630,470,630,470,10,470,10,470,10,10,'$'
; --------------- Variáveis de mensagens ---------------
str_apertaespaco db		'Aperte ESPACO no quarto andar','$'
str_calibrando	db		'Calibrando elevador...','$'
str_nomebruno	db		'Nome: Bruno Teixeira Jeveaux','$'
str_nomelaila	db		'Nome: Laila Sindra Ribeiro','$'
str_parasair	db		'Para sair do programa, pressione Q','$'
str_projetofinal db		'Projeto Final de Sistemas Embarcados 2018-1','$'


; --------------- Leitura dos sensores e atuadores ---------------



; --------------- flags ---------------
flag_calibrando	db		1			; indica que está calibrando
flag_espaco		db		0			; indica se apertou espaco
flag_um			db		0			; indica se apertou andar 1
flag_dois		db		0			; indica se apertou andar 2
flag_tres		db		0			; indica se apertou andar 3
flag_quatro		db		0			; indica se apertou andar 4
; --------------- Variáveis de interrupção ---------------
int9 			equ		9h
offset_dos		resw	1
cs_dos			resw	1
kb_data			equ 	60h			; porta de leitura do teclado
kb_ctl			equ 	61h			; porta de reset para pedir nova interrupção
pictrl			equ		20h
eoi				equ		20h
p_i				dw		0			; ponteiro p/ interrupção (qnd pressiona tecla)
tecla 			resb	1
tec_q 			equ		10h
tec_espaco		equ		39h
tec_um			db		02h,4fh		; teclas 1 no teclado
tec_dois		db		03h,50h		; teclas 2 no teclado
tec_tres		db		04h,51h		; teclas 3 no teclado
tec_quatro		db		05h,4bh		; teclas 4 no teclado
tec_esc			equ		01h			; teclas esc no teclado
; --------------- Segmento da pilha ---------------
segment stack stack
	resb 512
stacktop:
