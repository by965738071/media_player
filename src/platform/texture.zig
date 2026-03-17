const std = @import("std");
const Window = @import("window.zig");
const sdl = @import("sdl3");

ptr: sdl.render.Texture,
const Self = @This();

pub fn init(window: Window, dimensions: [2]i32) !Self {
    const texture = try sdl.render.Renderer.createTexture(
        window.renderer,
        sdl.pixels.Format.fourcc_yv12,
        .streaming,
        @intCast(dimensions[0]),
        @intCast(dimensions[1]),
    );
    errdefer texture.deinit();
    return Self{ .ptr = texture };
}

pub fn deinit(self: *Self) void {
    self.ptr.deinit();
}

pub fn updateYuv(self: *Self, data: [3][]const u8, stride: [3]usize) !void {
    try self.ptr.updateYUV(
        null,
        data[0].ptr,
        stride[0],
        data[1].ptr,
        stride[1],
        data[2].ptr,
        stride[2],
    );
}

pub fn render(self: *Self) !void {
    var renderer = try self.ptr.getRenderer();
    try renderer.renderTexture(self.ptr, null, null);
}
