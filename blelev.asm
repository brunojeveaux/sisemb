; --------------------------------------------------------
; Alunos: Bruno Teixeira Jeveaux e Laila Sindra Ribeiro
; Turma: 01
; --------------------------------------------------------
segment code
..start:
    	mov 		ax,data
    	mov 		ds,ax
    	mov 		ax,stack
    	mov 		ss,ax
    	mov 		sp,stacktop
	
	; TO DO LIST
	; QUANDO FIZER PARADA DE ELEVADOR, SUBIR UM POUQUINHO ATÉ sensor_atual = 0!!! DEPOIS PARAR MESMO.
	
	
	
	
	ler_sensor:		; le o sensor de andar e incrementa ou decrementa o andar de acordo com o necessário
	mov 		dx,319h
	in		dx,al
	mov 		byte[entrada],al
	xor 		ah,ah
	mov		al,byte[motoreleds]			
	shr		ax,6
	test		byte[entrada],01000000b
	jz 		buraco
	jmp 		obstruido
	buraco:			; se mudar de 1 pra zero e estava subindo, incrementa o andar. Se não, continua o que estava fazendo.
	mov		byte[sensor_new],0
	test 		byte[sensor_old],1
	jz 		continua
	cmp		al,0	; parado
	je		continua
	cmp		al,1	; subindo
	je 		incrementa_andar
	cmp		al,2	; descendo
	je		continua
	cmp		al,3	; parado
	je		continua
	obstruido:		; se mudar de zero pra 1 e estava descendo, decrementa o andar. Se não, continua o que estava fazendo.
	mov		byte[sensor_new],1
	test		byte[sensor_old],1
	jnz	 	continua
	cmp		al,0	; parado
	je		continua
	cmp		al,1	; subindo
	je	 	continua
	cmp 		al,2	; descendo
	je	 	decrementa_andar
	cmp		al,3	; parado
	je		continua
	incrementa_andar:
	inc		byte[andar_atual]
	jmp 		continua
	decrementa_andar:
	dec 		byte[andar_atual]
	continua:
	mov		al,byte[sensor_new]
	mov 		byte[sensor_old],al
	
	
	
        mov    	ah,08h ; fica esperando dar enter para finalizar o programa
	int     21h
        jmp saida

saida:
	mov 	ax,4c00h
	int		21h
	
; ---------------------------- FIM DO PROGRAMA PRINCIPAL ----------------------------

; -------------- Funções --------------

; **** move_motor ****
; salve em motoracao o comando desejado para o motor (0 parado, 1 subida, 2 descida, 3 parado)
; mov byte[motoracao],VALOR ; call move_motor
move_motor:
        push ax
        push cx
        push dx ; salva o contexto
        ;
        mov al,[motoreleds]
        mov ah,[motoracao]
        shl ah,6         ; shifta o dado para termos: XX000000
        and al,00111111b ; zera os bits 6 e 7 dos motores para dar o comando
        or al,ah ; mantém os bits 0 a 5 e dá o comando desejado
        mov byte[motoreleds],al
        continua_andando:
                mov dx,318h
                out dx,al
                cmp byte[motoracao],0         ; verifica se o comando foi de parada
                je fim_andando
                cmp byte[motoracao],3         ; verifica se o comando foi de parada
                je fim_andando
                call conta_tempo
                call verifica_andar
                mov cl,byte[andar_atual]
                cmp cl,[andar_desejado] ; verifica se chegou no andar, se não continua andando
                jne continua_andando
                ;
        fim_andando:
        mov ah,0
        mov al,byte[motoreleds]
        call printa_inteiro
        pop dx ; recupera o contexto
        pop cx
        pop ax
        ret
; **** fim_move_motor ****

; **** conta_tempo ****
conta_tempo:
        cmp byte[tempo],255
        jb incrementa_tempo
        mov byte[tempo],0
        ret
        incrementa_tempo:
        inc byte[tempo]
        ret
; **** fim_conta_tempo ****

; **** verifica_andar ****
verifica_andar:
        push ax

        cmp byte[tempo],255
        jne sai_andar
        cmp byte[motoracao],1 ; aqui ele verifica se o motor estava subindo
        jne decrementa_andar  ; se não estiver, então estava descendo
        inc byte[andar_atual]
        jmp sai_andar
        decrementa_andar:
        dec byte[andar_atual]
        sai_andar:
        mov ah,0
        mov al,byte[andar_atual]
        call printa_inteiro

        pop ax
        ret
	
;**** printa_inteiro ****
printa_inteiro: ; em ax está o inteiro que queremos printar
        push ax
        push bx
        push cx
        push dx
        push di
        ;
        ;converte inteiro que está em AX para string
    		mov bx,teste ; move o ponteiro da string auxiliar para bx
    		call zera_valor ; volta o valor da string auxiliar para 0
    		add bx,3 ; vai para o fim do ponteiro de string
    		mov cx,10
    dividindo:
    		mov dx,0
    		div cx ; divide ax por 10
    		; resto est� em dx
    		add [bx],dx ; transforma em character ; vai dar pau?? usar dl?
    		dec bx
    		cmp ax,0
    		je fim_conversao
    		jmp dividindo
    fim_conversao:
        call printa_string
        pop di
        pop dx
        pop cx
        pop bx
        pop ax
        ret
;**** fim_printa_inteiro ****	
	
;**** printa_string ****	
printa_string:
        push ax
        push dx

        mov ah,9
        mov dx,teste
        int 21h
        mov ah,9
        mov dx,crlf
        int 21h

        pop dx
        pop ax
        ret
;**** fim_printa_string ****	
	
;**** zera_valor ****	
zera_valor: ; ponteiro está em bx
    		push di
    		mov di,0
    	zerando:
    		cmp byte[bx+di],'$'
    		je termina_zerar
    		mov byte[bx+di],'0'
    		inc di
    		jmp zerando
    termina_zerar:
    		pop di
    		ret
;**** fim_zera_valor ****

;**** acende_button_led ****
; essa função acende o led de algum botão. Para utilizar a função, faça:
; mov al,NUMERO_DO_LED_A_SER_ACESO
; call acende_button_led
acende_button_led:    ;led a ser aceso está em al ; mov al,LED ; call acende_button_led
        push ax
        push cx
        push dx

        mov ah,0
        dec al ; decrementa para fazer o shift
        xor cx,cx
        mov cl,al
        mov al,1
        shl ax,cl
        or byte[motoreleds],al ; altera o vetor motoreleds para ligar o bit do led desejado
        mov al,byte[motoreleds]
        mov dx,318h
        out dx,al

        pop dx
        pop cx
        pop ax
        ret

;**** acende_button_led ****

segment data
; --------------- Variáveis de desenho --------------
; --------------- Variáveis de controle --------------
	motoreleds		db  00000000b ; bits 7 e 6 são os motores 0 0 Parado; 0 1 Sobe; 1 0 Desce; 1 1 Parado
	motoracao   		db  0
	andar_atual 		db  1
	andar_desejado 		db  4
	entrada			db		00000000b	; valores lidos da porta 319h (bit 6 é o sensor)
	sensor_old		db		0		; 0 -> buraco, 1 -> ostruido
	sensor_new		db		0		
; -------------- Mensagens e strings --------------
	str_			db		'fim dados'
; -------------- Variáveis para testes --------------
	; testes
	tempo   db    0
	teste  db    '0000$'
	crlf   db     13,10,'$'
segment stack stack
	resb 		512
stacktop:
