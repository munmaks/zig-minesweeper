const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");
const ui = @import("ui");
const game = @import("game");

const Assets = @import("assets.zig");
const Asset = Assets.Asset;

const zig_minesweeper = @import("zig_minesweeper");

pub fn main(init: std.process.Init) !void {
    // _ = init;
    // // Prints to stderr, unbuffered, ignoring potential errors.
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // // This is appropriate for anything that lives as long as the process.
    // const arena: std.mem.Allocator = init.arena.allocator();

    // // Accessing command line arguments:
    // const args = try init.minimal.args.toSlice(arena);
    // for (args) |arg| {
    //     std.log.info("arg: {s}", .{arg});
    // }

    // // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    // try zig_minesweeper.printAnotherMessage(stdout_writer);

    // try stdout_writer.flush(); // Don't forget to flush!

    // const pixels: [32 * 32]u8 = undefined;

    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1024;
    const screenHeight = 720;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Load the texture once
    // var textures: [8]rl.Texture2D = undefined;
    // const img: rl.Image = try rl.loadImage("./assets/spritesheet.png");
    // defer rl.unloadImage(img);

    // // for (game.CellKind) |kind| {
    // for (1..9) |i| {
    //     // _ = kind;

    //     rl.imageCrop(&img, (rl.Rectangle){
    //         .x = 0,
    //         .y = 0,
    //         .width = 8,
    //         .height = 8,
    //     });

    //     const oneDigitSize = 8;

    //     // Resize flipped-cropped image
    //     rl.imageResize(&img, oneDigitSize * 8, oneDigitSize * 8);
    //     const texture: rl.Texture2D = try rl.loadTextureFromImage(img);
    //     textures[i] = texture;
    //     // defer rl.unloadTexture(texture); // Unload the texture when the program exits
    // }

    const assets = try Assets.init();
    defer assets.deinit();

    var i: usize = 0;
    var j: usize = 0;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------
        j += 1;
        if (j > 60) {
            j = 0;
            i = (i + 1) % 13;
        }

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        // ! avoid copy-paste
        if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
            const vec = rl.getMousePosition();
            try stdout_writer.print("Left click ({d}, {d})\n", .{ vec.x, vec.y });
            try stdout_writer.flush();
        } else if (rl.isMouseButtonPressed(rl.MouseButton.right)) {
            const vec = rl.getMousePosition();
            try stdout_writer.print("Right click ({d}, {d})\n", .{ vec.x, vec.y });
            try stdout_writer.flush();
        }

        rl.clearBackground(.white);
        try ui.drawGrid(assets.textures[i], screenWidth, screenHeight); // Pass the preloaded texture

        // rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        //----------------------------------------------------------------------------------
    }

    // try stdout_writer.flush();
}

// fn loadDigitOne() void {}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    try std.testing.fuzz({}, testOne, .{});
}

fn testOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;
    // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!

    const gpa = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(gpa);
    while (!smith.eos()) switch (smith.value(enum { add_data, dup_data })) {
        .add_data => {
            const slice = try list.addManyAsSlice(gpa, smith.value(u4));
            smith.bytes(slice);
        },
        .dup_data => {
            if (list.items.len == 0) continue;
            if (list.items.len > std.math.maxInt(u32)) return error.SkipZigTest;
            const len = smith.valueRangeAtMost(u32, 1, @min(32, list.items.len));
            const off = smith.valueRangeAtMost(u32, 0, @intCast(list.items.len - len));
            try list.appendSlice(gpa, list.items[off..][0..len]);
            try std.testing.expectEqualSlices(
                u8,
                list.items[off..][0..len],
                list.items[list.items.len - len ..],
            );
        },
    };
}
