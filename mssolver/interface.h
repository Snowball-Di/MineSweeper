#pragma once

#include "msgame.h"
/*
* �ⲿ���ú�������
* ��C������ʽ������dll
* extern "C" __declspec(dllexport)
*/

extern "C" __declspec(dllexport) int CallHint(
	int board_width,
	int board_height,
	int total_mines,
	unsigned char* board,
	unsigned char* hints,
	int clicked_row,
	int clicked_column
);