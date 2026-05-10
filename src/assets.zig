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

fn textureFromRec(rec: rl.Rectangle) rl.RaylibError!rl.Texture {
    var image = try rl.loadImageFromMemory(".png", file);
    defer image.unload();
    image.crop(rec);
    image.resizeNN(TILE_SIZE * 8, TILE_SIZE * 8);
    return try rl.loadTextureFromImage(image);
}

pub fn init() rl.RaylibError!Assets {
    var textures: [13]rl.Texture2D = undefined;
    for (0..4) |y| {
        for (0..4) |x| {
            if (y * 4 + x > 12)
                break;

            textures[y * 4 + x] = try textureFromRec(.{
                .x = @floatFromInt(TILE_SIZE * x),
                .y = @floatFromInt(TILE_SIZE * y),
                .width = @floatFromInt(TILE_SIZE),
                .height = @floatFromInt(TILE_SIZE),
            });
        }
    }
    return .{ .textures = textures };
}

pub fn deinit(self: *const Assets) void {
    for (self.textures) |t|
        t.unload();
}
