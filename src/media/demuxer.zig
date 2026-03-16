const av = @import("ffmpeg");
const Packet = @import("packet.zig");
const std = @import("std");

const Self = @This();

ptr: *av.FormatContext,

pub fn init(url: [:0]const u8) !Self {
    var ptr: *av.AVFormatContext = undefined;
    const result = av.avformat_open_input(&ptr, url, null, null);
    if (result < 0) return error.FailedToOpenInput;
    errdefer av.avformat_close_input(&ptr);

    try av.avformat_find_stream_info(ptr, null);
    return Self{ .ptr = ptr };
}

pub fn deinit(self: *Self) void {
    av.avformat_close_input(&self.ptr);
}

pub fn next(self: *Self, packet: *Packet) !void {
    const result = av.av_read_frame(self.ptr, packet.ptr);
    if (result < 0) return error.FailedToReadFrame;
}

pub fn streamFromPacket(self: *Self, packet: Packet) *av.Stream {
    return self.ptr.streams[packet.ptr.stream_index];
}

pub fn streams(self: *Self) []*av.Stream {
    return self.ptr.streams[0..self.ptr.nb_streams];
}

pub const StreamInfo = struct {
    stream: *av.Stream,
    info: Info,

    const SelfInfo = @This();
    pub const Info = union(enum) {
        video: struct {
            width: u32,
            height: u32,
            fps: f64,
            bitrate: i64,
        },
        audio: struct {
            sample_rate: u32,
            channels: u32,
        },
        other: av.MediaType,
        pub fn info(self: *SelfInfo) Info {
            const par = self.stream.codecpar;
            return switch (par.codec_type) {
                av.MediaType.VIDEO => Info{ .video = .{
                    .width = par.width,
                    .height = par.height,
                    .fps = par.framerate.q2d(),
                    .bitrate = par.bit_rate,
                } },
                av.MediaType.AUDIO => Info{ .audio = .{
                    .sample_rate = par.sample_rate,
                    .channels = par.ch_layout.nb_channels,
                } },
                else => Info{ .other = par.codec_type },
            };
        }
    };
};

test "hello" {
    var demuxer = try @This().init("f:\\bxb\\other\\zig\\test.mp4");
    defer demuxer.deinit();
    var packet = try Packet.init();
    defer packet.deinit();
    var packet_count: i32 = 0;
    while (true) {
        const stream = demuxer.streamFromPacket(packet);
        std.debug.print("{any}\n", .{stream});
        packet_count += 1;
    }
}
