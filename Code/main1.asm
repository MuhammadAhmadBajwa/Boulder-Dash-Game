jmp FileReading
InputMsg1: db 'Enter the cave file name or press Enter to use the default (cave1.txt)',0
InputMsg2: db 'File name : ',0
ErrorMsg1: db 'ERR: Could not open input file. Program will now quit',0
ErrorMsg2: db 'ERR: Incomplete data in file. Program will now quit',0 
fileNameInput: db 64,64    ; 64 is buffer size and string input interupt will take 64 bytes input
fileData: times 1600 db 0  ; allocate space for file data input
FileReading:
; save registers
	push bp
	mov bp , sp
	push ax
	push bx
	push cx
	push dx
	
	cmp word[bp+4] , 1
	je RunDefault
	
; print input messages
	push 0                     ; x position
	push 0                     ; y position
	push 0x07                  ; attribute
	push InputMsg1             ; starting address of string
	call printstr
	
	push 0                     ; x position
	push 1                     ; y position
	push 0x07                  ; attribute
	push InputMsg2             ; starting address of string
	call printstr
	
; move cursor after the printed message
	mov dh, 1                  ; cursor row position
	mov dl, 13                 ; cursor column position
	mov bh, 0                  ; page number
	mov ah, 2                  ; subservice number
	int 10h
	
; input file name
	mov dx,fileNameInput       ; Address of Buffer for string input
	mov ah,0ah                 ; subservice number
	int 21h                    ; call interrupt for string input
	
	mov bx, 0             
	mov bl, [fileNameInput+1]  ; Load number of char bytes input by ISR
	cmp bl,0                   ; Check if no character is entered
	je RunDefault              ; If file name is not entered then run default cave1.txt
	mov byte[fileNameInput+bx+2], 0 ; otherwise place null at end of string
	jmp RunInputFile
	
RunDefault:
	mov dx,[bp+6]              ; Point dx to default filename 
	jmp OpenFile
	
RunInputFile:
	mov dx,fileNameInput+2     ; Point dx to user input filename
	
; opening file
OpenFile:
	mov al,0                   ; Read mode set
	mov ah,0x3d                ; Subservice number
	int 21h                    ; call interrupt for file opening
	jnc ReadFile               ; If no error occur then Read File
; Otherwise print the error message and terminate
	push 0                     ; column number
	push 2                     ; row number
	push 0x07                  ; attributes
	push ErrorMsg1             ; starting address of string
	call printstr              ; print string
	
; move cursor 
	mov dh, 2                  ; cursor row position
	mov dl, 3                  ; cursor column position
	mov bh, 0                  ; page number
	mov ah, 2                  ; subservice number
	int 10h                    ; call interrupt to move cursor
	jmp terminate              ; end program
	
	
ReadFile:
	push ax                    ; save filehandle return by file open subservice
	
; read file
	mov cx,1600                ; Bytes to be read
	mov bx,ax                  ; load FileHandle in bx
	mov dx,fileData            ; Address of buffer to save file input data
	mov ah,0x3f                ; subservice number
	int 21h                    ; call interrupt to read file into fileData
	
	cmp ax, 1600               ; checking if 1600 bytes has been read
	je closeFile               ; if yes then close the file
	
; otherwise print error message then insufficient bytes are read and terminate
	push 0                     ; column number
	push 2                     ; row number
	push 0x07                  ; attributes
	push ErrorMsg2             ; string base address
	call printstr              ; print string
; move cursor 
	mov dh, 2                  ; cursor row position
	mov dl, 3                  ; cursor column position
	mov bh, 0                  ; page number
	mov ah, 2                  ; subservice number
	int 10h                    ; call interrupt to move cursor
	jmp terminate
	
closeFile:
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
	ret 4
	
