#include "pch.h"
#include "solver.h"

int Solver::default_limit = 100;

bool isNumberCell(Cell c)
{
    if (0 <= int(c) && int(c) <= 8) return true;
    else return false;
}

bool isNonZeroCell(Cell c)
{
    if (1 <= int(c) && int(c) <= 8) return true;
    else return false;
}

// ͳ�Ʋ��������෽��ĸ�����explored/marked/unknown
std::array<int, 3> Solver::getNeighborsStats(const Pos& pos, const Board<Cell>& board)
{
    int explored = 0, marked = 0, unknown = 0;
    std::vector<Pos> list;
    list.reserve(8);
    game->getNeighbors(pos, list);
    for (auto it = list.begin(); it != list.end(); it++)
    {
        Cell cell = board.get(*it);
        if (cell == Cell::marked)
            marked += 1;
        else if (cell == Cell::unknown)
            unknown += 1;
        else
            explored += 1;
    }
    return std::array<int, 3>({ explored, marked, unknown });
}

Solver::CellFlag Solver::getCellFlag(const Pos& pos)
{
    auto stats = getNeighborsStats(pos, *(this->game->getBoard()));
    // ���unseen: ������unknown����Χû����̽������,
    if (Cell::unknown == game->getCell(pos) && stats[0] == 0)
    {
        return CellFlag::unseen;
    }
    // ���closed: ���췽�� �� ��ΧȫΪ��̽�����������ַ���
    else if (Cell::marked == game->getCell(pos))
    {
        return CellFlag::closed;
    }
    else if (isNumberCell(game->getCell(pos)) && stats[2] == 0)
    {
        return CellFlag::closed;
    }
    // ���uncertain: ������� ��Χ����̽����unknown �� ��Χ��unknown������
    else
    {
        return CellFlag::uncertain;
    }
}


int Solver::solve(const Pos& first)
{
    return 0;
}

void Solver::initCheckingStack()
{
    for (int i = 0; i < this->check_flags->height; i++) {
        for (int j = 0; j < this->check_flags->width; j++) {
            this->check_flags->set(Pos(i, j), false);
        }
    }
    for (int row = 0; row < this->check_flags->height; row++)
    {
        for (int col = 0; col < this->check_flags->width; col++)
        {
            if (isNumberCell(game->getCell(Pos(row, col))) &&
                CellFlag::uncertain == getCellFlag(Pos(row, col)))
            {
                checking.push(Pos(row, col));
                check_flags->set(Pos(row, col), true);
            }
        }
    }
}

int Solver::do_single()
{
    initCheckingStack();
    int counter;
    counter = single();
    return counter;
}

int Solver::single()
{
    while (!checking.empty())
    {
        Pos pos = checking.top();
        checking.pop();
        if (check_flags->get(pos) == false) continue;
        else check_flags->set(pos, false);

        auto stats = getNeighborsStats(pos, *(this->game->getBoard()));
        if (stats[1] + stats[2] == int(game->getCell(pos)))
        {	// ִ�б���
            std::vector<Pos> list; list.reserve(8);
            game->getNeighbors(pos, list);
            for (auto it = list.begin(); it != list.end(); it++)
            {
                if (Cell::unknown == game->getCell(*it))
                {
                    game->mark(*it);
                    cellUpdated(*it);
                }
            }
        }
        else if (stats[1] == int(game->getCell(pos)))
        {	// ִ��̽��
            std::vector<Pos> list; list.reserve(8);
            game->getNeighbors(pos, list);
            for (auto it_n = list.begin(); it_n != list.end(); it_n++)
            {
                if (Cell::unknown == game->getCell(*it_n))
                {
                    // ! ��push ѭ�������ͷ���
                    if (this->quit_when_explore) {
                        this->safes.push_back(*it_n);
                    }
                    else {
                        std::vector<Pos> explored_cells;
                        game->explore(*it_n, explored_cells);
                        for (auto it_e = explored_cells.begin(); it_e != explored_cells.end(); it_e++)
                        {
                            cellUpdated(*it_e);
                        }
                    }
                }
            }
            if (!this->safes.empty() && this->quit_when_explore) {
                return 1;
            }
            if (game->getState() == GameState::win)
            {
                break;
            }
        }
        else
        {	// �����κ���
        }
    }
    return 0;
}

int Solver::cellUpdated(const Pos& pos)
{
    // ���õĿ���;�� 1 �б��� 2 �з����µ��
    // ������Ӱ��ķ��� ��ջ��������
    // 1����ջ�� 2�Ƿ������� 3��Χ����unknown
    std::vector<Pos> list; list.reserve(8);
    game->getNeighbors(pos, list);
    list.push_back(pos);
    for (auto it = list.begin(); it != list.end(); it++)
    {
        if (check_flags->get(*it) == false &&
            isNonZeroCell(game->getCell(*it)) &&
            CellFlag::uncertain == getCellFlag(*it))
        {
            checking.push(*it);
            check_flags->set(*it, true);
        }
    }
    return 0;
}

int Solver::run()
{
    initCheckingStack();
    this->safes.clear();

    bool game_over = false;
    while (game_over == false)
    {
        if (single()) break;
        if (game->getState() != GameState::playing) break;
        if (!searchAndExplore()) break;
        if (game->getState() != GameState::playing) break;
    }
    return 0;
}

int Solver::searchAndExplore()
{
    std::vector<Pos> all_seen_unknown; all_seen_unknown.reserve(256);
    Board<bool> in_asu(this->game->getBoard()->width, this->game->getBoard()->height, false);
    for (int row = 0; row < this->game->getBoard()->height; row++)
    {
        for (int col = 0; col < this->game->getBoard()->width; col++)
        {
            if (!isNumberCell(game->getCell(Pos(row, col))) && CellFlag::uncertain == getCellFlag(Pos(row, col)))
            {
                all_seen_unknown.push_back(Pos(row, col));
                in_asu.set(Pos(row, col), true);
            }
        }
    }
    int num_unchecked = all_seen_unknown.size();
    if (num_unchecked == 0)
    {
        return 0;
    }

    // ������������� �п�������unknown / �Ҳ����߼��� / �ҵ���
    std::vector<Pos> to_mark, to_explore;
    auto from = all_seen_unknown.begin();
    while (true)
    {
        while (in_asu.get(*from) == false)
        {
            from++;
            if (from == all_seen_unknown.end()) break;
        }
        if (from == all_seen_unknown.end()) break;

        std::vector<Pos> search_set; search_set.reserve(256);
        this->bfs_unknowns(*from, search_set);
        if (search_set.size() > default_limit)
        {   // it does not search
        }
        else
        {
            if (this->searchAllWithin(search_set, to_mark, to_explore))
            {
                break;
            }
        }
        // ��search set�е�Ԫ�ش�ԭ������ȥ��
        in_asu.set(*from, false);
        for (auto it = search_set.begin(); it != search_set.end(); it++)
        {
            in_asu.set(*it, false);
        }
        num_unchecked -= search_set.size();
    }

    for (auto pos = to_explore.begin(); pos != to_explore.end(); pos++)
    {
        if (this->quit_when_explore) {
            this->safes.push_back(*pos);
        }
        else {
            std::vector<Pos> explored_cells; explored_cells.reserve(256);
            game->explore(*pos, explored_cells);
            for (auto it_e = explored_cells.begin(); it_e != explored_cells.end(); it_e++)
            {
                cellUpdated(*it_e);
            }
        }
    }
    for (auto pos = to_mark.begin(); pos != to_mark.end(); pos++)
    {
        game->mark(*pos);
        cellUpdated(*pos);
    }
    if (!this->safes.empty() && this->quit_when_explore) {
        // ����0 ʹ������run()����ֹͣ���
        return 0;
    }
    return int(to_explore.size() + to_mark.size());
}

void Solver::bfs_unknowns(const Pos& from, std::vector<Pos>& results)
{
    std::queue<Pos> q;
    Board<bool> vis(this->game->getBoard()->width, this->game->getBoard()->height, false);;

    q.push(from); vis.set(from, true); results.push_back(from);
    while (!q.empty())
    {
        Pos pos = q.front();
        q.pop();
        Cell me = game->getCell(pos);
        // unknownֻ������ڵ����� ����ֻ������ڵ�unknown
        if (me == Cell::unknown)
        {
            std::vector<Pos> list; list.reserve(8);
            game->getNeighbors(pos, list);
            for (auto it = list.begin(); it != list.end(); it++)
            {
                if (vis.get(*it) == false && isNumberCell(game->getCell(*it)))
                {
                    q.push(*it); vis.set(*it, true);
                }
            }
        }
        else
        {
            std::vector<Pos> list; list.reserve(8);
            game->getNeighbors(pos, list);
            for (auto it = list.begin(); it != list.end(); it++)
            {
                if (vis.get(*it) == false && game->getCell(*it) == Cell::unknown)
                {
                    q.push(*it); vis.set(*it, true); results.push_back(*it);
                }
            }
        }
    }
}


bool Solver::searchAllWithin(const std::vector<Pos>& set, std::vector<Pos>& to_mark, std::vector<Pos>& to_explore)
{
    Board<Cell>* board = new Board<Cell>(*(game->getBoard()));
    std::vector<std::array<int, 2>> cell_stats;  cell_stats.reserve(256);
    // 0 ���׵Ĵ��� 1 �ǿյĴ���
    for (auto it = set.begin(); it != set.end(); it++)
    {
        if (board->get(*it) != Cell::unknown) printf("Error!\n");
        cell_stats.push_back({ 0, 0 });
    }
    int total_num_possible = 0;

    int depth = 0;
    while (depth != -1)
    {
        // ���ӽڵ�or���ӽڵ�
        if (board->get(set[depth]) == Cell::unknown)
        {
            board->set(set[depth], Cell::marked);
        }
        else if (board->get(set[depth]) == Cell::marked)
        {
            board->set(set[depth], Cell::blank);
        }
        // ��鵱ǰ��Ԫ��ĳ�ͻ����
        bool conflict = false;
        std::vector<Pos> list; list.reserve(8);
        game->getNeighbors(set[depth], list);
        for (auto it = list.begin(); it != list.end(); it++)
        {
            Cell me = board->get(*it);
            if (!isNonZeroCell(me))
                continue;
            auto stats = getNeighborsStats(*it, *board);
            if (stats[1] > int(me) || stats[1] + stats[2] < int(me))
            {
                conflict = true;
                break;
            }
        }
        if (conflict)
        {   // �����ҷ�֧����� ��ִ�л���
            while (0 <= depth && board->get(set[depth]) == Cell::blank)
            {
                depth--;
            }
            for (int child = depth + 1; child < set.size() && board->get(set[child]) != Cell::unknown; child++)
            {
                board->set(set[child], Cell::unknown);
            }
        }
        else
        {   // δ������ͻ ������һ��
            depth++;
            if (depth == set.size())
            {
                // ���ʣ���������� ͳ�Ƶ�ǰö��������׸���
                int remains = this->game->getTotalMines() - game->getMarked();  // M
                int try_marks = 0;  // k
                for (int i = 0; i < set.size(); i++)
                {
                    if (board->get(set[i]) == Cell::marked)
                    {
                        try_marks++;
                    }
                }
                if (try_marks <= remains && remains <= try_marks + (game->getUnexplored() - set.size()))
                {   // ����ʣ��������ϵ
                    // ���浱ǰ��� Ȼ�󷵻����һ��
                    for (int i = 0; i < set.size(); i++)
                    {
                        if (board->get(set[i]) == Cell::marked)
                        {
                            cell_stats[i][0] += 1;
                        }
                        else if (board->get(set[i]) == Cell::blank)
                        {
                            cell_stats[i][1] += 1;
                        }
                        else printf("Error cell type...\n");
                    }
                    total_num_possible += 1;
                }
                depth--;
                // �����һ��Ϊblank����Ҫִ�л���
                while (0 <= depth && board->get(set[depth]) == Cell::blank)
                {
                    depth--;
                }
                for (int child = depth + 1; child < set.size() && board->get(set[child]) != Cell::unknown; child++)
                {
                    board->set(set[child], Cell::unknown);
                }
            }
        }
    }

    delete board;
    for (int i = 0; i < set.size(); i++)
    {
        if (cell_stats[i][0] + cell_stats[i][1] != total_num_possible) printf("impossible...");
        if (cell_stats[i][0] == 0) to_explore.push_back(set[i]);
        if (cell_stats[i][1] == 0) to_mark.push_back(set[i]);
    }
    if (to_explore.size() + to_mark.size() == 0)
        return false;
    else
        return true;
}

