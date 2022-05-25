#include "pch.h"
#include "msgame.h"



int Game::explore(const Pos& pos, std::vector<Pos>& cell_list)
{
    if (!this->board->inBounds(pos))
    {   // �߽���
        return -1;
    }
    if (this->state != GameState::playing)
    {   // ��������Ϸ����������
        return -1;
    }

    if (!cell_list.empty())
    {
        cell_list.clear();
    }

    // ��ȡ�õ�Ԫ��Ĵ�
    Cell cell = this->real_board->get(pos);
    if (cell == Cell::mine)
    {   // ���������
        this->board->set(pos, Cell::mine);
        // ������Ϸ״̬
        this->state = GameState::lose;
    }
    else
    {
        exploreClearCell(pos, cell_list);
        // �ж���Ϸ�Ƿ������������Ϸ״̬��
        if (this->num_unexplored == this->mines)
        {
            this->state = GameState::win;
        }
    }
    return 0;
}

void Game::exploreClearCell(const Pos& pos, std::vector<Pos>& cell_list)
{   // ��֤�������Ԫ������
    // ���˵�Ԫ���Ƿ�̽����
    Cell seen_cell = this->board->get(pos);
    if (seen_cell != Cell::unknown && seen_cell != Cell::marked)
    {
        return;
    }

    Cell cell = this->real_board->get(pos);
    if (cell == Cell::blank)
    {   // �����հ׸񣬵ݹ��̽������Χ�ĸ�
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
    {   // ��������1-8����ֻ�㿪��
        this->board->set(pos, this->real_board->get(pos));
        this->num_unexplored--;
        cell_list.push_back(pos);
    }
}

int Game::mark(const Pos& pos)
{
    if (!this->board->inBounds(pos))
    {   // �߽���
        return -1;
    }
    if (this->state != GameState::playing)
    {   // ��������Ϸ����������
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
    {   // �������̽���ĵ�Ԫ��Ҳ����ʧ��(-1)
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
        // �Ḳ�ǵ�ǰ��Ϸ���̣�������ֹ
    }

    // ��ʼ��������
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

    // ��ʼ��
    this->board = new Board<Cell>(Cell::unknown);
    this->num_marked = 0;
    this->num_unexplored = int(HEIGHT) * int(WIDTH);
    this->state = GameState::playing;
}
*/