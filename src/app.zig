const std = @import("std");
const platform = @import("platform");
const sdl = @import("sdl3");
const Media = @import("media").Media;
const Self = @This();
window: platform.Window,
is_running: bool,
media: Media,
texture: platform.Texture,

pub const Config = struct {
    title: [:0]const u8,
    width: u32,
    height: u32,
    is_resizable: bool,
    url: [:0]const u8,
};

pub fn init(config: Config) !Self {
    try platform.init();
    errdefer platform.deinit();

    var window = try platform.Window.init(config.title, config.width, config.height, config.is_resizable);

    errdefer window.deinit();

    var media = try Media.init(config.url);
    errdefer media.deinit();

    var texture = try platform.Texture.init(window, media.dimensions());
    errdefer texture.deinit();

    try window.show();
    return Self{
        .window = window,
        .is_running = true,
        .media = media,
        .texture = texture,
    };
}
pub fn deinit(self: *Self) void {
    self.texture.deinit();
    self.media.deinit();
    self.window.deinit();
    platform.deinit();
}

pub fn update(self: *Self) !void {
    if (try self.media.next()) |frame| {
        try self.texture.updateYuv(frame.yuv_data(), frame.stride());
    }
}

pub fn render(self: *Self) !void {
    try self.window.clear(.{ .r = 0, .g = 0, .b = 0, .a = 255 });
    try self.texture.render();
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
