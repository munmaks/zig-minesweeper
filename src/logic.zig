const std = @import("std");
const mem = std.mem;
const math = std.math;
const Random = std.Random.DefaultPrng;
const rl = @import("raylib");

pub const Logic = @This();

// !public constants
pub const Config = struct {
    width: usize,
    height: usize,
    mines: usize,
    seed: u64,
};

pub const CellKind = enum(u8) {
    ZERO = 0,
    ONE = 1,
    TWO = 2,
    THREE = 3,
    FOUR = 4,
    FIVE = 5,
    SIX = 6,
    SEVEN = 7,
    EIGHT = 8,
    MINE = 9,
};

pub const CellState = enum {
    HIDDEN,
    REVEALED,
    FLAGGED,
};

// !internal fields
config: Config,
cells: []CellKind,
state: []CellState,
diffused: i32,
gameOver: bool,
flagged: usize,

// !init a new board
pub fn init(alloc: mem.Allocator, cfg: Config) (error{ Overflow, TooManyMines, OutOfMemory }!Logic) {
    const total = try math.mul(usize, cfg.height, cfg.width);
    if (total < cfg.mines)
        return error.TooManyMines;

    var state = try alloc.alloc(CellState, total);
    for (0..total) |i| state[i] = .HIDDEN;

    var cells = try alloc.alloc(CellKind, total);
    for (0..total) |i| cells[i] = .ZERO;

    var logic: Logic = .{
        .cells = cells,
        .config = cfg,
        .state = state,
        .diffused = 0,
        .gameOver = false,
        .flagged = 0,
    };

    var prng = Random.init(cfg.seed);
    const rand = prng.random();

    var mines = try alloc.alloc(usize, total);
    defer alloc.free(mines);
    for (0..total) |i| mines[i] = i;

    rand.shuffle(usize, mines);
    for (0..cfg.mines) |cell| {
        cells[mines[cell]] = .MINE;
        neighbors(&logic, mines[cell], incrKind);
    }

    return logic;
}

pub fn revealedCount(self: *Logic) usize {
    var count: usize = 0;
    for (0..self.config.width * self.config.height) |i| {
        if (self.state[i] == .REVEALED and self.cells[i] != .MINE)
            count += 1;
    }
    return count;
}

// !convert 2D coords to internal index
fn xy2idx(self: *Logic, x: usize, y: usize) (error{Overflow}!usize) {
    if (x >= self.config.width or y >= self.config.height)
        return error.Overflow;

    return y * self.config.width + x;
}

fn toIndex(self: *Logic, vec: rl.Vector2) (error{Overflow}!usize) {
    const x: usize = @intFromFloat(vec.x);
    const y: usize = @intFromFloat(vec.y);
    if (x < 0 or x >= self.config.width or
        y < 0 or y >= self.config.height)
    {
        return error.Overflow;
    }
    return y * self.config.width + x;
}

// !neighbors iterates over neighbors of the given cell executing given function
fn neighbors(self: *Logic, cell: usize, func: fn (self: *Logic, cell: usize) void) void {
    const x = cell % self.config.width;
    const y = cell / self.config.width;

    // !top
    if (y > 0)
        func(self, cell - self.config.width);

    // !left
    if (x > 0)
        func(self, cell - 1);

    // !bottom
    if (y < self.config.height - 1)
        func(self, cell + self.config.width);

    // !right
    if (x < self.config.width - 1)
        func(self, cell + 1);

    // !topleft
    if (x > 0 and y > 0)
        func(self, cell - self.config.width - 1);

    // !bottomleft
    if (x > 0 and y < self.config.height - 1)
        func(self, cell + self.config.width - 1);

    // !topright
    if (x < self.config.width - 1 and y > 0)
        func(self, cell - self.config.width + 1);

    // !bottomright
    if (x < self.config.width - 1 and y < self.config.height - 1)
        func(self, cell + self.config.width + 1);
}

fn incrKind(self: *Logic, idx: usize) void {
    if (self.cells[idx] != .MINE)
        self.cells[idx] = @enumFromInt(@intFromEnum(self.cells[idx]) + 1);
}

fn revealRec(self: *Logic, idx: usize) void {
    if (self.state[idx] == .REVEALED) return;
    self.state[idx] = .REVEALED;
    if (self.cells[idx] == .ZERO)
        neighbors(self, idx, revealRec);
}

fn revealRecNum(self: *Logic, idx: usize) void {
    if (self.state[idx] == .REVEALED or
        self.state[idx] == .FLAGGED) return;
    if (self.cells[idx] == .MINE) return;
    self.state[idx] = .REVEALED;
    if (self.cells[idx] == .ZERO)
        neighbors(self, idx, revealRec);
}

// !deinit the game
pub fn deinit(self: *Logic, alloc: mem.Allocator) void {
    alloc.free(self.state);
    alloc.free(self.cells);
}

// !remaining can be used to determine amount of mines needed to be revealed
pub fn remaining(self: *Logic) usize {
    return self.config.mines - self.diffused;
}

// !isOver returns true if the game is won, false if not, and null if the game is not over
pub fn isOver(self: *Logic) ?bool {
    if (self.gameOver)
        return false;
    for (0..self.config.width * self.config.height) |i| {
        // !we have a revealed mine cell
        if (self.state[i] == .REVEALED and self.cells[i] == .MINE)
            return false;

        // !we have a non-revealed non-mine cell
        if (self.state[i] != .REVEALED and self.cells[i] != .MINE)
            return null;
    }

    // !all cells non-mined cells are revealed
    return true;
}

// !get state at x,y
pub fn stateAt(self: *Logic, x: usize, y: usize) (error{Overflow}!CellState) {
    const idx = try self.xy2idx(x, y);
    return self.state[idx];
}

// pub fn stateAtVec(self: *Logic, vec: rl.Vector2) (error{Overflow}!CellState) {
//     const idx = try self.toIndex(vec);
//     return self.state[idx];
// }

// !to test this function:
// !get kind at x,y if cell is revealed
pub fn kindAt(self: *Logic, x: usize, y: usize) (error{ Overflow, Hidden }!CellKind) {
    const idx = try self.xy2idx(x, y);
    if (self.state[idx] != .REVEALED)
        return error.Hidden;

    return self.cells[idx];
}

fn countFlagged(self: *Logic, idx: usize) void {
    if (self.state[idx] == .FLAGGED) {
        self.flagged += 1;
    }
}

// !reveal a cell at x,y
pub fn reveal(self: *Logic, x: usize, y: usize) (error{Overflow}!void) {
    const idx = try self.xy2idx(x, y);

    if (self.state[idx] == .FLAGGED)
        return;

    // ! if it's revealed and in neighbors flag is equal to the number
    // ! beneath the cell, we can reveal
    if (self.state[idx] == .REVEALED and
        self.cells[idx] != .MINE)
    {
        self.flagged = 0;
        neighbors(self, idx, countFlagged);
        const kindNumber: u8 = @intFromEnum(self.cells[idx]);

        if (self.flagged == @as(usize, kindNumber)) {
            neighbors(self, idx, revealRecNum);
            return;
        }
    }

    if (self.cells[idx] == .MINE) {
        self.state[idx] = .REVEALED;
        self.gameOver = true;
        return;
    }

    if (self.state[idx] == .FLAGGED)
        return;
    revealRec(self, idx);
}

pub fn flagAt(self: *Logic, x: usize, y: usize) (error{Overflow}!void) {
    const idx = try self.xy2idx(x, y);
    switch (self.state[idx]) {
        .FLAGGED => {
            self.state[idx] = .HIDDEN;
            self.diffused -= 1;
        },
        .HIDDEN => {
            self.state[idx] = .FLAGGED;
            self.diffused += 1;
        },
        .REVEALED => {}, //return error.Revealed,
    }
}
