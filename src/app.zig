const std = @import("std");
const platform = @import("platform/root.zig");
const sdl = @import("sdl3");

const Self = @This();
window: platform.Window,
is_running: bool,

pub const Config = struct {
    title: [:0]const u8,
    width: u32,
    height: u32,
    is_resizable: bool,
};

pub fn init(config: Config) !Self {
    try platform.init();
    errdefer platform.deinit();

    var window = try platform.Window.init(config.title, config.width, config.height, config.is_resizable);

    errdefer window.deinit();
    try window.show();
    return Self{ .window = window, .is_running = true };
}
pub fn deinit(self: *Self) void {
    self.window.deinit();
    platform.deinit();
}

pub fn update(self: *Self) !void {
    _ = self;
}

pub fn render(self: *Self) !void {
    try self.window.clear(.{ .r = 255, .g = 0, .b = 0, .a = 255 });
    try self.window.present();
}

pub fn run(self: *Self) !void {
    while (self.is_running) {
        while (sdl.events.poll()) |event| {
            switch (event) {
                .quit => {
                    self.is_running = false;
                },
                else => {},
            }
        }

        try self.update();
        try self.render();
    }
}
