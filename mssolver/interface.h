#pragma once

#include "msgame.h"
/*
* 外部调用函数定义
* 以C函数方式导出到dll
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