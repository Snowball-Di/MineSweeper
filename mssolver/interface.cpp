#include "pch.h"
#include "interface.h"
#include "msgame.h"


extern "C" __declspec(dllexport) void* CallHint(
	int board_width,
	int board_height,
	int total_mines,
	unsigned char* board,
	unsigned char* hints,
	int clicked_row,
	int clicked_column
)
{
	Board<Cell> playBoard(board_width, board_height, (Cell*)board);
	Board<Hint> hintBoard(board_width, board_height, (Hint*)hints);

	for (int i = 0; i < playBoard.width; i++) {
		for (int j = 0; j < playBoard.height; j++) {
			hintBoard.set(Pos(i, j), Hint::hint_safe);
		}
	}
	

	return nullptr;
}
