.386
.model flat,stdcall
option casemap:none

include    msgame.inc

; global function declarations
public runHint


generateHint proto	:dword, :dword, :byte


; *** external variables ***
extern	playBoard:dword
extern	hintBoard:dword

extern	Board_column:dword
extern	Board_row:dword
extern	Clicked_column:dword
extern  Clicked_row:dword

extern	row_directions:dword
extern  col_directions:dword


; *** internal variables ***
.data

; --- stack<Point> BFSջ ---
STACK_SIZE		equ	MAX_CELLS
stacktop		dword 0
stackbase		dword STACK_SIZE DUP(-1)
stackend		dword 0

bfsVisitFlags	byte MAX_CELLS DUP(0)
; --------------------




.code

; --- stack<Point> ---
;
; ���ݽṹ stack ��ʵ�֣�ջԪ��Ϊ pair<int, int>
; ѹջ��ջ���������ջ����������� �޷���ֵ
; stack_init �Ὣջ��� ʹ��ǰ�������

stack_init proc
	lea		eax, stackbase
	mov		stacktop, eax
	ret
stack_init endp

stack_empty proc
	lea		eax, stackbase
	cmp		eax, stacktop
	je		base_eq_top
		; ջ�ǿ�
		mov		eax, 0
		ret
	base_eq_top:
		; ջΪ��
		mov		eax, 1
		ret
stack_empty endp

stack_full proc
	lea		eax, stackend
	; ջ�ڴ��������һ����ַӦΪstackbase�����stackend  ������ջ��ָ�����Ƚ�
	cmp		eax, stacktop
	je		stack_is_full
		mov		eax, 0
		ret
	stack_is_full:
		mov		eax, 1
		ret
stack_full endp

stack_push proc		row:dword, col:dword
	push	ebx
	; ����������ѹջ
	mov		ebx, stacktop ; ȡջ��ָ��
	mov		eax, row
	mov		[ebx], eax
	add		ebx, 4
	mov		eax, col
	mov		[ebx], eax
	add		ebx, 4
	mov		stacktop, ebx ; дջ��ָ��

	pop		ebx
	ret
stack_push endp

stack_pop proc		prow:dword, pcol:dword
	mov		ebx, stacktop ; ȡջ��ָ��
	sub		ebx, 4
	mov		eax, [ebx]	; eaxΪջ��Ԫ��
	mov		ecx, prow	; ȡָ������
	mov		[ecx], eax	; ��ջ��Ԫ��д��ָ��ָ����ڴ�
	sub		ebx, 4
	mov		eax, [ebx]
	mov		ecx, pcol
	mov		[ecx], eax
	mov		stacktop, ebx ; дջ��ָ��
	ret
stack_pop endp

; --------------------

; --- �鿴������Ϣ�ĸ������� ---


; �ж�λ�������Ƿ�Խ��
; �������Ϊ dword �з�������
pointInBounds proc	row:dword, col:dword
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
pointInBounds endp

; ��ά����Ѱַ
; ���� byte playBoard[row][col] (�����al��)
playBoardAccess	proc	row:dword, col:dword
	mov		ebx, row
	mul		Board_column  ; (����edx)
	add		ebx, col
	; eaxΪһά��������ֵ
	xor		eax, eax
	mov		al, byte ptr [playBoard+ebx]
	ret
playBoardAccess endp

; �ж�һ����Ԫ���Ƿ�Ϊ����
isNumberCell proc	cell:byte
	mov		al, cell
	.IF	al <= NUMBER_8
		.IF al >= NUMBER_0
			mov	eax, 1
			ret
		.ENDIF
	.ENDIF
	mov		eax, 0
	ret
isNumberCell endp

; ����ĳ��Ԫ������ڸ�
iterNeighbors proc	row:dword, col:dword
	local	currentRow:dword
	local	currentCol:dword

	xor		ecx, ecx
	.WHILE ecx < 8
		; ������8��������ھ�����
		mov		eax, row
		add		eax, row_directions[ecx*4]
		mov		currentRow, eax
		mov		eax, col
		add		eax, col_directions[ecx*4]
		mov		currentCol, eax
		; �ټ���Ƿ�Խ��
		invoke	pointInBounds, currentRow, currentCol
		.IF eax == 0
			.CONTINUE
		.ENDIF
		; Ȼ���úϷ�����Ѱַ�õ���Ԫ��
		invoke	playBoardAccess, currentRow, currentCol
		; ��ִ����ز��� ���翴�ǲ�����
		.IF al == MINE
			;...
		.ENDIF

		inc		ecx
	.ENDW
	xor		eax, eax
	ret
iterNeighbors endp

; --------------------








doBFSSolvable proc	srcRow:dword, srcCol:dword
	local	row:dword
	local	col:dword
	local	neighborRow:dword
	local	neighborCol:dword
	local	statsExplored:dword
	local	statsFlaged:dword
	local	statsUnknown:dword

	; ��ʼ�� bfsVisitFlags
	mov		eax, Board_row
	mul		Board_column
	mov		ecx, eax
	xor		ebx, ebx
	.WHILE	ebx < ecx
		mov		byte ptr bfsVisitFlags[ebx], 0
		add		ebx, 1
	.ENDW

	invoke	stack_init
	invoke	stack_push, srcRow, srcCol
	mov		eax, srcRow
	mul		Board_column
	add		eax, srcCol
	mov		byte ptr bfsVisitFlags[eax], 1

	; �������������ѭ��
	bfs_while_begin:
		; ѭ�� ֱ��ջΪ��
		invoke	stack_empty	
		cmp		eax, 1
		je		bfs_while_end

		; ����ջ��Ԫ��
		invoke	stack_pop, addr row, addr col

		; �ȼ�鵱ǰ��ջ�ĸ� �������ַ����������� ����Ȼ�������ھ���ջ
		invoke	playBoardAccess, row, col
		invoke	isNumberCell, al
		cmp		eax, 0
		je		bfs_ignore_check
		; ���������ָ� ͳ����Χ�������Ϣ
		mov		statsExplored, 0
		mov		statsFlaged, 0
		mov		statsUnknown, 0
		xor		ecx, ecx
		.WHILE ecx < 8
			; ������8��������ھ�����
			mov		eax, row
			add		eax, row_directions[ecx*4]
			mov		neighborRow, eax
			mov		eax, col
			add		eax, col_directions[ecx*4]
			mov		neighborCol, eax
			; �ټ���Ƿ�Խ��
			invoke	pointInBounds, neighborRow, neighborCol
			.IF eax == 0
				inc		ecx
				.CONTINUE
			.ENDIF
			; Ȼ���úϷ�����Ѱַ�õ���Ԫ��
			invoke	playBoardAccess, neighborRow, neighborCol
			; ��ִ����ز���
			.IF al == FLAGED
				add		statsFlaged, 1
			.ELSEIF	al == UNKNOWN
				add		statsUnknown, 1
			.ELSE
				add		statsExplored, 1
			.ENDIF

			inc		ecx
		.ENDW
		
		; ����1 ����+δ̽�� == ����
		; ���� ����Χ������δ̽�������ж�Ϊ�� ����Ҫ������ұ���
		xor		eax, eax
		invoke	playBoardAccess, row, col
		mov		ebx, statsFlaged
		add		ebx, statsUnknown
		.IF eax == ebx
			invoke	generateHint, row, col, HINT_CLUE
			; ִ�� ����Χ�ķ����ַ�����ʾΪ��
			xor		ecx, ecx
			.WHILE ecx < 8
				mov		eax, row
				add		eax, row_directions[ecx*4]
				mov		neighborRow, eax
				mov		eax, col
				add		eax, col_directions[ecx*4]
				mov		neighborCol, eax
				invoke	pointInBounds, neighborRow, neighborCol
				.IF eax == 0
					inc		ecx
					.CONTINUE
				.ENDIF
				invoke	playBoardAccess, neighborRow, neighborCol
				invoke  isNumberCell, al
				.IF al == 0
					invoke	generateHint, neighborRow, neighborCol, HINT_MINE
				.ENDIF

				inc		ecx
			.ENDW
			; TODO ע�� ��ʾ��ʾʱ���������ҵı��ף���ʾ��ʱ��ҲӦ�������ж�

			; ������ʾ ��������
			jmp		ret_success
		.ENDIF

		; ����2 ���� == ����
		; ���� ����Χ����δ̽�������ж�Ϊ�� !��Ҫ!������ҵı�����ȷ
		; ��ʱ�����ò���

		; ˫�������� �߼����ܸ�������1

		bfs_ignore_check:
		; �����ĸ����ھ���ջ ��ջ����Ϸ���=1
		xor		ecx, ecx
		.WHILE ecx < 8
			; ������8��������ھ�����
			mov		eax, row
			add		eax, row_directions[ecx*4]
			mov		neighborRow, eax
			mov		eax, col
			add		eax, col_directions[ecx*4]
			mov		neighborCol, eax
			; ����Ƿ�Խ��
			invoke	pointInBounds, neighborRow, neighborCol
			.IF eax == 0
				inc		ecx
				.CONTINUE
			.ENDIF
			; �ټ���Ƿ����
			mov		ebx, neighborRow
			mul		Board_column
			add		ebx, neighborCol
			mov		al, byte ptr bfsVisitFlags[ebx]
			.IF al == 1
				inc		ecx
				.CONTINUE
			.ENDIF

			invoke	stack_push, neighborRow, neighborCol	; ��ջ
			mov		byte ptr bfsVisitFlags[ebx], 1			; ���ʱ����1

			inc		ecx
		.ENDW

		jmp	bfs_while_begin
	bfs_while_end:

	mov		eax, 0
	ret
	ret_success:
	mov		eax, 1
	ret
doBFSSolvable endp



generateHint proc	row:dword, col:dword, info:byte
	mov		eax, row
	mul		Board_column
	add		eax, col
	mov		bl, info
	mov		byte ptr hintBoard[eax], bl
	ret
generateHint endp


runHint proc
	invoke	doBFSSolvable, Clicked_row, Clicked_column
	ret
runHint endp

end