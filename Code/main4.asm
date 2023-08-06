jmp LoadSplashScreen
SplashFileName : db 'main.txt',0
D: dw 0x66dd
x: dw 0x06b1
X: dw 0x00b1
B: dw 0x66dd
A: dw 0x66df
a: dw 0x66df
W: dw 0x66db
SplashFileData: times 2050 db 0  ; allocate space for file data input

SplashFileReading:
; save registers
	push bp
	mov bp , sp
	push ax
	push bx
	push cx
	push dx
	
	mov dx,SplashFileName     ; Point dx to user input filename
	mov al,0                   ; Read mode set
	mov ah,0x3d                ; Subservice number
	int 21h                    ; call interrupt for file opening
	push ax                    ; save filehandle return by file open subservice
	
; read file
	mov cx,2050                ; Bytes to be read
	mov bx,ax                  ; load FileHandle in bx
	mov dx,SplashFileData            ; Address of buffer to save file input data
	mov ah,0x3f                ; subservice number
	int 21h                    ; call interrupt to read file into fileData
	
; close file
	pop bx                     ; load FileHandle in bx           
	mov ah,0x3e                ; subserive number
	int 21h                    ; call interrupt to close file
	
	
; restore registers
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 
	

Waiting:
    push cx
	push dx
    push ax

	mov cx, 0
	mov dx, 0xfff
	mov ah, 86h
	int 15h

	pop ax
	pop dx
	pop cx
	ret
	
LoadSplashScreen:
    push es
    push ax
	push bx
	push cx 
	push dx
	push di

    call SplashFileReading
	mov bx , SplashFileData
	mov di , 0
	mov ax, 0xb800
	mov es,  ax
	mov dx,  0
    mov cx, 2050

Loop2:
;--------------------------------------------------------------
;Here iam comparing the data read in buffer and placing its
;equivalent character in video memory
;--------------------------------------------------------------
    call Waiting
	cmp byte[bx] , 'x'
	jne checkA
	mov ax , [x]
	jmp  drawSplashScreen
	
checkA:
	cmp byte[bx] , 'A'
	jne checkB
	mov ax , [A]
	jmp  drawSplashScreen
	
checkB:
	cmp byte[bx] , 'B'
	jne checkW
	mov ax , [B]
	jmp  drawSplashScreen
	
checkW:
	cmp byte[bx] , 'W'
	jne checkC
	mov ax , [W]
	jmp  drawSplashScreen
	
checkC:
	cmp byte[bx] , 'C'
	jne checkX
	mov ax, [D]
	jmp  drawSplashScreen
checkX:
    cmp byte[bx] , 'X'
	jne checka
	mov ax, [X]
	jmp  drawSplashScreen
checka:
    cmp byte[bx] , 'a'
	jne unknown
	mov ax, [a]
	jmp  drawSplashScreen
unknown:
   inc bx
   jmp increment  
drawSplashScreen:
	mov word [es:di] , ax    ; print character
	add di , 2               ; move to next video memory location
	inc bx                   ; move to next txt fileData location
increment:
	loop Loop2

    mov cx , 700
l1:
    call Waiting
	loop l1

	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	ret 