const std = @import("std");

const rl = @import("raylib");
const game = @import("game");

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

pub fn drawGrid(texture: rl.Texture2D, screenWidth: usize, screenHeight: usize) !void {
    // _ = screenHeight;
    // _ = screenWidth;

    // rl.drawTexture(texture, 0, 0, .white);

    for (0..screenHeight / cell_size) |i| {
        for (0..screenWidth / cell_size) |j| {
            // _ = i;
            // _ = j;
            const x: i32 = @intCast(j * cell_size);
            const y: i32 = @intCast(i * cell_size);
            rl.drawTexture(texture, x, y, .white);
        }
    }
}
