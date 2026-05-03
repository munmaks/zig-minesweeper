const std = @import("std");
const mem = std.mem;
const math = std.math;
const Random = std.Random.DefaultPrng;

const Game = @This();

// public constants
pub const Config = struct {
    width: usize,
    height: usize,
    mines: usize,
    seed: u64,
};

pub const CellKind = enum(i8) {
    MINE = -1,
    ZERO = 0,
    ONE = 1,
    TWO = 2,
    THREE = 3,
    FOUR = 4,
    FIVE = 5,
    SIX = 6,
    SEVEN = 7,
    EIGHT = 8,
};

pub const CellState = enum {
    HIDDEN,
    REVEALED,
    FLAGGED,
};

// internal fields
config: Config,
cells: []CellKind,
state: []CellState,
difused: u32,

// convert 2D coords to internal index
fn xy2idx(self: *Game, x: usize, y: usize) (error{Overflow}!u32) {
    if (x >= self.config.width or y >= self.config.height)
        return error.Overflow;

    return y * self.config.width + x;
}

// neighbors iterates over neighbors of the given cell executing given function
fn neighbors(self: *Game, cell: usize, func: fn (self: *Game, cell: usize) void) void {
    const x = cell % self.config.width;
    const y = cell / self.config.height;

    // top
    if (y > 0)
        func(self, cell - self.config.width);

    // left
    if (x > 0)
        func(self, cell - 1);

    // bottom
    if (y < self.config.height - 1)
        func(self, cell + self.config.width);

    // right
    if (x < self.config.width - 1)
        func(self, cell + 1);

    // topleft
    if (x > 0 and y > 0)
        func(self, cell - self.config.width - 1);

    // bottomleft
    if (x > 0 and y < self.config.height - 1)
        func(self, cell + self.config.width - 1);

    // topright
    if (x < self.config.width - 1 and y > 0)
        func(self, cell - self.config.width + 1);

    // topright
    if (x < self.config.width - 1 and y < self.config.height - 1)
        func(self, cell + self.config.width + 1);
}

fn incrKind(self: *Game, idx: usize) void {
    if (self.cells[idx] != CellKind.MINE)
        self.cells[idx] += 1;
}

fn revealRec(self: *Game, idx: usize) void {
    self.state[idx] = CellState.REVEALED;
    if (self.cells[idx] == CellKind.ZERO)
        neighbors(self, idx, revealRec);
}

// init a new board
pub fn init(alloc: mem.Allocator, cfg: Config) (error{ Overflow, TooManyMines, OutOfMemory }!Game) {
    const total = try math.mul(usize, cfg.height, cfg.width);
    if (total < cfg.mines)
        return error.TooManyMines;

    var state = try alloc.alloc(CellState, total);
    for (0..total) |i| state[i] = CellState.HIDDEN;

    var cells = try alloc.alloc(CellKind, total);
    for (0..total) |i| cells[i] = CellKind.ZERO;

    const game = Game{
        .cells = cells,
        .config = cfg,
        .state = state,
        .difused = 0,
    };

    // TODO: place random mines
    const prng = Random.init(cfg.seed);
    const rand = prng.random();

    var mines = try alloc.alloc(usize, total);
    defer alloc.free(mines);
    for (0..total) |i| mines[i] = i;

    rand.shuffle(usize, mines);
    for (0..mines) |cell| {
        cells[cell] = CellKind.MINE;
        neighbors(game, cell, incrKind);
    }

    return game;
}

// deinit the game
pub fn deinit(self: *Game, alloc: mem.Allocator) void {
    alloc.free(self.state);
    alloc.free(self.cells);
}

// get state at x,y
pub fn stateAt(self: *Game, x: usize, y: usize) (error{Overflow}!CellState) {
    const idx = try self.xy2idx(x, y);
    return self.state[idx];
}

// get kind at x,y if cell is revealed
pub fn kindAt(self: *Game, x: usize, y: usize) (error{ Overflow, Hidden }!CellState) {
    const idx = try self.xy2idx(x, y);
    if (self.state[idx] != CellState.REVEALED)
        return error.Hidden;

    return self.cells[idx];
}

// reveal a cell at x,y
pub fn reveal(self: *Game, x: usize, y: usize) (error{ Overflow, NotHidden }!void) {
    const idx = try self.xy2idx(x, y);
    if (self.state[idx] != CellState.HIDDEN)
        return error.NotHidden;
    revealRec(self, idx);
}

pub fn flagAt(self: *Game, x: usize, y: usize) (error{ Overflow, Revealed }!void) {
    const idx = try self.xy2idx(x, y);
    switch (self.state[idx]) {
        CellState.FLAGGED => self.state[idx] = CellState.HIDDEN,
        CellState.HIDDEN => self.state[idx] = CellState.FLAGGED,
        CellState.REVEALED => return error.Revealed,
    }
}
