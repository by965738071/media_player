pub const Window = @import("window.zig");
pub const Event = @import("event.zig").Event;
pub const sdl = @import("sdl3");

pub fn init() !void {
    try sdl.init(.{
        .video = true,
        .audio = true,
    });
}

pub fn deinit() void {
    sdl.quit(.{ .video = true, .audio = true });
}
