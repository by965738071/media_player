const av = @import("ffmpeg");
const Packet = @import("packet.zig");
const std = @import("std");
const Stream = @import("stream.zig");
const StreamInfo = @import("stream.zig").StreamInfo;

const Self = @This();

ptr: ?*av.FormatContext,

pub fn init(url: [:0]const u8) !Self {
    std.debug.print("Opening: {s}\n", .{url});

    var ptr: ?*av.FormatContext = null;
    const result = av.avformat_open_input(&ptr, url, null, null);
    if (result < 0) {
        std.debug.print("avformat_open_input failed with error code: {}\n", .{result});
        return error.FailedToOpenInput;
    }
    errdefer av.avformat_close_input(&ptr);

    // 跳过 avformat_find_stream_info 以避免段错误
    _ = av.avformat_find_stream_info(ptr.?, null);

    return Self{ .ptr = ptr.? };
}

pub fn deinit(self: *Self) void {
    av.avformat_close_input(&self.ptr);
}

pub fn next(self: *Self, packet: *Packet) !void {
    const result = av.av_read_frame(self.ptr.?, packet.ptr);
    if (result < 0) return error.FailedToReadFrame;
}

pub fn streamFromPacket(self: *Self, packet: Packet) !Stream {
    const stream = self.ptr.?.streams[@intCast(packet.ptr.stream_index)];
    return Stream.init(stream);
}

pub fn streams(self: *Self) []*av.Stream {
    return self.ptr.streams[0..self.ptr.nb_streams];
}

pub fn bestStream(self: *Self, mediaType: av.MediaType, relatedStream: ?Stream) Stream {
    const result = av.av_find_best_stream(
        self.ptr.?,
        mediaType,
        -1,
        if (relatedStream) |r| @intCast(r.index()) else 0,
        null,
        0,
    );
    const stream = try Stream.init(self.ptr.?.streams[@intCast(result)]);

    return stream;
}
