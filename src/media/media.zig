const Demuxer = @import("demuxer.zig");
const Decoder = @import("decoder.zig");
const Stream = @import("stream.zig");
const Packet = @import("packet.zig");
const Frame = @import("frame.zig");
const MediaType = @import("ffmpeg").MediaType;
const std = @import("std");

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

    // 将 stream 传递给解码器以便设置 time_base
    var video_decoder = try Decoder.init(video_stream, 1);
    errdefer video_decoder.deinit();
    var audio_decoder = try Decoder.init(audio_stream, 2);
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
        // 刷新解码器获取剩余帧
        self.video_decoder.flush() catch {};
        self.audio_decoder.flush() catch {};
        self.is_flushed = true;
        self.is_pending_packet = false;
        return false;
    }

    // 从解复用器读取下一个数据包
    self.demuxer.next(&self.packet) catch |err| {
        if (err == error.EndOfFile) {
            // 刷新解码器获取剩余帧
            self.video_decoder.flush() catch {};
            self.audio_decoder.flush() catch {};
            return false;
        }
        return err;
    };
    self.is_pending_packet = true;
    return true;
}
pub fn feed(self: *Self) !void {
    const decoder = if (self.packet.stream_index() == self.video_stream.index()) &self.video_decoder else if (self.packet.stream_index() == self.audio_stream.index()) &self.audio_decoder else {
        self.is_pending_packet = false;
        return;
    };

    decoder.push(self.packet) catch {
        // EndOfFile 意味着解码器已处理完所有输入，这是正常的
        // 忽略此错误，继续尝试获取帧

        self.is_pending_packet = false;
        return;
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
