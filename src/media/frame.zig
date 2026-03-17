const std = @import("std");
const av = @import("ffmpeg");

const Self = @This();
ptr: *av.Frame,

pub fn init() !Self {
    const ptr = try av.Frame.alloc();
    return .{ .ptr = ptr };
}

pub fn deinit(self: Self) void {
    self.ptr.free();
}

pub fn yuv_data(self: Self) [3][]const u8 {
    const data = self.ptr.data;
    const linesize = self.ptr.linesize;
    return .{
        data[0][0..@intCast(linesize[0])],
        data[1][0..@intCast(linesize[1])],
        data[2][0..@intCast(linesize[2])],
    };
}

pub fn stride(self: Self) [3]usize {
    const linesize = self.ptr.linesize;
    return .{ @intCast(linesize[0]), @intCast(linesize[1]), @intCast(linesize[2]) };
}
