.386
.model flat, stdcall
option casemap:none

include msgame.inc

public explore ;探索
public flagThePosition	;标旗
public autoFlag	;自动插旗


;external variables 
extern playBoard:dword
extern realBoard:dword

extern Board_column:dword
extern Board_row:dword
extern	Clicked_column:dword
extern  Clicked_row:dword

extern	row_directions:dword
extern  col_directions:dword
extern  gameState:dword

extern flaggedMinesCorrect:dword
extern flaggedMinesTotal:dword

.data
;------- stack --------
max_size	equ			MAX_CELLS 
sTop		dword		0
sBase		dword		max_size dup(-1)
sEnd		dword		0
visited		byte		max_size dup(0) ;visit图

;--------- cur col&row ---------
cur_row		dword		0
cur_col		dword		0


.code
sInit proc
	lea		eax, sBase
	mov		sTop, eax
	ret
sInit endp

sEmpty proc
	lea		eax, sBase
	cmp		eax, sTop
	je		base_eq_top
	
	mov eax, 0
	ret

	base_eq_top:
		mov eax, 1
		ret
sEmpty endp

sPush proc	row:dword, col:dword	
	mov		ebx, sTop
	mov		eax, row
	mov		[ebx], eax
	add		ebx, 4
	mov		eax, col
	mov		[ebx], eax
	mov		sTop, ebx
	ret
sPush endp

sPop proc row:dword, col:dword	
	mov ebx, sTop
	sub ebx, 4
	mov eax, [ebx]
	mov [row], eax
	sub ebx, 4
	mov eax, [ebx]
	mov [col], eax
	mov sTop, ebx;
	ret
sPop endp


accessPB proc row:dword, col:dword
	mov eax, row
	mul Board_row
	add eax, col
	mov al, byte ptr playBoard[eax]
	ret
accessPB endp

accessAB proc row:dword, col:dword
	mov eax, row
	mul Board_row
	add eax, col
	mov al, byte ptr realBoard[eax]
	ret
accessAB endp

;判定
isNumber proc cell:byte
	mov		al, cell
	.IF	al <= NUMBER_8
		.IF al >= NUMBER_0
			mov	eax, 1
			ret
		.ENDIF
	.ENDIF
	mov		eax, 0
	ret
isNumber endp

;check boundary检查是否越界
legalCor proc row:dword, col:dword
	mov		eax, row
	.IF	eax >= Board_row
		jmp	out_of_bounds
	.ENDIF
	.IF	eax < 0
		jmp	out_of_bounds
	.ENDIF
	mov		eax, col
	.IF	eax >= Board_column
		jmp	out_of_bounds
	.ENDIF
	.IF	eax < 0
		jmp	out_of_bounds
	.ENDIF
	mov		eax, 1
	ret

	out_of_bounds:
		mov		eax, 0
		ret
legalCor endp

flagThePosition proc row:dword, col:dword
	invoke accessPB, row, col
	.if al == UNKNOWN
		mov eax, row
		mul Board_column
		add eax, col
		mov byte ptr playBoard[eax], FLAGED
		mov eax, flaggedMinesTotal
		add eax, 1
		mov flaggedMinesTotal, eax
		ret
	.endif

	.if al == FLAGED
		mov eax, row
		mul Board_column
		add eax, col
		mov byte ptr playBoard[eax], UNKNOWN
		mov eax, flaggedMinesTotal
		sub eax, 1
		mov flaggedMinesTotal, eax
		ret
	.endif
	ret
flagThePosition	endp

autoFlag proc row:dword, col:dword
	local unknown:	byte
	local nbrow:	dword
	local nbcol:	dword
	invoke accessAB, row, col
	invoke isNumber, al
	;操作位置是数字
	cmp eax, 1
	je autoflag
	ret
	autoflag:
		xor al, al
		mov unknown, 0
		xor ecx, ecx

		.while ecx < 8
			mov		eax, row
			add		eax, row_directions[ecx*4]
			mov		nbrow, eax
			mov		eax, col
			add		eax, col_directions[ecx*4]
			mov		nbcol, eax
			; 检查是否越界
			invoke	legalCor, nbrow, nbcol
			.if eax == 0
				.continue
			.endif
			; 获取该格子状态
			invoke	accessPB, nbrow, nbcol
			; 再执行相关操作
			.if al == UNKNOWN
				add unknown, 1
			.endif
			inc		ecx
		.ENDW

		mov ah, unknown
		.if ah == al
			.while ecx < 8
				mov		eax, row
				add		eax, row_directions[ecx*4]
				mov		nbrow, eax
				mov		eax, col
				add		eax, col_directions[ecx*4]
				mov		nbcol, eax
				; 检查是否越界
				invoke	legalCor, nbrow, nbcol
				.if eax == 0
					.continue
				.endif
				; 获取该格子状态
				invoke	accessPB, nbrow, nbcol
				; 再执行相关操作
				.if al == UNKNOWN
					invoke flagThePosition, nbrow, nbcol
				.endif
				inc		ecx
			.ENDW
		.endif
	ret
autoFlag endp

explore proc	row:dword, col:dword
	push ebx
	invoke accessPB, row, col
	.if al == UNKNOWN
		invoke accessAB, row, col
		.if al == MINE
			mov gameState, STATE_LOSE
			pop ebx
			ret
		.endif
		mov bl, al
		mov eax, row
		mul Board_column
		add eax, col
		mov byte ptr playBoard[eax], bl
		pop ebx
		ret
	.endif
	pop ebx
	ret
explore endp

end