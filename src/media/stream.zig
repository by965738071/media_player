const av = @import("ffmpeg");
const std = @import("std");

avStream: *av.Stream,
info: StreamInfo,

const Self = @This();

pub fn init(stream: *av.Stream) !Self {
    const par = stream.codecpar;
    const info: StreamInfo = switch (par.codec_type) {
        .VIDEO => StreamInfo{ .video = .{
            .width = @intCast(par.width),
            .height = @intCast(par.height),
            .fps = par.framerate.q2d(),
            .bitrate = par.bit_rate,
        } },
        .AUDIO => StreamInfo{ .audio = .{
            .sample_rate = @intCast(par.sample_rate),
            .channels = @intCast(par.ch_layout.nb_channels),
        } },
        else => StreamInfo{ .other = par.codec_type },
    };
    return Self{ .avStream = stream, .info = info };
}

pub fn index(self: Self) usize {
    return @intCast(self.avStream.index);
}

pub fn codec_parameters(self: Self) *av.Codec.Parameters {
    return self.avStream.codecpar;
}

pub const StreamInfo = union(enum) {
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
};
