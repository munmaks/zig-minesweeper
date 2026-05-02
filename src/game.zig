const std = @import("std");
const mem = std.mem;

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

pub const CellState = enum(u1) {
    HIDDEN = 0,
    REVEALED = 1,
};

// internal fields
config: Config,
cells: []CellKind,
state: []CellState,

// convert 2D coords to internal index
fn xy2idx(self: *Game, x: usize, y: usize) (error{Overflow}!u32) {
    if (x >= self.config.width or y >= self.config.height)
        return error.Overflow;

    return y * self.config.width + x;
}

// neighbours iterator helper
const Neighbors = struct {
    self: *Game,
    x: usize,
    y: usize,

    pub fn next(self: *Neighbors) ?usize {
        // TODO: implement the logic here
        _ = self;
        return null;
    }
};

fn neighbors(self: *Game, idx: usize) Neighbors {
    return .{
        .self = self,
        .cell = idx,
    };
}

// init a new board
pub fn init(alloc: mem.Allocator, cfg: Config) (error{ Overflow, TooManyMines, OutOfMemory }!Game) {
    const total = try std.math.mul(usize, cfg.height, cfg.width);
    if (total < cfg.mines)
        return error.TooManyMines;

    var state = try alloc.alloc(CellState, total);
    for (0..total) |i| state[i] = CellState.HIDDEN;

    var cells = try alloc.alloc(CellKind, total);
    for (0..total) |i| cells[i] = CellKind.ZERO;

    // TODO: place random mines

    // const prng = std.Random.DefaultPrng.init(cfg.seed);
    // const rand = prng.random();

    return Game{
        .cells = cells,
        .config = cfg,
        .state = state,
    };
}

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

    self.state[idx] = CellState.REVEALED;
    // TODO: reveal all nearby if zero
}
