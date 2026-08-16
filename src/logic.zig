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
    // board: rl.Rectangle,
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
    EXPLODED = 10,
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
    if (x >= self.config.width or
        y >= self.config.height)
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
fn neighbors(self: *Logic, cell: usize, func: fn (*Logic, usize) void) void {
    const width = self.config.width;
    const height = self.config.height;

    const x: isize = @intCast(cell % width);
    const y: isize = @intCast(cell / width);

    const directions: [16]isize = .{
        -1, -1, // !top-left
        0, -1, // !top
        1, -1, // !top-right
        -1, 0, // !left
        1, 0, // !right
        -1, 1, // !bottom-left
        0, 1, // !bottom
        1, 1, // !bottom-right
    };

    var i: usize = 0;
    while (i < directions.len) : (i += 2) {
        const nx = x + directions[i];
        const ny = y + directions[i + 1];

        if (nx < 0 or nx >= width or
            ny < 0 or ny >= height)
        {
            continue;
        }

        const neighbor =
            @as(usize, @intCast(ny)) * width +
            @as(usize, @intCast(nx));

        func(self, neighbor);
    }
}

fn incrKind(self: *Logic, idx: usize) void {
    if (self.cells[idx] != .MINE)
        self.cells[idx] = @enumFromInt(@intFromEnum(self.cells[idx]) + 1);
}

fn revealRec(self: *Logic, idx: usize) void {
    if (self.state[idx] == .REVEALED)
        return;

    self.state[idx] = .REVEALED;
    if (self.cells[idx] == .ZERO)
        neighbors(self, idx, revealRec);
}

fn revealRecNum(self: *Logic, idx: usize) void {
    if (self.state[idx] == .REVEALED or
        self.state[idx] == .FLAGGED)
        return;

    if (self.cells[idx] == .MINE)
        return;

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
    if (self.gameOver) {
        return false;
    }
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
pub fn kindAt(self: *Logic, x: usize, y: usize) (error{Overflow}!CellKind) {
    return self.cells[try self.xy2idx(x, y)];
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
    if (self.state[idx] == .REVEALED) {
        self.flagged = 0;
        neighbors(self, idx, countFlagged);
        const kindNumber: u8 = @intFromEnum(self.cells[idx]);

        if (self.flagged == @as(usize, kindNumber)) {
            neighbors(self, idx, revealRecNum);
            return;
        }
    }

    if (self.cells[idx] == .MINE) {
        self.cells[idx] = .EXPLODED;
        self.gameOver = true;
        self.revealAll();
        return;
    }

    if (self.state[idx] == .FLAGGED) {
        return;
    }

    revealRec(self, idx);
}

fn revealAll(self: *Logic) void {
    for (0..self.config.width * self.config.height) |i| {
        if (self.state[i] == .HIDDEN)
            self.state[i] = .REVEALED;
    }
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
        .REVEALED => {},
    }
}
