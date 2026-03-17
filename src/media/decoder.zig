const av = @import("ffmpeg");
const std = @import("std");
const Packet = @import("packet.zig");
const Frame = @import("frame.zig");

const Self = @This();

ptr: *av.Codec.Context,

pub fn init(codec_parameters: *av.Codec.Parameters, thread_count: u32) !Self {
    const codec = try av.Codec.find_decoder(codec_parameters.codec_id);
    var ctx = try av.Codec.Context.alloc(codec);
    ctx.thread_count = @intCast(thread_count);
    errdefer ctx.free();
    try ctx.parameters_to_context(codec_parameters);

    return Self{ .ptr = ctx };
}

pub fn deinit(self: *Self) void {
    self.ptr.free();
}

pub fn push(self: *Self, packet: Packet) !void {
    try self.ptr.send_packet(packet.ptr);
}

pub fn pull(self: *Self, frame: *Frame) !bool {
    self.ptr.receive_frame(frame.ptr) catch return false;
    return true;
}

pub fn clear(self: *Self) void {
    self.ptr.flush_buffers();
}

pub fn flush(self: *Self) !void {
    try self.ptr.send_packet(null);
}
