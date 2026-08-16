const rl = @import("raylib");

pub const Assets = @This();

const spritesheet = @embedFile("spritesheet.png");
const TILE_SIZE = 8;
const MAX_TEXTURES = 13;

textures: [MAX_TEXTURES]rl.Texture2D,

pub const Asset = enum(u8) {
    ONE = 0,
    TWO = 1,
    THREE = 2,
    FOUR = 3,
    FIVE = 4,
    SIX = 5,
    SEVEN = 6,
    EIGHT = 7,
    EXPLODED = 8,
    MINED = 9,
    FLAGGED = 10,
    HIDDEN = 11,
    ZERO = 12,
};

pub fn resolve(self: *const Assets, asset: Asset) rl.Texture2D {
    // return switch (asset) {
    //     .ONE => self.textures[0],
    //     .TWO => self.textures[1],
    //     ...
    //     .ZERO => self.textures[12],
    // };
    return self.textures[@as(usize, @intFromEnum(asset))];
}

fn textureFromRec(rec: rl.Rectangle) rl.RaylibError!rl.Texture {
    var image = try rl.loadImageFromMemory(".png", spritesheet);
    defer image.unload();
    image.crop(rec);
    image.resizeNN(TILE_SIZE * TILE_SIZE, TILE_SIZE * TILE_SIZE);
    return try rl.loadTextureFromImage(image);
}

pub fn init() rl.RaylibError!Assets {
    var textures: [MAX_TEXTURES]rl.Texture2D = undefined;
    for (0..MAX_TEXTURES) |i| {
        const x = i % 4;
        const y = i / 4;
        textures[i] = try textureFromRec(.{
            .x = @floatFromInt(x * TILE_SIZE),
            .y = @floatFromInt(y * TILE_SIZE),
            .width = @floatFromInt(TILE_SIZE),
            .height = @floatFromInt(TILE_SIZE),
        });
    }
    return .{ .textures = textures };
}

pub fn deinit(self: *const Assets) void {
    for (self.textures) |t|
        t.unload();
}
