#pragma once

#ifndef MSGAME_H
#define MSGAME_H


// 描述一个雷盘中的单元格的坐标
class Pos
{   
public:
    int row;
    int col;
    Pos(int x = 0, int y = 0) : row(x), col(y)
    {
    }
    ~Pos() {}
    inline const Pos operator+(const Pos& right) const
    {
        return Pos(this->row + right.row, this->col + right.col);
    }
    inline bool operator==(const Pos& other) const
    {
        return this->row == other.row && this->col == other.col;
    }
};

// 以C风格一维数组为内部数据结构的 雷盘 模板类
template <typename T>
class Board
{
public:
    int width;
    int height;
    bool isRef; // 若该对象引用外部的数组，则析构时不释放T*

    Board(int w, int h, T init) {
        this->width = w;
        this->height = h;
        this->isRef = false;
        this->cells_array = new T[width * height]{};
        for (int i = 0; i < w * h; i++) {
            this->cells_array[i] = init;
        }
    }

    Board(int w, int h, T* ptr) {
        this->width = w;
        this->height = h;
        this->cells_array = ptr;
        this->isRef = true;
    }

    ~Board() {
        // free problem.
    }

    bool inBounds(Pos pos) {
        if (0 <= pos.row && pos.row < width && 0 <= pos.col && pos.col < height) {
            return true;
        }
        else {
            return false;
        }
    }

    T get(Pos pos) const {
        return this->cells_array[pos.row * this->width + pos.col];
    }

    void set(Pos pos, T data) {
        this->cells_array[pos.row * this->width + pos.col] = data;
    }

private:
    T* cells_array;

};

// 枚举类实际值须与 msgame.inc 定义一致
enum class Cell : unsigned char
{
    blank = 0,
    n1 = 1,
    n2 = 2,
    n3 = 3,
    n4 = 4,
    n5 = 5,
    n6 = 6,
    n7 = 7,
    n8 = 8,
    unknown = 16,
    marked = 32,
    mine = 255,
};
enum class Hint : unsigned char
{
    hint_none = 0,
    hint_safe = 1,
    hint_mine = 2,
    hint_clue = 3,
    hint_guess = 4
};

enum class GameState : int
{
    init = 10,
    playing = 0,
    lose = 2,
    win = 1,
};

// 求解器内部模拟的游戏 与接口无关
class Game
{

private:
    Board<Cell>* real_board;
    Board<Cell>* board;
    GameState state;

    int width, height, mines;
    int num_marked;
    int num_unexplored;
    int isRef;

    void exploreClearCell(const Pos&, std::vector<Pos>&);
public:
    Game(int w, int h, int m, Board<Cell>* ptr=nullptr) : width(w), height(h), mines(m) {
        if (ptr != nullptr) {
            this->isRef = true;
            this->state = GameState::playing;
        }
        else {
            this->isRef = false;
            this->state = GameState::init;
        }
        this->real_board = nullptr;
        this->board = ptr;
        this->num_marked = 0;
        this->num_unexplored = 0;
    }
    ~Game() {
        if (this->real_board != nullptr) {
            delete this->real_board;
        }
        if (this->board != nullptr && this->isRef == false) {
            delete this->board;
        }
    }
    int getTotalMines() const { return mines; }
    int getUnexplored() const { return num_unexplored; }
    int getMarked() const { return num_marked; }

    // 开始新游戏 给定起始位置进行初始化
    void startGame(const Pos&);

    Board<Cell>* getBoard() const {
        return this->board;
    }
    Cell getCell(const Pos& pos) const {
        return this->board->get(pos);
    }
    GameState getState() const {
        return this->state;
    }
    void getNeighbors(const Pos& pos, std::vector<Pos>& neighbors) const {
        static const Pos directions[8] = { {0,-1},{1,-1},{1,0},{1,1},{0,1},{-1,1},{-1,0},{-1,-1} };
        for (int i = 0; i < 8; i++) {
            Pos temp = pos + directions[i];
            if (this->board->inBounds(temp)) {
                neighbors.push_back(temp);
            }
        }
    }

    int explore(const Pos&, std::vector<Pos>&);
    int mark(const Pos&);

};


#endif // !MSGAME_H
