const std = @import("std");

const App = @import("app.zig");
const media_player = @import("media_player");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    const arg_iter = init.minimal.args;

    var iter = try std.process.Args.iterateAllocator(arg_iter, allocator);
    defer iter.deinit();
    _ = iter.skip();

    const url_raw = iter.next() orelse "test.mp4";

    // Windows 路径需要转换为正斜杠，并添加 file:// 前缀
    var buf: [512]u8 = undefined;
    // 将反斜杠替换为正斜杠
    var path_buf: [512]u8 = undefined;
    var path_len: usize = 0;
    for (url_raw) |c| {
        if (c == '\\') {
            path_buf[path_len] = '/';
        } else {
            path_buf[path_len] = c;
        }
        path_len += 1;
    }
    const url = try std.fmt.bufPrintZ(&buf, "file:///{s}", .{path_buf[0..path_len]});

    var app = try App.init(.{ .title = "media_player", .url = url, .width = 800, .height = 600, .is_resizable = true });
    try app.run();

    defer app.deinit();
}
