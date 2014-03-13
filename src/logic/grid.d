
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

class Grid
{
public:

    this(GridSizeUnit size_w, GridSizeUnit size_h, uint num_of_bombs, uint seed)
    body
    {
        _seed = seed;
        this(size_w, size_h, num_of_bombs);
    }

    this(GridSizeUnit size_w, GridSizeUnit size_h, uint num_of_bombs)
    {
        if (_seed == uint.init)
        {
            _seed = uniform(0, uint.max);
        }
        _size_w = size_w;
        _size_h = size_h;
        _num_of_bombs = num_of_bombs;

        generate();
    }

    @property auto height() const { return _size_h; }
    @property auto width() const { return _size_w; }

    @property auto num_bombs() const { return _num_of_bombs; }

    @property auto seed() const { return _seed; }

    // Simply to verify correct behaviour
    @property auto countedBombs() const
    {
        uint num_of_bombs;
        for (int xx; xx < _size_w; ++xx)
        {
            for (int yy; yy < _size_h; ++yy)
            {
                if (_fields[xx][yy].isBomb)
                {
                    ++num_of_bombs;
                }
            }
        }
        return num_of_bombs;
    }

    /**
     * @return bool Returns true if nothing happened. Returns false if something
     *              blew up.
     */
    bool clickOn(GridSizeUnit x, GridSizeUnit y)
    in
    {
        assert(x > 0);
        assert(x <= _size_w);
        assert(y > 0);
        assert(y <= _size_h);
    }
    body
    {
        return _fields[x][y].clickOn();
    }

    /**
     * Calculates neighboring bomb count. Range 0..8.
     */
    auto getBombCountForField(GridSizeUnit x, GridSizeUnit y) const
    in
    {
        assert(x > 0);
        assert(x <= _size_w);
        assert(y > 0);
        assert(y <= _size_h);
    }
    body
    {
        ubyte num_neighbor_bombs;
        for (auto d_x = -1; d_x <= 1; ++d_x)
        {
            auto _x = x + d_x;
            if (d_x == 0 || _x < 0 || _x >= _size_w)
            {
                continue;
            }

            for (auto d_y = -1; d_y <= 1; ++d_y)
            {
                auto _y = y + d_y;
                if (d_y == 0 || _y < 0 || _y >= _size_h)
                {
                    continue;
                }

                num_neighbor_bombs += _fields[_x][_y].isBomb;
            }
        }

        return num_neighbor_bombs;
    }

private:

    void generate()
    {
        auto rng = Random(_seed);
        real ratio_of_bombs = _num_of_bombs / cast(real) (_size_w * _size_h);
        uint cur_num_bombs;

        bool[][] bomb_positions;

        bomb_positions.length = _size_w;
        foreach (ref row; bomb_positions)
        {
            row.length = _size_h;
        }

        while (cur_num_bombs < _num_of_bombs)
        {
            GridSizeUnit bomb_x = uniform(0, _size_w, rng);
            GridSizeUnit bomb_y = uniform(0, _size_h, rng);

            if (!bomb_positions[bomb_x][bomb_y])
            {
                bomb_positions[bomb_x][bomb_y] = true;
                ++cur_num_bombs;
            }
        }

        _fields.length = _size_w;
        for (uint xx; xx < _size_w; ++xx)
        {
            for (uint yy; yy < _size_h; ++yy)
            {
                bool isBomb = bomb_positions[xx][yy];
                FieldType type;
                if (isBomb)
                {
                    type = FieldType.Bomb;
                }
                else
                {
                    type = FieldType.Empty;
                }

                _fields[xx] ~= GridField(xx, yy, type);
            }
        }
    }

    GridField[][] _fields;
    const uint _seed;
    const uint _num_of_bombs;
    const GridSizeUnit _size_w;
    const GridSizeUnit _size_h;
}

unittest {
    writeln("logic.grid.Grid");

    auto g1 = new Grid(4, 5, 6);

    assert(g1.countedBombs == 6, std.conv.to!string(g1.countedBombs));

    writeln("Done.");
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

    @property auto isCovered() const { return _covered; }

    @property auto hadBeenClickedOn() const { return !_covered; }

    /**
     * @return bool Returns true if nothing happened. Returns false if something
     *              blew up.
     */
    bool clickOn()
    {
        if (isCovered)
        {
            uncover();
        }

        return !isBomb;
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
