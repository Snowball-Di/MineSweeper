.386
.model flat,stdcall
option casemap:none

include    msgame.inc

srand  PROTO C :DWORD
rand   PROTO C 
time   PROTO C :DWORD
memset PROTO C :DWORD,:BYTE,:DWORD

extrn  	    gameState:dword
extrn		remainingMines:dword
extrn		exploredCells :dword
extrn		realBoard     :byte
extrn		playBoard     :byte
extrn		hintBoard     :byte
extrn		row_directions :dword
extrn		col_directions:dword
extrn		mine_total    :dword
extrn		Board_column  :dword
extrn		Board_row     :dword
extrn		Clicked_column:dword
extrn		Clicked_row   :dword




public Initializing
.data

Total       DWORD 0
PLACED_MINE DWORD 0
POSITION    DWORD 0
TOTAL_SCALE DWORD 0
.code

Initializing   proc
    LOCAL ROW: DWORD
    LOCAL COLUMN: DWORD
    LOCAL ROW_MAX: DWORD
    LOCAL COL_MAX: DWORD
    LOCAL Clicked_point: DWORD
    
   

    push eax
	push ebx
    push ecx
    push edx
    push esi
    push edi
	
    invoke memset,addr realBoard,0,MAX_CELLS
    invoke memset,addr playBoard,0,MAX_CELLS
    invoke memset,addr hintBoard,0,MAX_CELLS

    xor edx,edx
    mov eax,Clicked_row
    mul Board_column
    add eax,Clicked_column
    mov Clicked_point,eax
    xor eax,eax


    invoke time,0
    invoke srand,eax


    xor edx,edx
    mov eax,Board_column
    MUL Board_row
    mov TOTAL_SCALE,eax

    xor esi,esi
    .while esi < mine_total
        USED:
        invoke rand
        xor    edx,edx
        div    TOTAL_SCALE
        mov    POSITION,edx

        cmp    edx,Clicked_point
        JE     USED
        
        xor    ecx,ecx
        mov    cl,byte ptr [realBoard+edx]
        cmp    cl,MINE
        JE     USED

        mov    cl, MINE
        mov    byte ptr [realBoard+edx],cl

        INC    esi

    .endw

    xor esi,esi



    mov ecx, Board_column
    dec ecx
    mov COL_MAX, ecx

    mov ecx, Board_row
    dec ecx
    mov ROW_MAX, ecx

    .while esi < TOTAL_SCALE
        mov ebx,esi

        CMP byte ptr [realBoard+ebx], MINE
        JE  IS_MINE

        xor edx,edx
        mov eax,esi
        DIV Board_column
   
        .IF eax != 0 
            .IF edx != 0
                mov ebx, esi
                sub ebx, Board_column
                dec ebx
                .IF byte ptr [realBoard+ebx]==MINE
                    mov ecx, esi
                    inc byte ptr [realBoard+ecx]
                .ENDIF
            .ENDIF

            mov ebx, esi
            sub ebx, Board_column
            .IF byte ptr [realBoard+ebx]==MINE
                mov ecx, esi
                inc byte ptr [realBoard+ecx]
            .ENDIF

            .IF edx != COL_MAX
                mov ebx, esi
                sub ebx, Board_column
                inc ebx
                .IF byte ptr [realBoard+ebx]==MINE
                    mov ecx, esi
                    inc byte ptr [realBoard+ecx]
                .ENDIF
            .ENDIF

        .ENDIF


        .IF edx != 0
            mov ebx, esi
            dec ebx
            .IF byte ptr [realBoard+ebx]==MINE
                mov ecx, esi
                inc byte ptr [realBoard+ecx]
            .ENDIF
        .ENDIF

        .IF edx != COL_MAX
            mov ebx, esi
            inc ebx
            .IF byte ptr [realBoard+ebx]==MINE
                mov ecx, esi
                inc byte ptr [realBoard+ecx]
            .ENDIF
        .ENDIF




        .IF eax != ROW_MAX
            .IF edx != 0
                mov ebx, esi
                add ebx, Board_column
                dec ebx
                .IF byte ptr [realBoard+ebx]==MINE
                    mov ecx, esi
                    inc byte ptr [realBoard+ecx]
                .ENDIF
            .ENDIF

            mov ebx, esi
            add ebx, Board_column
            .IF byte ptr [realBoard+ebx]==MINE
                mov ecx, esi
                inc byte ptr [realBoard+ecx]
            .ENDIF

            .IF edx != COL_MAX
                mov ebx, esi
                add ebx, Board_column
                inc ebx
                .IF byte ptr [realBoard+ebx]==MINE
                    mov ecx, esi
                    inc byte ptr [realBoard+ecx]
                .ENDIF
            .ENDIF

        .ENDIF



    IS_MINE:
        INC esi

    .endw


    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
Initializing endp

end