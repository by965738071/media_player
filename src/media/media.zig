const Demuxer = @import("demuxer.zig");
const Decoder = @import("decoder.zig");
const Stream = @import("stream.zig");
const Packet = @import("packet.zig");
const Frame = @import("frame.zig");
const MediaType = @import("ffmpeg").MediaType;

pub const Self = @This();

demuxer: Demuxer,
video_stream: Stream,
audio_stream: Stream,

video_decoder: Decoder,
audio_decoder: Decoder,

packet: Packet,
frame: Frame,
is_pending_packet: bool = false,
is_flushed: bool = false,

pub fn init(url: [:0]const u8) !Self {
    var demuxer = try Demuxer.init(url);
    errdefer demuxer.deinit();

    const video_stream = demuxer.bestStream(MediaType.VIDEO, null);
    const audio_stream = demuxer.bestStream(MediaType.AUDIO, video_stream);

    var video_decoder = try Decoder.init(video_stream.codec_parameters(), 1);
    errdefer video_decoder.deinit();
    var audio_decoder = try Decoder.init(audio_stream.codec_parameters(), 2);
    errdefer audio_decoder.deinit();

    var packet = try Packet.init();
    errdefer packet.deinit();

    var frame = try Frame.init();
    errdefer frame.deinit();

    return Self{
        .demuxer = demuxer,
        .video_stream = video_stream,
        .audio_stream = audio_stream,
        .video_decoder = video_decoder,
        .audio_decoder = audio_decoder,
        .packet = try Packet.init(),
        .frame = try Frame.init(),
    };
}

pub fn deinit(self: *Self) void {
    self.demuxer.deinit();
    self.video_decoder.deinit();
    self.audio_decoder.deinit();
    self.packet.deinit();
    self.frame.deinit();
}

pub fn drain(self: *Self) !?Frame {
    if (try self.video_decoder.pull(&self.frame)) {
        return self.frame;
    }
    if (try self.audio_decoder.pull(&self.frame)) {
        return self.frame;
    }

    return null;
}

pub fn fetch(self: *Self) !bool {
    if (self.is_pending_packet) {
        while (true) {
            try self.video_decoder.flush();
            try self.audio_decoder.flush();
            self.is_flushed = true;
            return false;
        }

        self.is_pending_packet = false;
    }
    return true;
}
pub fn feed(self: *Self) !void {
    const decoder = if (self.packet.stream_index() == self.video_stream.index()) &self.video_decoder else if (self.packet.stream_index() == self.audio_stream.index()) &self.audio_decoder else {
        self.is_pending_packet = false;
        return;
    };

    decoder.push(self.packet) catch |err| {
        self.is_pending_packet = false;
        return err;
    };
}

pub fn next(self: *Self) !?Frame {
    if (try self.drain()) |frame| {
        return frame;
    }

    if (!try self.fetch()) {
        return try self.drain();
    }
    try self.feed();
    return try self.drain();
}

pub fn dimensions(self: *Self) [2]i32 {
    return .{ @intCast(self.video_decoder.ptr.width), @intCast(self.video_decoder.ptr.height) };
}
