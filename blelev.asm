; Aluno: Bruno Teixeira Jeveaux
; Turma: 01
; ----------------------------
segment code
..start:
    		mov 		ax,data
    		mov 		ds,ax
    		mov 		ax,stack
    		mov 		ss,ax
    		mov 		sp,stacktop
; oi sou eu
        mov byte[motoracao],1
        call move_motor
        mov    	ah,08h ; fica esperando dar enter para finalizar o programa
		    int     21h
        mov     ax,4c00h ; finaliza o programa
      	int     21h

move_motor: ; em motoracao está o comando desejado para o motor (0 parado, 1 subida, 2 descida, 3 parado)
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

conta_tempo:
        cmp byte[tempo],255
        jb incrementa_tempo
        mov byte[tempo],0
        ret
        incrementa_tempo:
        inc byte[tempo]
        ret
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

segment data

motoreleds  db  00000000b
motoracao   db  0
andar_atual db  1
andar_desejado  db  4

; testes
tempo   db    0
teste  db    '0000$'
crlf   db     13,10,'$'
segment stack stack
    		resb 		512
stacktop:
