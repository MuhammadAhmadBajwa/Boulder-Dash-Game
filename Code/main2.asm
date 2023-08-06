;-----------------------------------------------------------------
; These are the helper subroutines taken from the course book 
;-----------------------------------------------------------------
clrscr:
	push es
	push ax
	push cx
	push di
	
	mov ax,0xb800
	mov es,ax
	mov di,0
	mov ax,0x720
	mov cx,2000
	
	cld 
	rep stosw
	
	pop di
	pop cx
	pop ax
	pop es
	ret
	
printstr:
	push bp 
	mov bp ,sp
	push es
	push ax
	push cx
	push si
	push di
	
	push ds
	pop  es
	
	mov di,[bp+4]
	mov cx,0xffff
	mov al,0
	repne scasb
	mov ax,0xffff
	sub ax,cx
	dec ax
	jz exit
	
	mov cx,ax
	mov ax,0xb800
	mov es,ax
	mov al,80
	mul byte[bp+8]
	add ax,[bp+10]
	shl ax, 1
	mov di,ax
	mov si,[bp+4]
	mov ah,[bp+6]
	
	cld
nextchar:
	lodsb
	stosw
	loop nextchar
	
exit:
	pop di
	pop si
	pop cx
	pop ax
	pop es
	pop bp
	ret 8
	
	
	 
printnum:
	 push bp 
	 mov bp, sp 
	 push es 
	 push ax 
	 push bx 
	 push cx 
	 push dx 
	 push di 
	 mov ax, 0xb800 
	 mov es, ax 
	 mov ax, [bp+6] 
	 mov bx, 10 
	 mov cx, 0 
nextdigit: mov dx, 0 
	 div bx 
	 add dl, 0x30 
	 push dx 
	 inc cx  
	 cmp ax, 0 
	 jnz nextdigit 
	 mov di, [bp+4] 
nextpos:
	 pop dx 
	 mov dh, 0x07 
	 mov [es:di], dx 
	 add di, 2 
	 loop nextpos 
	 pop di 
	 pop dx 
	 pop cx 
	 pop bx 
	 pop ax 
	 pop es 
	 pop bp 
	 ret 4
	
