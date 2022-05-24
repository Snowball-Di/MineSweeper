#pragma once

#ifndef MSGAME_H
#define MSGAME_H


// ����һ�������еĵ�Ԫ�������
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

// ��C���һά����Ϊ�ڲ����ݽṹ�� ���� ģ����
template <typename T>
class Board
{
public:
    int width;
    int height;
    bool isRef;

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
        if (!this->isRef) {
            delete[] this->cells_array;
        }
    }

    bool inBounds(Pos pos) {
        if (0 <= pos.row && pos.row <= width && 0 <= pos.col && pos.col <= height) {
            return true;
        }
        else {
            return false;
        }
    }

    T get(Pos pos) {
        return this->cells_array[pos.row * this->width + pos.col];
    }

private:
    T* cells_array;

};

// ö����ʵ��ֵ���� msgame.inc ����һ��
enum class Cell : unsigned char
{

};
enum class Hint : unsigned char
{

};

enum class GameState : int
{
    init = 10,
    playing = 0,
    lose = 2,
    win = 1,
};

// ������ڲ�ģ�����Ϸ ��ӿ��޹�
class Game
{

private:
    Board<Cell>* real_board;
    Board<Cell>* board;
    GameState state;

    int num_marked;
    int num_unexplored;

    void exploreClearCell(const Pos&, std::vector<Pos>&);
public:
    Game() {
        this->state = GameState::init;
        this->real_board = nullptr;
        this->board = nullptr;
    }
    ~Game() {
        if (this->real_board != nullptr)
            delete this->real_board;
        if (this->board != nullptr)
            delete this->board;
    }
    int getUnexplored() const { return num_unexplored; }
    int getMarked() const { return num_marked; }

    // ��ʼ����Ϸ ������ʼλ�ý��г�ʼ��
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
