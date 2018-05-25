;leitura de sensor dos elevadores
segment code
..start:
	mov 	ax, data
	mov		ds,ax
	mov		ax,stack
	mov		ss,ax
	mov		sp,stacktop
	
	xor 	di,di						; para testes
	mov 	cx,10						; para testes
ler_sensor:
	;mov 	dx,319h
	;in		dx,al
	;mov 	byte[entrada],al
	
	mov 	al,byte[leitura+di]			; para testes
	mov 	byte[entrada],al			; para testes
	
	xor 	ah,ah
	mov		al,byte[motoreleds+di]			; +di para testes
	shr		ax,6
	test	byte[leitura+di],01000000b	; leitura+di para testes ; entrada para func normal
	jz 		buraco
	jmp 	obstruido
	buraco:			; se mudar de 1 pra zero e estava subindo, incrementa o andar. Se não, continua o que estava fazendo.
	mov		byte[sensor_new],0
	test 	byte[sensor_old],1
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
	test	byte[sensor_old],1
	jnz	 	continua
	cmp		al,0	; parado
	je		continua
	cmp		al,1	; subindo
	je	 	continua
	cmp 	al,2	; descendo
	je	 	decrementa_andar
	cmp		al,3	; parado
	je		continua
	incrementa_andar:
	inc		byte[andar_atual]
	jmp 	continua
	decrementa_andar:
	dec 	byte[andar_atual]
	continua:
	mov		al,byte[sensor_new]
	mov 	byte[sensor_old],al
	
	mov		al,byte[andar_atual]
	add		al,'0'
	mov 	byte[andar_str],al
	mov 	dx,andar_str
	mov 	ah,09h
	int 	21h
	inc		di					; para testes
	loop 	ler_sensor			; para testes
saida:
	mov 	ax,4c00h
	int		21h
	
segment data
	motoreleds	db		10000000b,10000000b,10000000b,10000000b,10000000b,10000000b,10000000b,10000000b,10000000b,10000000b	; bits 7 e 6 são os motores 0 0 Parado; 0 1 Sobe; 1 0 Desce; 1 1 Parado
	entrada		db		00000000b	; bit 6 é o sensor
	sensor_old	db		0			; 0 -> buraco, 1 -> ostruido
	sensor_new	db		0			
	andar_atual	db		4			
	str_		db		'fim dados'
	leitura		db		00000000b,00000000b,01000000b,01000000b,01000000b,01000000b,01000000b,00000000b,00000000b,00000000b ; usado para teste
	andar_str	db		0,13,10,'$'

segment stack stack
	resb 256
stacktop: