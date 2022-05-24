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

; --- stack<Point> BFS栈 ---
STACK_SIZE		equ	MAX_CELLS
stacktop		dword 0
stackbase		dword STACK_SIZE DUP(-1)
stackend		dword 0

bfsVisitFlags	byte MAX_CELLS DUP(0)
; --------------------




.code

; --- stack<Point> ---
;
; 数据结构 stack 的实现，栈元素为 pair<int, int>
; 压栈入栈操作不检查栈的上溢和下溢 无返回值
; stack_init 会将栈清空 使用前必须调用

stack_init proc
	lea		eax, stackbase
	mov		stacktop, eax
	ret
stack_init endp

stack_empty proc
	lea		eax, stackbase
	cmp		eax, stacktop
	je		base_eq_top
		; 栈非空
		mov		eax, 0
		ret
	base_eq_top:
		; 栈为空
		mov		eax, 1
		ret
stack_empty endp

stack_full proc
	lea		eax, stackend
	; 栈内存区域的下一个地址应为stackbase后面的stackend  将它与栈顶指针做比较
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
	; 将两个变量压栈
	mov		ebx, stacktop ; 取栈顶指针
	mov		eax, row
	mov		[ebx], eax
	add		ebx, 4
	mov		eax, col
	mov		[ebx], eax
	add		ebx, 4
	mov		stacktop, ebx ; 写栈顶指针

	pop		ebx
	ret
stack_push endp

stack_pop proc		prow:dword, pcol:dword
	mov		ebx, stacktop ; 取栈顶指针
	sub		ebx, 4
	mov		eax, [ebx]	; eax为栈顶元素
	mov		ecx, prow	; 取指针内容
	mov		[ecx], eax	; 将栈顶元素写到指针指向的内存
	sub		ebx, 4
	mov		eax, [ebx]
	mov		ecx, pcol
	mov		[ecx], eax
	mov		stacktop, ebx ; 写栈顶指针
	ret
stack_pop endp

; --------------------

; --- 查看盘面信息的辅助函数 ---


; 判断位置坐标是否越界
; 两坐标均为 dword 有符号整数
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

; 二维数组寻址
; 返回 byte playBoard[row][col] (存放在al中)
playBoardAccess	proc	row:dword, col:dword
	mov		ebx, row
	mul		Board_column  ; (忽略edx)
	add		ebx, col
	; eax为一维数组索引值
	xor		eax, eax
	mov		al, byte ptr [playBoard+ebx]
	ret
playBoardAccess endp

; 判断一个单元格是否为数字
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

; 遍历某单元格的相邻格
iterNeighbors proc	row:dword, col:dword
	local	currentRow:dword
	local	currentCol:dword

	xor		ecx, ecx
	.WHILE ecx < 8
		; 先生成8个方向的邻居坐标
		mov		eax, row
		add		eax, row_directions[ecx*4]
		mov		currentRow, eax
		mov		eax, col
		add		eax, col_directions[ecx*4]
		mov		currentCol, eax
		; 再检查是否越界
		invoke	pointInBounds, currentRow, currentCol
		.IF eax == 0
			.CONTINUE
		.ENDIF
		; 然后用合法坐标寻址得到单元格
		invoke	playBoardAccess, currentRow, currentCol
		; 再执行相关操作 例如看是不是雷
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

	; 初始化 bfsVisitFlags
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

	; 广度优先搜索主循环
	bfs_while_begin:
		; 循环 直到栈为空
		invoke	stack_empty	
		cmp		eax, 1
		je		bfs_while_end

		; 弹出栈顶元素
		invoke	stack_pop, addr row, addr col

		; 先检查当前出栈的格 不是数字方格就跳过检查 但仍然会引起邻居入栈
		invoke	playBoardAccess, row, col
		invoke	isNumberCell, al
		cmp		eax, 0
		je		bfs_ignore_check
		; 对所有数字格 统计周围方格的信息
		mov		statsExplored, 0
		mov		statsFlaged, 0
		mov		statsUnknown, 0
		xor		ecx, ecx
		.WHILE ecx < 8
			; 先生成8个方向的邻居坐标
			mov		eax, row
			add		eax, row_directions[ecx*4]
			mov		neighborRow, eax
			mov		eax, col
			add		eax, col_directions[ecx*4]
			mov		neighborCol, eax
			; 再检查是否越界
			invoke	pointInBounds, neighborRow, neighborCol
			.IF eax == 0
				inc		ecx
				.CONTINUE
			.ENDIF
			; 然后用合法坐标寻址得到单元格
			invoke	playBoardAccess, neighborRow, neighborCol
			; 再执行相关操作
			.IF al == FLAGED
				add		statsFlaged, 1
			.ELSEIF	al == UNKNOWN
				add		statsUnknown, 1
			.ELSE
				add		statsExplored, 1
			.ENDIF

			inc		ecx
		.ENDW
		
		; 条件1 旗帜+未探索 == 数字
		; 动作 将周围的所有未探索方格判定为雷 不需要信任玩家标雷
		xor		eax, eax
		invoke	playBoardAccess, row, col
		mov		ebx, statsFlaged
		add		ebx, statsUnknown
		.IF eax == ebx
			invoke	generateHint, row, col, HINT_CLUE
			; 执行 对周围的非数字方格提示为雷
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
			; TODO 注意 显示提示时必须忽略玩家的标雷，显示的时候也应该做好判断

			; 已有提示 立即返回
			jmp		ret_success
		.ENDIF

		; 条件2 旗帜 == 数字
		; 动作 将周围所有未探索方格判定为空 !需要!信任玩家的标雷正确
		; 暂时放弃该策略

		; 双数字推理 逻辑上能覆盖条件1

		bfs_ignore_check:
		; 将它的各个邻居入栈 入栈后标上访问=1
		xor		ecx, ecx
		.WHILE ecx < 8
			; 先生成8个方向的邻居坐标
			mov		eax, row
			add		eax, row_directions[ecx*4]
			mov		neighborRow, eax
			mov		eax, col
			add		eax, col_directions[ecx*4]
			mov		neighborCol, eax
			; 检查是否越界
			invoke	pointInBounds, neighborRow, neighborCol
			.IF eax == 0
				inc		ecx
				.CONTINUE
			.ENDIF
			; 再检查是否访问
			mov		ebx, neighborRow
			mul		Board_column
			add		ebx, neighborCol
			mov		al, byte ptr bfsVisitFlags[ebx]
			.IF al == 1
				inc		ecx
				.CONTINUE
			.ENDIF

			invoke	stack_push, neighborRow, neighborCol	; 入栈
			mov		byte ptr bfsVisitFlags[ebx], 1			; 访问标记置1

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