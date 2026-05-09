const rl = @import("raylib");

const Assets = @This();

const file = @embedFile("spritesheet.png");
const TILE_SIZE = 8;

textures: [13]rl.Texture2D,

pub const Asset = enum { ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, EXPLODED, MINED, FLAGGED, HIDDEN, ZERO };

pub fn resolve(self: *const Assets, asset: Asset) rl.Texture2D {
    return switch (asset) {
        .ONE => self.textures[0],
        .TWO => self.textures[1],
        .THREE => self.textures[2],
        .FOUR => self.textures[3],
        .FIVE => self.textures[4],
        .SIX => self.textures[5],
        .SEVEN => self.textures[6],
        .EIGHT => self.textures[7],
        .EXPLODED => self.textures[8],
        .MINED => self.textures[9],
        .FLAGGED => self.textures[10],
        .HIDDEN => self.textures[11],
        .ZERO => self.textures[12],
    };
}

pub fn init() rl.RaylibError!Assets {
    const spritesheet = rl.loadImageFromMemory(".png", file) catch unreachable;
    defer spritesheet.unload();

    var textures: [13]rl.Texture2D = undefined;
    for (0..4) |y| {
        for (0..4) |x| {
            if (y * 4 + x > 12)
                break;

            const rec: rl.Rectangle = .{
                .x = @floatFromInt(TILE_SIZE * x),
                .y = @floatFromInt(TILE_SIZE * y),
                .width = @floatFromInt(TILE_SIZE),
                .height = @floatFromInt(TILE_SIZE),
            };
            var cropped = spritesheet.copyRec(rec);
            cropped.resizeNN(TILE_SIZE * 8, TILE_SIZE * 8);
            textures[y * 4 + x] = rl.loadTextureFromImage(cropped) catch unreachable;
        }
    }
    return .{ .textures = textures };
}

pub fn deinit(self: *const Assets) void {
    for (self.textures) |t|
        t.unload();
}
