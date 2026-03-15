const sdl = @import("sdl3");
const checkSDL = @import("internal.zig").checkSDL;
const std = @import("std");

const Self = @This();

window: sdl.video.Window,
renderer: sdl.render.Renderer,

pub fn init(title: [:0]const u8, width: usize, height: usize, is_resizable: bool) !Self {
    var window_flags: sdl.video.Window.Flags = .{ .hidden = true };

    if (is_resizable) {
        window_flags = .{ .hidden = false, .resizable = true };
    }

    var result = try sdl.render.Renderer.initWithWindow(
        title,
        width,
        height,
        window_flags,
    );

    const self = Self{ .window = result.@"0", .renderer = result.@"1" };
    return self;
}

pub fn deinit(self: *Self) void {
    self.renderer.deinit();
    self.window.deinit();
}

pub fn show(self: *Self) !void {
    try self.window.show();
}

const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

pub fn clear(self: *Self, color: Color) !void {
    _ = color;

    try self.renderer.setDrawColorFloat(sdl.pixels.FColor{
        .r = 1.0,
        .g = 1.0,
        .b = 1.0,
        .a = 1.0,
    });
    try self.renderer.clear();
}

pub fn present(self: *Self) !void {
    try self.renderer.present();
}
