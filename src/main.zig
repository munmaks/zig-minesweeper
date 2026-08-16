const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");
const ui = @import("ui");
const logic = @import("logic");

const Assets = @import("assets");

const zig_minesweeper = @import("zig_minesweeper");

pub fn main(init: std.process.Init) !void {
    // // Accessing command line arguments:
    // const args = try init.minimal.args.toSlice(arena);
    // for (args) |arg| {
    //     std.log.info("arg: {s}", .{arg});
    // }

    // // In order to do I/O operations need an `Io` instance.
    const io = init.io;
    const gpa = init.gpa;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth: usize = 1024;
    const screenHeight: usize = 720;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var seed: u64 = undefined;
    io.random(std.mem.asBytes(&seed));

    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

    // ! for now let's say a medium difficulty:
    // ! easy: 15 mines, medium: 30 mines, hard: 45 mines
    const numMines = 30;

    var game = try logic.Logic.init(gpa, .{
        .width = screenWidth / 64,
        .height = screenHeight / 64,
        .mines = numMines,
        .seed = random.int(u64), // random number
    });

    defer game.deinit(gpa);

    const assets = try Assets.init();
    defer assets.deinit();

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        if (game.isOver()) |over| {
            if (over) {
                try stdout_writer.print("You Win!\n", .{});
            } else {
                try stdout_writer.print("You Lose!\n", .{});
            }
            try stdout_writer.print("Diffused: <{}>, total: <{}>\nrevealed: <{}>\n", .{
                game.diffused,
                game.config.mines,
                game.revealedCount(),
            });

            // ! [DEBUG] wait 5
            rl.waitTime(5);
            break;
        }

        if (rl.isMouseButtonPressed(rl.MouseButton.left) or
            rl.isMouseButtonPressed(rl.MouseButton.right))
        {
            const mousePos = rl.getMousePosition();
            const intX: usize = @intFromFloat(mousePos.x);
            const intY: usize = @intFromFloat(mousePos.y);
            const x = @divTrunc(intX, 64);
            const y = @divTrunc(intY, 64);
            if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
                try game.reveal(x, y);
            } else if (rl.isMouseButtonPressed(rl.MouseButton.right)) {
                try game.flagAt(x, y);
            }

            try ui.showMousePosition(mousePos, stdout_writer);
        }

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        try ui.drawGrid(&game, assets);

        // rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        //----------------------------------------------------------------------------------
    }

    try stdout_writer.flush();
}
