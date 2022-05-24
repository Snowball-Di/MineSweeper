#include "pch.h"
#include "msgame.h"


void* CallHint(
	int board_width,
	int board_height,
	int total_mines,
	unsigned char* board,
	unsigned char* hints
	)
{
	Board<Cell> playBoard(board_width, board_height, (Cell*)board);
	Board<Hint> hintBoard(board_width, board_height, (Hint*)board);


	return nullptr;
}
