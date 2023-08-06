jmp PlayGame
GameOverMsg: db '     Game Over !!',0
LevelCompleteMsg: db '  All  Levels Complete',0
NextLevelMsg:   db  'Level Complete.Press Enter to Play Next Level',0
score:  dw 0
level:  dw 1
bell : dw 0x007,'$'
restartMsg: db 'r : restart',0
level2File: dw 'cave2.txt'
level3File: dw 'cave3.txt'
	
printRestartMsg:
	push 30
	push 24
	push 0x07
	push restartMsg
	call printstr
	ret
	
	
; Subroutine to Remove rockford from previous location
; when rockford is at Target position
PrevLocationRemove:
	push dx
	mov dx,[Rockford]
	
;compare left
	cmp [es:di-2],dx
	jne CheckRight
	mov word[es:di-2],0x0720
	
CheckRight:
	cmp [es:di+2],dx
	jne CheckUp
	mov word[es:di+2],0x0720
	
CheckUp:
	cmp [es:di-160],dx
	jne CheckDown
	mov word [es:di-160],0x0720
	
CheckDown:
	cmp[es:di+160],dx
	jne  end 
	mov word[es:di+160],0x0720
	
end:
	pop dx
	ret
	
	
CheckValidMove: 
	push ax
	push bx
	push es
	push dx
	
	push 0xb800
	pop es
	
; move cursor at 0 location
	mov dh, 0                  ; cursor row position
	mov dl, 0                  ; cursor column position
	mov bh, 0                  ; page number
	mov ah, 2                  ; subservice number
	int 10h
	
	mov ax,[es:di]
	cmp ax,[Wall]              ; check if wall
	jne compareDirt            ; if no compare Dirt
	mov ah,09h
	mov dx,bell                ; if yes make bell sound 
	int 21h
	mov cx , 0                 ; invalid move
	jmp return
	
compareDirt:
	cmp ax,[Dirt]             ; check if dirt
	jne compareBoulder        ; if no compare boulder
	mov dx , [Rockford]
	mov word [es:di],dx       ; if yes move in that direction
	mov cx , 1                ; valid move 
	jmp return
	
compareBoulder: 
	cmp ax,[Boulder]           ; check if boulder
	jne compareDiamond         ; if no compare Diamond
	mov ah,09h
	mov dx,bell                ; if yes make bell sound 
	int 21h
	mov cx , 0                 ; invalid move 
	jmp return
	
compareDiamond:
	cmp ax,[Diamond]          ; check if diamond
	jne compareTarget         ; if no compareTarget
	mov dx, [Rockford]
	mov word[es:di],dx        ; if yes make move 
	
; increment Score  and print that score 
	mov bx , [score]
	inc bx
	mov [score],bx
	push bx
	push (24*80+7)*2
	call printnum
	mov cx , 1                ; valid move 
	
compareTarget: 
	cmp ax, [Target]         ; check if target
	jne compareAlreadyVisited; if no check already visited  
	mov dl,02h               ; if yes make move and level complete
	mov dh,8ah
	mov word[es:di],dx 
; increment  LEVEL and jmp to ignorekeyinput  
	cmp word[level] , 3
	je AllLevelsComplete
	mov bx , [level]
	inc bx 
	mov [level],bx
	call PrevLocationRemove
	push 0
	push 1
	push 0x07
	push NextLevelMsg
	call printstr
	jmp IgnoreKeyInput
	
;-------------------------------------------------------------------
;To move to next level Iam checking curret level number as level number
;is already incremented and reading and then loading txt files according 
;to the level number my game supports 3 level
;-------------------------------------------------------------------
MoveToNextLevel:
	cmp word[level],2       ; checking if player is on level 2
	ja compareLevel3       ; if no check for level 3
	push level2File         ; if yes push level2 txt file name
	jmp LoadNextLevel       ; Load next level
compareLevel3:
	cmp word[level],3
	ja AllLevelsComplete
	push level3File         ; push level3 txt file name
	
LoadNextLevel:              ; loading next level
	push 1                  ; flag 1 to open the default file name passed as
	                        ; parameter above 
	                        ; and flag 0 to input file name form user at runtime
	call FileReading        ; read file and restart the game according to new file data
	jmp restart
	
AllLevelsComplete:
;Print Level complete message
	push 0
	push 1
	push 0x07
	push LevelCompleteMsg
	call printstr
	mov bx,[level]
	inc bx
	mov [level],bx
	jmp IgnoreKeyInput
	
compareAlreadyVisited:
	cmp ax,0x0720            ; check if already visited
	jne return               ; if no return
	mov dx,[Rockford]        ; if yes make move
	mov word[es:di],dx
	mov cx , 1
return:
	pop dx
	pop es
	pop bx
	pop ax
	ret 
	
	
PlayGame:
	push es
	push ax
	push cx
	push dx
	push di
	mov di,[rockfordLocation]  ; point di to rockford initial location
	                           ; which was saved during layout drawing
	
	mov ax, 0xb800
	mov es,ax
GameLoop:
; check for game over condition
	mov ax,[es:di-160]
	cmp ax,[Boulder]           ; checking if rockford is under boulder
	jne KeystrokeInput         ; if not jump to next keystroke input
	                           ; if yes then game is over print game over 
							   ; message and change boulder and rockford
							   ; attributes to blinking red
; Print Game Over Message
	push 0
	push 1
	push 0x07
	push GameOverMsg
	call printstr
	call printRestartMsg
; Change boulder and rockford attributes
	mov al , 09h               ; boulder ascii
	mov ah , 84h               ; change attributes to blinking red    
	mov [es:di-160],ax         ; put at boulder location as boulder is above rockford
	                           ; that's why di -160
	
	mov al , 02h
	mov [es:di] , ax           ; di is always pointing to rockford location in gameplay
	jmp IgnoreKeyInput 
	
	
KeystrokeInput:
	mov ah,00h                 ; subservice for keystroke input
	int 16h                    ; wait for keystroke
	
; check which key is pressed and move in that direction
	cmp ah,0x4b                ; checking for left key
	jne compareRight           ; if no check for right key
	sub di,2                   ; if yes move the rockford to left memory location
	call CheckValidMove        ; checking if move is valid if valid then move
	jcxz InvalidLeftMove       ; cheking if move was valid
	mov word [es:di+2],0x0720  ; if yes then remove rocford from current location
	                           ; as rockford is shifted to valid move location
	jmp GameLoop               ; jmp back to gameloop to input next keystroke
	
InvalidLeftMove:               ; else if move was invalid 
	add di, 2                  ; redo the memory location
	jmp GameLoop               ; jmp back to gameloop to input next keystroke
	
;same steps are following as commented above for comparing left key
compareRight:
	cmp ah,0x4d
	jne compareUp
	add di,2
	call CheckValidMove
	jcxz InvalidRightMove
	mov word[es:di-2],0x0720
	jmp GameLoop
InvalidRightMove:
	sub di, 2
	jmp GameLoop
	
;same steps are following as commented above for comparing left key
compareUp:
	cmp ah,0x48
	jne compareDown
	sub di,160
	call CheckValidMove
	jcxz InvalidUpMove
	mov word[es:di+160],0x0720
	jmp GameLoop
InvalidUpMove:
	add di,160
	jmp GameLoop
	
	
;same steps are following as commented above for comparing left key
compareDown:
	cmp ah,0x50
	jne compareExit
	add di,160
	call CheckValidMove
	jcxz InvalidDownMove
	mov word[es:di-160],0x0720
	jmp GameLoop
InvalidDownMove:
	sub di, 160
	jmp GameLoop
	
	
compareExit:                
	cmp ah,0x1                ; compare for escape key
	jne GameLoop              ; if not jmp back to gameloop
	call clrscr               ; if yes clear screen and make cursor visible
;make cursor visible
	mov ch,0                  ; 0 is for default blinking of cursor
	mov ah,1                  ; choosing subservice number
	int 10h                   ; call interrupt to make cursor visible
	jmp EndOfGame             ; and jmp to end of game
	
	
;--------------------------------------------------------------------------
;IgnoreKeyInput is called or I jump to it when the game is over or level
;is completed then we have to ignore all keystroke inputs the only options
; we left with are escape or restart or enter 
; esc : escape to exit the game
; r   : restart the current level 
; enter  : If level completed move to next level
;--------------------------------------------------------------------------
IgnoreKeyInput:
	mov ah,00h                 ; subservice for keystroke input
	int 16h                    ; wait for keystroke
	cmp ah,0x1                 ; cheking if esc is pressed
jne compareRestart             ; if no check for r : restart
	jmp EndOfGame              ; if yes jump to end of game
compareRestart:
cmp al,'r'                     ; check for r : restart
	jne compareEnter           ; if no check for next key which is enter
	cmp word [es:di],0x8402    ; if yes check if game is over by compareing rockford attribute
	                           ; attribute that should have changed now to blinking red
	jne IgnoreKeyInput         ; if game is not over then you cannot restart the game                  
	                           ; or move to next level
	jmp restart			       ; so game is over and r is pressed therefore restart the current level
	
compareEnter:
	cmp ah, 0x1c               ; checking if enter is pressed
	jne IgnoreKeyInput         ; if no jmp back to start of loop
	cmp word[level],3          ; checking if all levels are completed  or game is not over
	ja  IgnoreKeyInput         ; if levels are above than max level then we cannot jump to next level
	cmp word [es:di],0x8402    ; checking if game is over
	je IgnoreKeyInput          ; If game is over then do not move to next level upon pressing enter
	jmp MoveToNextLevel        ; otherwise move to next level
	
EndOfGame:                     ; end of game will clear the screen and make cursor visible
	call clrscr
;make cursor visible
	mov ch,0
	mov ah,1
	int 10h
     jmp terminate
	pop di
	pop dx
	pop cx
	pop ax
	pop es
	
	ret
	
