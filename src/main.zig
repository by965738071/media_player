const std = @import("std");
const Io = std.Io;
const App = @import("app.zig");
const media_player = @import("media_player");

pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // This is appropriate for anything that lives as long as the process.
    // const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:

    // In order to do I/O operations need an `Io` instance.
    // const io = init.io;
    _ = init;
    var app = try App.init(.{ .title = "media_player", .width = 800, .height = 600, .is_resizable = true });
    try app.run();

    defer app.deinit();
}
