const av = @import("ffmpeg");

const Self = @This();
ptr: *av.Packet,
pub fn init() !Self {
    const ptr = try av.Packet.alloc();
    if (ptr == null) {
        return error.NoMemory;
    }
    return Self{ .ptr = ptr };
}

pub fn deinit(self: *Self) void {
    av.Packet.free(self.ptr);
}
