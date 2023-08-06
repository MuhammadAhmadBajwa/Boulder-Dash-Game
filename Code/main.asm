[org 0x100]
jmp start
fileName: db 'cave1.txt',0
header: db 'BOULDER DASH NUCES EDITION',0
ArrowLabel  : db 'Arrow keys : move',0
EscapeLabel : db 'Esc :  quit',0
ScoreLabel  : db 'Score: 0',0
LevelLabel  : db 'Level: ',0
UnkownCharErrMsg: db 'ERR :  Unknown Character Detected. Program will now quit',0
Dirt: dw 0x0fb1
Rockford: dw 0x0f02
Target: dw  0x0a7f
Boulder: dw 0x0509
Diamond: dw  0x0304
Wall: dw 0x66db
rockfordLocation: db 0

%include 'main1.asm'
%include 'main2.asm'
%include 'main3.asm'
%include 'main4.asm'
	
;------------------------------------------------------------------
;This subroutine is drawing only the static boundaries of game
;------------------------------------------------------------------
DrawBoundaries:
	push es                  ; save registers
	push ax
	push cx
	push di
	
	mov ax,0xb800 
	mov es,ax                ; point es to video memory
	
;draw upper boundary
	mov ax,[Wall]
	mov di,(2*80+0)*2
	mov cx,80
	cld  
	rep stosw               
	
;draw lower boundary
	mov di,(23*80+0)*2
	mov cx,80
	cld 
	rep stosw
	
;draw left and right boundary
	mov di,(3*80+0)*2
	mov cx, 20
loop1:
	mov [es:di],ax           ; printing right boundary
	add di,158
	mov [es:di],ax
	add di,2
	loop loop1
	
	pop di
	pop ax
	pop cx
	pop es
	ret
	
;-------------------------------------------------------------
;This subroutine is drawing actual game layout according to
;the fileData  which is read from the txt file into buffer
;named fileData having space of 1600 bytes
;-------------------------------------------------------------
LoadGameLayout:
    push es
    push ax
	push bx
	push cx 
	push dx
	push di
	
	mov bx , fileData
	mov di , (3*80+1)*2
	mov ax, 0xb800
	mov es,  ax
	mov dx,  0
OuterLoop:
	mov cx , 0
InnerLoop:
;--------------------------------------------------------------
;Here iam comparing the data read in buffer and placing its
;equivalent character in video memory
;--------------------------------------------------------------
    inc cx
	cmp byte[bx] , 'x'
	jne checkDiamond
	mov ax , [Dirt]
	jmp Draw
	
checkDiamond:
	cmp byte[bx] , 'D'
	jne checkBoulder
	mov ax , [Diamond]
	jmp Draw
	
checkBoulder:
	cmp byte[bx] , 'B'
	jne checkWall
	mov ax , [Boulder]
	jmp Draw
	
checkWall:
	cmp byte[bx] , 'W'
	jne checkRockford
	mov ax , [Wall]
	jmp Draw
	
checkRockford:
	cmp byte[bx] , 'R'
	jne checkTarget
	mov ax, [Rockford]
	mov [rockfordLocation],di ; update the rockford initial location
	jmp Draw
	
checkTarget:
	cmp byte[bx] , 'T'
	jne compareCR
	mov ax, [Target]
	jmp Draw
	
compareCR:                   
							 ; if cr and lf detected then jmp back to start of loop
	                         ; because we do not want to draw them
	cmp byte[bx] , 13        ; checking if CR
	jne compareLF            ; if not check for LF
	cmp cx,79                ; checking if current row contains valid number of characters
	jne IncompleteRow        ; if not print incomplete data msg
	inc bx
	jmp InnerLoop            ; if yes jmp back to start of loop
	
compareLF:  
	cmp byte[bx] , 10        ; cheking if LF
	jne UnknownCharacter     ; if Not then Unknown character is dectected
	inc bx
	jmp InnerLoopEnd         ; if yes end of row so jump out of inner loop
	
UnknownCharacter:            ; if unknown character detected then print error msg
	                         ; and terminate the game
	call clrscr
	push 0
	push 0
	push 0x07
	push UnkownCharErrMsg
	call printstr
	jmp terminate
;-------------------------------------------------------------------
; printing incomplete data error message if  row contains less or 
; greater than 78 characters
;-------------------------------------------------------------------
IncompleteRow:               
    call clrscr
	push 0
	push 0
	push 0x07
	push ErrorMsg2
	call printstr
	jmp terminate
	
Draw:
	mov word [es:di] , ax    ; print character
	add di , 2               ; move to next video memory location
	inc bx                   ; move to next txt fileData location
	jmp  InnerLoop
	
InnerLoopEnd:
	add di , 4               ; point di to next row location 
	inc dx                   ; increment row number
	cmp dx, 20               ; check if 20 rows have been printed
	jl OuterLoop
	
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	ret 
	
	
;-------------------------------------------------------------------
;This subroutine is start of my game it will clear the screen and make
;cursor invisible and then  draw the static layout including title ,
;header , footers and then call other subroutines to draw boundaries 
;and  game internal layout respectively
;-------------------------------------------------------------------
GameStart:
    push ax
	push bx
	push cx
	call clrscr
;make cursor invisible
	mov ch,32
	mov ah,1
	int 10h
	
	
;draw initial structure of game
	call clrscr
	push 25                  ; column number (x position)
	push 0                   ; row number    (y position)
	push 0x07                ; attribute     (normal white on black )
	push header              ; address of string
	call printstr            ; print string
	
	push 0                   ; column number
	push 1                   ; row number
	push 0x07                ; attribute
	push ArrowLabel          ; address of string
	call printstr            ; print string
	
	push 65                  ; column number
	push 1                   ; row number
	push 0x07                ; attribute
	push EscapeLabel         ; address of string
	call printstr            ; print string
	
	push 0                   ; column number
	push 24                  ; row number
	push 0x07                ; attribute
	push ScoreLabel          ; address of string
	call printstr            ; print string
	
	push 65                  ; column number
	push 24                  ; row number
	push 0x07                ; attribute  
	push LevelLabel          ; string address
	call printstr            ; print string
	
	mov  bx , [level]        ; load level number in bx
	push bx                  ; pass level number as paramater
	push (24*80+72)*2        ; pass static print memory location of level number
	call printnum            ; print level number
	
	call DrawBoundaries
	call LoadGameLayout
	
	pop cx
	pop bx
	pop ax
	ret
	
	
;-------------------------------------------------------------------
;In main following tasks are done
;1.clearing screen and then reading file
;2.Drawing game complete layout
;3.Playing game which include taking account of moves
;-------------------------------------------------------------------
start:
    call LoadSplashScreen
	call clrscr
	push fileName          ; default file name  to be open
	push 0                 ; flag 1 to open the default file name passed as
	                       ; parameter above 
	                       ; and flag 0 to input file name form user at runtime
	call FileReading
restart:
	mov word [score],0
	call GameStart
	call PlayGame
terminate:
	mov ax,0x4c00
	int 0x21
	
