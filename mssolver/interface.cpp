#include "pch.h"
#include "interface.h"
#include "msgame.h"
#include "solver.h"


extern "C" __declspec(dllexport) int CallHint(
	int board_width,
	int board_height,
	int total_mines,
	unsigned char* board,
	unsigned char* hints,
	int clicked_row,
	int clicked_column
)
{
	Board<Cell> playBoard(board_width, board_height, Cell::unknown);
	Board<Hint> hintBoard(board_width, board_height, (Hint*)hints);

	// ��������ұ��ף����ȴ���һ������playBoard����board���ݸ���
	for (int i = 0; i < playBoard.height; i++) {
		for (int j = 0; j < playBoard.width; j++) {
			Cell cell = (Cell)board[i * board_width + j];
			if (cell == Cell::marked)
				playBoard.set(Pos(i, j), Cell::unknown);
			else
				playBoard.set(Pos(i, j), cell);

			hintBoard.set(Pos(i, j), Hint::hint_none);
		}
	}

	Game game(board_width, board_height, total_mines, &playBoard);
	Solver solver(true);
	solver.setGame(&game);
	solver.run();
	
	for (auto it = solver.safes.begin(); it != solver.safes.end(); it++) {
		hintBoard.set(*it, Hint::hint_safe);
	}

	// �Ա�������ı��׺���ұ���
	for (int i = 0; i < playBoard.height; i++) {
		for (int j = 0; j < playBoard.width; j++) {
			Cell cell = (Cell)board[i * board_width + j];
			if (cell != Cell::marked) {
				if (game.getBoard()->get(Pos(i, j)) == Cell::marked) {
					hintBoard.set(Pos(i, j), Hint::hint_mine);
				}
			}
		}
	}

	return 0;
}
