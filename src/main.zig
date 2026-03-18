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
    var path_fixed: [512]u8 = undefined;
    var path_len: usize = 0;
    for (url_raw) |c| {
        if (c == '"') continue; // 跳过引号
        path_fixed[path_len] = if (c == '\\') '/' else c;
        path_len += 1;
    }

    // 转换为以 null 结尾的字符串
    // 对于绝对路径，添加 "file:" 前缀
    var url_buf: [512]u8 = undefined;
    var url: [:0]const u8 = undefined;
    if (path_len >= 2 and path_fixed[1] == ':') {
        // Windows 绝对路径如 "F:/..." -> "file:F:/..."
        url = std.fmt.bufPrintZ(&url_buf, "file:{s}", .{path_fixed[0..path_len]}) catch unreachable;
    } else if (path_len >= 1 and path_fixed[0] == '/') {
        // Unix 绝对路径 -> "file:/..."
        url = std.fmt.bufPrintZ(&url_buf, "file:{s}", .{path_fixed[0..path_len]}) catch unreachable;
    } else {
        // 相对路径保持原样
        url = std.fmt.bufPrintZ(&url_buf, "{s}", .{path_fixed[0..path_len]}) catch unreachable;
    }

    var app = try App.init(.{ .title = "media_player", .url = url, .width = 800, .height = 600, .is_resizable = true });
    try app.run();

    defer app.deinit();
}
