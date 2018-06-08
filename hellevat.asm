;**** pinta_seta ****
; essa função pinta o botão de chamadas. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha da seta
; mov dx,DIRECAO			; -1 para pintar seta superior e 1 para pintar seta inferior
; call pinta_seta
pinta_seta:
        push ax
        push bx
        push cx
        push dx
        push di

				add bx,dx
				push ax
				push bx
				call plot_xy

				mov cx,18
				mov di,1
				pintando_seta:
				add bx,dx
				sub ax,di
				push ax ; push x1
				push bx	; push y1

				add ax,di
				add ax,di
				push ax ; push x2
				push bx	; push y2
				call line
				sub ax,di ; volta à posição central
				inc di
				loop pintando_seta

				mov cx,20
				; pinta o retângulo da seta
				pintando:
				add bx,dx
				sub ax,9
				push ax ; push x1
				push bx ; push y1
				add ax,18
				push ax ; push x2
				push bx ; push y2
				sub ax,9
				call line
				loop pintando

				pop di
        pop dx
        pop cx
        pop bx
        pop ax
        ret

;**** pinta_seta ****

;**** pinta_seta_dupla_interna ****
; essa função pinta o botão de chamadas interna. Para utilizar a função, faça:
; mov ax,coordenada_x
; mov bx,coordenada_y ; essas coordenadas são da pontinha SUPERIOR da seta
; call pinta_seta_dupla_interna
pinta_seta_dupla_interna:
        push ax
        push bx
        push cx
        push dx
        push di

				mov byte[cor],vermelho
				mov dx,-1
				call pinta_seta
				sub bx,60
				mov dx,1
				call pinta_seta

				pop di
        pop dx
        pop cx
        pop bx
        pop ax
        ret

;**** pinta_seta_dupla_interna ****
