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

    // 将反斜杠转换为正斜杠（FFmpeg 需要）
    var path_buf: [512]u8 = undefined;
    var path_len: usize = 0;
    for (url_raw) |c| {
        path_buf[path_len] = if (c == '\\') '/' else c;
        path_len += 1;
    }
    
    // 转换为以 null 结尾的字符串
    const url = try std.fmt.bufPrintZ(&path_buf, "{s}", .{path_buf[0..path_len]});

    var app = try App.init(.{ .title = "media_player", .url = url, .width = 800, .height = 600, .is_resizable = true });
    try app.run();

    defer app.deinit();
}
