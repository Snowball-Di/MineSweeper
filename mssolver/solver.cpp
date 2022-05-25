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

// 统计并返回三类方格的个数，explored/marked/unknown
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
    // 标记unseen: 本身是unknown且周围没有已探索方格,
    if (Cell::unknown == game->getCell(pos) && stats[0] == 0)
    {
        return CellFlag::unseen;
    }
    // 标记closed: 插旗方格 或 周围全为已探索或插旗的数字方格
    else if (Cell::marked == game->getCell(pos))
    {
        return CellFlag::closed;
    }
    else if (isNumberCell(game->getCell(pos)) && stats[2] == 0)
    {
        return CellFlag::closed;
    }
    // 标记uncertain: 情况包括 周围有已探索的unknown 和 周围有unknown的数字
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
        {	// 执行标雷
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
        {	// 执行探索
            std::vector<Pos> list; list.reserve(8);
            game->getNeighbors(pos, list);
            for (auto it_n = list.begin(); it_n != list.end(); it_n++)
            {
                if (Cell::unknown == game->getCell(*it_n))
                {
                    // ! 先push 循环结束就返回
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
        {	// 不做任何事
        }
    }
    return 0;
}

int Solver::cellUpdated(const Pos& pos)
{
    // 调用的可能途径 1 有标雷 2 有方格被新点击
    // 对于有影响的方格 入栈条件如下
    // 1不在栈内 2是非零数字 3周围存在unknown
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

    // 可能有如下情况 有看不到的unknown / 找不到逻辑解 / 找到解
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
        // 将search set中的元素从原集合中去除
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
        // 返回0 使调用者run()立刻停止求解
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
        // unknown只添加相邻的数字 数字只添加相邻的unknown
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
    // 0 是雷的次数 1 是空的次数
    for (auto it = set.begin(); it != set.end(); it++)
    {
        if (board->get(*it) != Cell::unknown) printf("Error!\n");
        cell_stats.push_back({ 0, 0 });
    }
    int total_num_possible = 0;

    int depth = 0;
    while (depth != -1)
    {
        // 左子节点or右子节点
        if (board->get(set[depth]) == Cell::unknown)
        {
            board->set(set[depth], Cell::marked);
        }
        else if (board->get(set[depth]) == Cell::marked)
        {
            board->set(set[depth], Cell::blank);
        }
        // 检查当前单元格的冲突条件
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
        {   // 若左右分支都查过 则执行回溯
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
        {   // 未发生冲突 搜索下一层
            depth++;
            if (depth == set.size())
            {
                // 检查剩余雷数条件 统计当前枚举区域标雷个数
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
                {   // 满足剩余雷数关系
                    // 保存当前格局 然后返回最后一层
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
                // 若最后一层为blank则需要执行回溯
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

