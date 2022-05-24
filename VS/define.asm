.386
.model flat,stdcall
option casemap:none

include msgame.inc

public  	gameState
public		flaggedMinesCorrect, flaggedMinesTotal
public		remainingMines
public		exploredCells
public		realBoard
public		playBoard
public		hintBoard
public		row_directions
public		col_directions
public		mine_total
public		Board_column
public		Board_row
public		Clicked_column
public		Clicked_row
public		showHint

.data
; --- ��Ϸȫ�������� ---
gameState       dword 0
showHint		dword 0

flaggedMinesCorrect		dword 0
flaggedMinesTotal		dword 0
remainingMines			dword 0
exploredCells			dword 0

realBoard       byte MAX_CELLS DUP(0)
playBoard       byte MAX_CELLS DUP(0)
hintBoard       byte MAX_CELLS DUP(0)

; --- ������������ ---
; ������ �ܼӵ��������γ�8���������������
row_directions  dword  0,  1,  1,  1,  0, -1, -1, -1
col_directions  dword -1, -1,  0,  1,  1,  1,  0, -1

mine_total      dword 0 ;��¼�׵�����
Board_column    dword 0 ;ͼ��������
Board_row       dword 0 ;ͼ��������
Clicked_column  dword 0 ;��һ�������λ��
Clicked_row     dword 0 ;��һ�������λ��



end