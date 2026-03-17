const av = @import("ffmpeg");

const Self = @This();
ptr: *av.Packet,

pub fn init() !Self {
    const ptr = try av.Packet.alloc();

    return Self{ .ptr = ptr };
}

pub fn deinit(self: *Self) void {
    av.Packet.free(self.ptr);
}

pub fn stream_index(self: *Self) usize {
    return @intCast(self.ptr.stream_index);
}
