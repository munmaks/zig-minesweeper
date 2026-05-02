const std = @import("std");

const Error = error{ InvalidConfig, InvalidMove };
const Config = struct { width: u32, height: u32, mines: u32, seed: u64 };
const Move = struct { x: u32, y: u32 };
const State = struct { mines: std.DynamicBitSet, hidden: std.DynamicBitSet };
const Game = struct { config: Config, history: std.ArrayList(Move) };

// initGame creates a new Game instance
pub fn initGame(cfg: Config, alloc: std.mem.Allocator) !Game {
    if (cfg.width * cfg.height < cfg.mines)
        return Error.InvalidConfig;
    _ = alloc;
    return Error.InvalidConfig;
}

// makeMove appends a move and re-evaluates the current state, returning false on Game Over else true
pub fn makeMove(game: Game, move: Move) !bool {
    _ = game;
    _ = move;
    return Error.NotImplemented;
}
