#pragma once
#include "pch.h"
#include "msgame.h"

class Solver
{
public:
    enum class CellFlag
    {
        unseen = -1, uncertain = 1, closed = 2,
    };

    Solver(bool flag) : quit_when_explore(flag)
    {
        this->game = nullptr;
        this->check_flags = nullptr;
    }
    ~Solver() {
        if (this->check_flags != nullptr) {
            delete this->check_flags;
        }
    }

    void setGame(Game* g) { 
        this->game = g;
        this->check_flags = new Board<bool>(g->getBoard()->width, g->getBoard()->height, false);
    }
    int solve(const Pos&);
    CellFlag getCellFlag(const Pos&);

    static int default_limit;
    Game* game;
    bool quit_when_explore;
    Board<bool>* check_flags;
    std::stack<Pos> checking;
    std::vector<Pos> safes;

    std::array<int, 3> getNeighborsStats(const Pos& pos, const Board<Cell>&);

    int do_single();
    int searchAndExplore();
    int run();

    void initCheckingStack();
    int single();
    int cellUpdated(const Pos&);
    void bfs_unknowns(const Pos&, std::vector<Pos>&);
    bool searchAllWithin(const std::vector<Pos>&, std::vector<Pos>&, std::vector<Pos>&);
};
