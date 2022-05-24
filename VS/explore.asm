.386
.model flat, stdcall
option casemap:none

include msgame.inc

public singleExplore	;one pixel explore
public flagThePosition	;flag the position
public autoClick		;auto explore the neighbours
public explore			;explore pixel and expand explore the neighbours
public changeGameState	;check if win or lose


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
visited		byte		max_size dup(0) ;visit

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
	push ebx
	mov		ebx, sTop
	mov		eax, row
	mov		[ebx], eax
	add		ebx, 4
	mov		eax, col
	mov		[ebx], eax
	add		ebx, 4
	mov		sTop, ebx
	pop ebx
	ret
sPush endp

sPop proc col:dword, row:dword	
	push ebx
	push ecx
	mov ebx, sTop
	sub ebx, 4
	mov eax, [ebx]
	mov ecx, row
	mov [ecx], eax
	sub ebx, 4
	mov eax, [ebx]
	mov ecx, col
	mov [ecx], eax
	mov sTop, ebx;
	pop ecx
	pop ebx
	ret
sPop endp


accessPB proc row:dword, col:dword
	mov eax, row
	mul Board_column
	add eax, col
	mov al, byte ptr playBoard[eax]
	ret
accessPB endp

accessAB proc row:dword, col:dword
	mov eax, row
	mul Board_column
	add eax, col
	mov al, byte ptr realBoard[eax]
	ret
accessAB endp

;check if number
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

;check boundary
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

singleExplore proc	row:dword, col:dword
	push ebx
	invoke accessPB, row, col
	.if al == UNKNOWN
		invoke accessAB, row, col
		.if al == MINE
			mov eax, row
			mul Board_column
			add eax, col
			mov byte ptr playBoard[eax], EXPLODED
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
singleExplore endp

explore proc row:dword, col:dword
	local nbrow:dword
	local nbcol:dword
	local cur_row:dword
	local cur_col:dword
	push ecx
	push ebx
	invoke accessAB, row, col
	.if al == 0
		invoke sInit
		invoke sPush, row, col
		mov		eax, Board_row
		mul		Board_column
		mov		ecx, eax
		xor		ebx, ebx
		.WHILE	ebx < ecx
			mov		byte ptr visited[ebx], 0
			add		ebx, 1
		.ENDW

		bfs:
			invoke sEmpty
			cmp al, 1
			je return 
			invoke sPop, addr cur_row, addr cur_col
			invoke accessAB, cur_row, cur_col
			.if al == 0
			xor ecx, ecx
				.while ecx < 8
					mov		eax, cur_row
					add		eax, row_directions[ecx*4]
					mov		nbrow, eax
					mov		eax, cur_col
					add		eax, col_directions[ecx*4]
					mov		nbcol, eax
					invoke	legalCor, nbrow, nbcol
					.if eax == 0
						inc ecx
						.continue
					.endif

					mov		eax, nbrow
					mul		Board_column
					add		eax, nbcol
					mov		al, byte ptr visited[eax]

					.if al == 1
						inc ecx
						.continue
					.endif

					mov		eax, nbrow
					mul		Board_column
					add		eax, nbcol
					mov		byte ptr visited[eax], 1

					invoke	accessPB, nbrow, nbcol
					;.if al == UNKNOWN
						invoke sPush, nbrow, nbcol
					;.endif
					inc		ecx
				.ENDW
			.endif
			invoke singleExplore, cur_row, cur_col
			jmp bfs
	.endif

	invoke singleExplore, row, col
	return:
	pop ecx
	pop ebx
	ret
explore endp

autoClick proc row:dword, col:dword
	local flag:	byte
	local nbrow:	dword
	local nbcol:	dword
	push ecx
	push ebx
	invoke accessAB, row, col
	invoke isNumber, al
	cmp eax, 1
	je autoclick
	pop ebx
	pop ecx
	ret
	autoclick:
		xor al, al
		mov flag, 0
		xor ecx, ecx

		.while ecx < 8
			mov		eax, row
			add		eax, row_directions[ecx*4]
			mov		nbrow, eax
			mov		eax, col
			add		eax, col_directions[ecx*4]
			mov		nbcol, eax
			invoke	legalCor, nbrow, nbcol
			.if eax == 0
			inc ecx
				.continue
			.endif
			invoke	accessPB, nbrow, nbcol
			.if al == FLAGED
				add flag, 1
			.endif
			inc		ecx
		.ENDW

		mov cl, flag
		invoke accessAB, row, col
		.if cl == al
			xor ecx, ecx
			.while ecx < 8
				mov		eax, row
				add		eax, row_directions[ecx*4]
				mov		nbrow, eax
				mov		eax, col
				add		eax, col_directions[ecx*4]
				mov		nbcol, eax
				invoke	legalCor, nbrow, nbcol
				.if eax == 0
					inc ecx
					.continue
				.endif
				invoke	accessPB, nbrow, nbcol
				.if al == UNKNOWN
					invoke explore, nbrow, nbcol
				.endif
				inc		ecx
			.ENDW
		.endif
	pop ebx
	pop ecx
	ret
autoClick endp

checkWin proc
	push ebx
	push ecx
	mov		eax, Board_row
	mul		Board_column
	mov		ecx, eax
	xor		ebx, ebx
	.WHILE	ebx < ecx
		mov dl, byte ptr playBoard[ebx]
		mov dh, byte ptr realBoard[ebx]
		invoke isNumber, dh
		.if al == 1
			invoke isNumber, dl
			cmp al, 0
			je notwin
		.endif
		inc ebx
	.ENDW
	mov gameState, STATE_WIN
	notwin:
		pop ecx
		pop ebx
		ret
checkWin endp

showAnswer proc
	push ebx
	push ecx
	push edx
	mov		eax, Board_row
	mul		Board_column
	mov		ecx, eax
	xor		ebx, ebx
	.WHILE	ebx < ecx
		mov dl, byte ptr playBoard[ebx]
		mov dh, byte ptr realBoard[ebx]
		.if dl == FLAGED
			.if dh == MINE
				inc ebx
				.continue
			.endif
			mov byte ptr playBoard[ebx], FLAG_WRONG
		.endif

		.if dl == UNKNOWN
			mov byte ptr playBoard[ebx], dh
			.if dh == MINE
			mov byte ptr playBoard[ebx], EXPLODED
			.endif
		.endif
		inc ebx
	.ENDW
	pop edx
	pop ecx
	pop ebx
	ret
showAnswer endp

checklose proc
	push ebx
	push ecx
	mov		eax, Board_row
	mul		Board_column
	mov		ecx, eax
	xor		ebx, ebx
	.WHILE	ebx < ecx
		mov al, byte ptr playBoard[ebx]
		.if al == EXPLODED
			mov gameState, STATE_LOSE
			invoke showAnswer
			jmp lose
		.endif
		inc ebx
	.ENDW
	lose:
	pop ecx
	pop ebx
	ret
checklose endp

changeGameState proc
	invoke checkWin
	invoke checklose
	ret
changeGameState endp

end