;Christian Pizarro
;23441107
;can read text file, and move through it with arrow, and also write and delete stuff in text file
TITLE PGM: FILE BROWSER
.MODEL SMALL
.STACK 100H
.DATA
new_line db 0ah,0dh,"$"
title_str db "                         Christian Pizarro's Text Editor","$"
Bottom_str db "Arrow keys: Move thoughout the text file, ESC: Saves , WRITE ENABLED","$"
filename db 25 DUP(?)
text    db  1600 DUP(' ')
ins_flag db 1
PosX    dw 0
PosY    dw 0
handle  dw ?


.CODE

    MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    MOV SI,82h
    LEA DI,filename ;whatever file name is after the call of execute file
READ:
    MOV AL,ES:[SI]
    CMP AL,0Dh
    JE READDATA
    MOV [DI],AL
    INC SI
    INC DI
    JMP READ

READDATA:
    mov AH,3Dh          ; opens the file.
    mov AL,2            ; 2 allows for both read and write
    LEA DX,filename     ; makes a pointer to the filename
    int 21h             ; call DOS
    MOV handle,AX       ; Function 3Dh returns the file handle in AX, here we save it for later use.
    JNC READFILE
    JMP EXIT_MAIN

READFILE:
    mov ah,3Fh
    mov cx,07D0H        ; CX is how many bytes to read.
    mov dx,offset text  ; DOS Functions like DX having pointers for some reason.
    mov bx,handle       ; BX needs the file handle.
    int 21h             ; call DOS



;file browser screen
FILEBROWSER:

    ; set video mode
    MOV AH, 0 ; set mode function
    MOV AL, 03h ; 25x80 text mode
    INT 10H ; set mode

    ; creates cursor
    mov ah,01H ;cursor shape
    MOV CX,0607H ;underline cursor
    INT 10H

    CALL DISP_MEM ;function to display file

    MOV PosX,0
    MOV PosY,0
    ;move cursor to upper left corner
    MOV AH,2h ;move cursor function.
    MOV DH,1
    MOV DL,0
    MOV BH,0  ;PAGE 0
    INT 10H ;move Cursor
    ;=======================================================
    ;get key stroke
    MOV AH,0    ;keyboard input function
    INT 16H     ;AH= scan code, AL= ASCII code

    WHILE_:
    CMP AL, 0dh ; comparing the enter key
    JNE Check_backspace
    ;------------------ Enter Key --------------
    LEA DX,new_line
    MOV AH,09h
    int 21H
    INC PosY
    MOV PosX,0
    jmp NEXT_KEY

    Check_backspace: ;deletes and moves cursor back one
    CMP AL,08h
    JNE Check_del
    CALL UPDATE_BKS_MEM
    CALL DISP_MEM
    MOV AX,PosX
    CMP AX,0
    JE LBKS1
    DEC PosX
    JMP LBKS2
    LBKS1:
    MOV AX,79
    MOV PosX,AX
    DEC PosY
    LBKS2:
    MOV DX,PosX
    MOV AX,PosY
    MOV DH,AL
    MOV AH,2
    MOV BH,0
    INT 10H
    jmp NEXT_KEY

    Check_del: ;deletes maintains cursor location
    CMP AX,5300h
    JNE press
    CALL UPDATE_DEL_MEM
    CALL DISP_MEM
    MOV AX,PosX
    CMP AX,0
    JE LDEL1
    DEC PosX
    JMP LDEL2
    LDEL1:
    MOV AX,79
    MOV PosX,AX
    DEC PosY
    LDEL2:
    MOV DX,PosX
    MOV AX,PosY
    MOV DH,AL
    MOV AH,2
    MOV BH,0
    INT 10H
    jmp NEXT_KEY

    press:
    CMP AL,1BH      ;ESC
    JNE NESC
    JMP END_WHILE    ;exits code after END_WHILE complete

    NESC:
    ;if function key
    CMP AL,0        ;AL=0;
    JNE ELSE_       ;no, character key
    ;then, function key
    CALL MOVE_ARROWS ;execute function
    JMP NEXT_KEY ;get Next keystrokes


    ELSE_: ;Display character
    PUSH AX
    MOV AL,ins_flag
    CMP AL,0
    JNE INSERT_ON
    POP AX
    CALL UPDATE_MEM
    MOV AH,2  ;display character func
    MOV DL,AL ;get character
    INT 21H   ;display character
    MOV BX,PosX
    CMP BX,79
    JE N_Line
    INC PosX
    JMP NEXT_KEY
    N_Line:
    MOV PosX,0
    INC PosY
    JMP NEXT_KEY

    INSERT_ON:
    POP AX
    CALL UPDATE_INS_MEM
    CALL DISP_MEM
    MOV BX,PosX
    CMP BX,79
    JE N_Line1
    INC PosX
    JMP INSML1
    N_Line1:
    MOV PosX,0
    INC PosY
    INSML1:
    MOV DX,PosX
    MOV AX,PosY
    MOV DH,AL
    INC DH
    MOV AH,2 ;cursor move function
    MOV BH,0
    INT 10H  ;move cursor

    NEXT_KEY:
    MOV AH,0 ;get keystroke function
    INT 16H  ;AH will scan code
    JMP WHILE_

    END_WHILE:
    CALL DISP_MEM
    EXIT_MAIN: ;EXIT

    MOV AH,42H ;for writing file
    MOV AL,0
    XOR CX,CX
    XOR DX,DX
    MOV BX,handle
    int 21h
    mov ah,40h
    mov cx,0640H   ; bytes to write.
    mov dx,offset text  ; address of data to write
    mov bx,handle
    int 21h
    mov  ah, 3eh
    int  21h
    MOV AH, 4CH
    INT 21H
    ;must close file with escape or no save.
MAIN ENDP


MOVE_ARROWS PROC
;Operates the arrow keys
;input: AH=scan code
;output: none

    PUSH BX
    PUSH CX
    PUSH DX
    PUSH AX ;save scan code

    MOV AX,PosY
    MOV DX,PosX
    MOV DH,AL
    INC DH
    POP AX


    CMP AH, 48h ;up arrow
    JNE DFS1
    CMP AL,0
    JMP CURSOR_UP
    DFS1:
    CMP AH,4Bh ;left arrow
    JNE DFS2
    CMP AL,0
    JMP CURSOR_LEFT
    DFS2:
    CMP AH, 4Dh ;right arrow
    JNE DFS3
    CMP AL,0
    JMP CURSOR_RIGHT
    DFS3:
    CMP AH, 50h ;down arrow
    JNE DFSD
    CMP AL,0
    JMP CURSOR_DOWN
    DFSD:
    JMP DF_EXIT ; other

    CURSOR_UP:
    CMP DH, 1  ; row 1
    JNE GO_UP ;if yes go MOV DOWN
    JMP DF_EXIT     ;do nothing, at first line of first page
    GO_UP:
    DEC DH ;if not then row=row-1
    DEC PosY
    JMP EXECUTE ;exceute

    CURSOR_DOWN:
    CMP DH,20 ;last row
    JNE  GO_DOWN ; if so go up
    JMP DF_EXIT ;Last line
    GO_DOWN:
    INC DH ;if not row=row+1;
    INC PosY
    JMP EXECUTE ;execute

    CURSOR_LEFT:
    CMP DL,0
    JNE GO_LEFT
    CMP DH,1
    JNE GO_BACK
    JMP DF_EXIT
    GO_BACK:
    DEC DH
    MOV DL,79
    MOV PosX,79
    DEC PosY
    JMP EXECUTE


    CURSOR_RIGHT:
    CMP DL,79
    JNE GO_RIGHT
    CMP DH,20
    JNE GO_FARWARD
    JMP DF_EXIT
    GO_FARWARD:
    INC DH
    MOV DL,0
    MOV PosX,0
    INC PosY
    JMP EXECUTE ;execute

    GO_LEFT:
    DEC DL ;col=col-1;
    DEC PosX
    JMP EXECUTE ;go to execute

    GO_RIGHT:
    INC DL ;col=col+1
    INC PosX
    JMP EXECUTE ;go to execute


    EXECUTE: ;move cursor
    MOV AH,2
    MOV BH,0
    INT 10H

    DF_EXIT:
    POP DX
    POP CX
    POP BX
    RET
MOVE_ARROWs ENDP


UPDATE_MEM PROC ;new characters to memory
    PUSH AX
    MOV AX,PosY
    MOV BX,80
    MUL BX
    MOV BX,PosX
    ADD BX,AX
    POP AX
    MOV text[BX],AL
    RET
UPDATE_MEM ENDP


UPDATE_INS_MEM PROC
    PUSH AX
    MOV AX,PosY
    MOV BX,80
    MUL BX
    MOV BX,PosX
    ADD BX,AX
    PUSH BX
    MOV AX,1600
    SUB AX,BX
    MOV CX,AX
    MOV BX,1599
    ML1:
        DEC BX
        MOV AL,text[BX]
        INC BX
        MOV text[BX],AL
        DEC BX
        LOOP ML1
    POP BX
    POP AX
    MOV text[BX],AL
    RET
UPDATE_INS_MEM ENDP

UPDATE_BKS_MEM PROC
    MOV AX,PosY
    MOV BX,80
    MUL BX
    MOV BX,PosX
    ADD BX,AX
    PUSH BX
    MOV AX,1600
    SUB AX,BX
    MOV CX,AX
    POP BX
    MBL1:
        MOV AL,text[BX]
        DEC BX
        MOV text[BX],AL
        INC BX
        INC BX
        LOOP MBL1
    RET
UPDATE_BKS_MEM ENDP


UPDATE_DEL_MEM PROC
    MOV AX,PosY
    MOV BX,80
    MUL BX
    MOV BX,PosX
    ADD BX,AX
    PUSH BX
    MOV AX,1600
    SUB AX,BX
    MOV CX,AX
    POP BX
    MODIFY1:
        INC BX
        MOV AL,text[BX]
        DEC BX
        MOV text[BX],AL
        INC BX
        LOOP MODIFY1
    RET
    UPDATE_DEL_MEM ENDP

GET_MEM PROC
    MOV AX,PosY
    MOV BX,80
    MUL BX
    MOV BX,PosX
    ADD BX,AX
    MOV DL,text[BX]
    RET
GET_MEM ENDP


DISP_MEM PROC ;displays file to screen
    MOV AX,PosX
    PUSH AX
    MOV AX,PosY
    PUSH AX
    MOV AH,2h ;move cursor function.
    MOV DH,0
    MOV DL,0
    MOV BH,0  ;PAGE 0
    INT 10H ;move Cursor
    LEA DX,title_str
    MOV AH,09h
    int 21H
    MOV AH,2h ;move cursor function.
    MOV DH,1
    MOV DL,0
    MOV BH,0  ;PAGE 0
    INT 10H ;move Cursor
    ;cursor is set to top left corner

    MOV PosX,0
    MOV PosY,0
    MOV CX,20
    dLoop1:
    PUSH CX
    MOV CX,80
    dLoop2:
    PUSH CX
    CALL GET_MEM
    MOV AH,2
    INT 21H
    MOV BX,PosX
    CMP BX,79
    JE dL2
    INC BX
    MOV PosX,BX
    JMP dL3
    dL2:
    MOV PosX,0
    INC PosY
    dL3:
    POP CX
    LOOP dLoop2
    POP CX
    LOOP dLoop1
    POP AX
    MOV PosY,AX
    POP AX
    MOV PosX,AX

    MOV AH,2h ;move cursor function.
    MOV DH,23
    MOV DL,0
    MOV BH,0  ;PAGE 0
    INT 10H ;move Cursor
    LEA DX,bottom_str
    MOV AH,09h
    int 21H
    RET
DISP_MEM ENDP

END MAIN
