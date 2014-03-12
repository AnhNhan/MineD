
module logic.grid;

import std.random : uniform, Random;

version(unittest) {
    import std.stdio;
}

enum FieldType {
    Empty
  , Bomb
}

alias uint GridSizeUnit;

class Grid(GridSizeUnit size_w, GridSizeUnit size_h, uint num_of_bombs = 10)
{
    static assert(num_of_bombs < (size_w * size_h), "Too many bombs for such a small field!");

public:

    this(uint seed)
    body
    {
        _seed = seed;
        this();
    }

    this()
    {
        if (_seed == uint.init) {
            _seed = uniform(0, uint.max);
        }

        generate();
    }

    @property auto countedBombs() const
    {
        uint num_of_bombs;
        for (int xx; xx < size_w; ++xx)
        {
            for (int yy; yy < size_h; ++yy)
            {
                if (_fields[xx][yy].isBomb) {
                    ++num_of_bombs;
                }
            }
        }
        return num_of_bombs;
    }

private:

    void generate()
    {
        auto rng = Random(_seed);
        real ratio_of_bombs = num_of_bombs / cast(real) (size_w * size_h);
        uint cur_num_bombs;
        for (uint xx; xx < size_w; ++xx)
        {
            for (uint yy; yy < size_h; ++yy)
            {
                bool isBomb = uniform(0.0f, 1.0f, rng) < ratio_of_bombs;
                FieldType type;
                if (isBomb && cur_num_bombs <= num_of_bombs) {
                    ++cur_num_bombs;
                    type = FieldType.Bomb;
                } else {
                    type = FieldType.Empty;
                }

                _fields[xx][yy] = GridField(xx, yy, type);
            }
        }
    }

    GridField[size_w][size_h] _fields;
    private const uint _seed;
}

unittest {
    auto g1 = new Grid!(4, 5, 6)();

    assert(g1.countedBombs == 6);
}

private const struct GridPosition
{
    GridSizeUnit x;
    GridSizeUnit y;

    @disable this();

    this(I : int, J : int)(in I _x, in J _y)
    {
        x = cast(GridSizeUnit) _x;
        y = cast(GridSizeUnit) _y;
    }
}

unittest {
    writeln("logic.grid.GridPosition");

    auto pos1 = const GridPosition(12, 42);
    assert(pos1.x == 12);
    assert(pos1.y == 42);

    writeln("Done.");
}

private struct GridField
{
    const FieldType type;
    const GridPosition pos;

    @disable this();

    this(I : int, J : int)(in I x, in J y, FieldType _type)
    {
        pos = const GridPosition(x, y);
        type = _type;
    }

    @property
    bool isBomb() const { return type == FieldType.Bomb; }

    @property
    bool isEmpty() const { return type == FieldType.Empty; }

    private bool _questionMarked = false;

    @property bool isQuestionMarked() const { return _questionMarked; }

    void markHasNoIdea()
        in
            {
                assert(!_questionMarked, "Can't be applied twice!");
                assert(_covered, "Has to be covered!");
            }
        body
            {
                _questionMarked = true;
            }

    void removeQuestionMark()
        in
            {
                assert(_questionMarked, "Had to be question marked!");
                assert(_covered, "Has to be covered!");
            }
        body
            {
                _questionMarked = false;
            }

    private bool _covered = true;

    void uncover()
        in
            {
                assert(!_covered, "Already uncovered!");
            }
        body
            {
                _covered = false;
            }
}

unittest {
    writeln("logic.grid.GridField");

    auto f1 = GridField(3, 8, FieldType.Empty);

    assert(f1.pos.x == 3);
    assert(f1.pos.y == 8);
    assert(f1.isEmpty);
    assert(!f1.isBomb);

    assert(!f1.isQuestionMarked);
    f1.markHasNoIdea();
    assert(f1.isQuestionMarked);
    f1.removeQuestionMark();
    assert(!f1.isQuestionMarked);

    writeln("Done.");
}
