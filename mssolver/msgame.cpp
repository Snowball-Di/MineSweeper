#include "pch.h"
#include "msgame.h"



int Game::explore(const Pos& pos, std::vector<Pos>& cell_list)
{
    if (!this->board->inBounds(pos))
    {   // 边界检查
        return -1;
    }
    if (this->state != GameState::playing)
    {   // 不处于游戏内则不允许点击
        return -1;
    }

    if (!cell_list.empty())
    {
        cell_list.clear();
    }

    // 获取该单元格的答案
    Cell cell = this->real_board->get(pos);
    if (cell == Cell::mine)
    {   // 左键踩雷了
        this->board->set(pos, Cell::mine);
        // 更新游戏状态
        this->state = GameState::lose;
    }
    else
    {
        exploreClearCell(pos, cell_list);
        // 判断游戏是否结束（更新游戏状态）
        if (this->num_unexplored == this->mines)
        {
            this->state = GameState::win;
        }
    }
    return 0;
}

void Game::exploreClearCell(const Pos& pos, std::vector<Pos>& cell_list)
{   // 保证被点击单元格不是雷
    // 检查此单元格是否被探索过
    Cell seen_cell = this->board->get(pos);
    if (seen_cell != Cell::unknown && seen_cell != Cell::marked)
    {
        return;
    }

    Cell cell = this->real_board->get(pos);
    if (cell == Cell::blank)
    {   // 遇到空白格，递归地探索它周围的格
        this->board->set(pos, Cell::blank);
        this->num_unexplored--;
        std::vector<Pos> list; list.reserve(8);
        this->getNeighbors(pos, list);
        std::vector<Pos>::iterator it;
        for (it = list.begin(); it != list.end(); it++)
        {
            exploreClearCell(*it, cell_list);
        }
    }
    else
    {   // 遇到数字1-8，则只点开它
        this->board->set(pos, this->real_board->get(pos));
        this->num_unexplored--;
        cell_list.push_back(pos);
    }
}

int Game::mark(const Pos& pos)
{
    if (!this->board->inBounds(pos))
    {   // 边界检查
        return -1;
    }
    if (this->state != GameState::playing)
    {   // 不处于游戏内则不允许点击
        return -1;
    }
    Cell seen_cell = this->board->get(pos);
    if (seen_cell == Cell::unknown)
    {
        this->board->set(pos, Cell::marked);
        this->num_marked++;
    }
    else if (seen_cell == Cell::marked)
    {
        this->board->set(pos, Cell::unknown);
        this->num_marked--;
    }
    else
    {   // 标记了已探索的单元格，也返回失败(-1)
        return -1;
    }
    return 0;
}

void Game::startGame(const Pos& pos) {

}
/*
{
    if (this->state == GameState::playing)
    {
        // 会覆盖当前游戏进程，但不阻止
    }

    // 初始化答案雷盘
    this->real_board = new Board<Cell>(Cell::blank);
    for (int mine_placed = 0; mine_placed < TOTAL_MINES; mine_placed++)
    {
        int x, y;
        do {
            x = rand() % HEIGHT;
            y = rand() % WIDTH;
        } while (this->real_board->cells[x][y] == Cell::mine);
        this->real_board->cells[x][y] = Cell::mine;
    }
    for (int row = 0; row < HEIGHT; row++)
    {
        for (int col = 0; col < WIDTH; col++)
        {
            if (this->real_board->cells[row][col] == Cell::mine)
                continue;
            int number = 0;
            std::vector<Pos> list; list.reserve(8);
            this->getNeighbors(Pos(row, col), list);
            std::vector<Pos>::iterator it;
            for (it = list.begin(); it != list.end(); it++)
            {
                if (this->real_board->cells[it->row][it->col] == Cell::mine)
                {
                    number++;
                }
            }
            this->real_board->cells[row][col] = Cell(number);
        }
    }

    // 初始化
    this->board = new Board<Cell>(Cell::unknown);
    this->num_marked = 0;
    this->num_unexplored = int(HEIGHT) * int(WIDTH);
    this->state = GameState::playing;
}
*/