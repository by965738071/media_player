const demuxer = @import("demuxer.zig");
const packet = @import("packet.zig");
const std = @import("std");
const Stream = @import("stream.zig");
test "demuxer init and read" {
    var de = try demuxer.init("test.mp4");
    defer de.deinit();

    // Get video stream
    const video_stream = de.bestStream(.VIDEO, null);
    if (video_stream) |stream| {
        const info = try Stream.init(stream);
        switch (info.info) {
            .video => |v| {
                std.debug.print("video: width={}, height={}\n", .{ v.width, v.height });
            },
            else => {},
        }
    }

    // Read a few packets
    var pkt = try packet.init();
    defer pkt.deinit();

    var count: u32 = 0;
    while (count < 10) {
        de.next(&pkt) catch break;
        _ = try de.streamFromPacket(pkt);
        count += 1;
    }

    std.debug.print("read {} packets\n", .{count});
}
