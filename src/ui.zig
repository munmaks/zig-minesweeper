const std = @import("std");

const rl = @import("raylib");
const Logic = @import("logic");
const Assets = @import("assets");
const Asset = Assets.Asset;

const cell_size: usize = 64;
const fileName = "./assets/spritesheet.png"; // Use absolute path for debugging

const color: rl.Color = .{
    .r = 255,
    .g = 0,
    .b = 0,
    .a = 255,
};

const imgColor: rl.Color = .{
    .r = 0,
    .g = 245,
    .b = 0,
    .a = 255,
};

pub fn showMousePosition(mousePos: rl.Vector2, stdout_writer: *std.Io.Writer) !void {
    const x: usize = @intFromFloat(mousePos.x);
    const y: usize = @intFromFloat(mousePos.y);
    const cellX = @divTrunc(x, cell_size);
    const cellY = @divTrunc(y, cell_size);
    // Print the mouse position to stdout
    try stdout_writer.print(
        "Cell Position: ({}, {})\n",
        .{ cellX, cellY },
    );
    try stdout_writer.flush();
}

fn resolveTexture(assets: Assets, kind: Logic.CellKind) rl.Texture2D {
    return switch (kind) {
        .ZERO => assets.resolve(.ZERO),
        .ONE => assets.resolve(.ONE),
        .TWO => assets.resolve(.TWO),
        .THREE => assets.resolve(.THREE),
        .FOUR => assets.resolve(.FOUR),
        .FIVE => assets.resolve(.FIVE),
        .SIX => assets.resolve(.SIX),
        .SEVEN => assets.resolve(.SEVEN),
        .EIGHT => assets.resolve(.EIGHT),
        .MINE => assets.resolve(.MINED),
        .EXPLODED => assets.resolve(.EXPLODED),
    };
    // const intKind = @intFromEnum(kind);
    // const asset: Asset = @enumFromInt(intKind);
    // return assets.resolve(asset);
}

pub fn drawGrid(game: *Logic, assets: Assets) !void {
    for (0..game.config.width) |x| {
        for (0..game.config.height) |y| {
            const texture =
                switch (try game.stateAt(x, y)) {
                    .FLAGGED => assets.resolve(.FLAGGED),
                    .HIDDEN => assets.resolve(.HIDDEN),
                    .REVEALED => resolveTexture(assets, try game.kindAt(x, y)),
                };
            rl.drawTexture(
                texture,
                @intCast(x * cell_size),
                @intCast(y * cell_size),
                .white,
            );
        }
    }
}
