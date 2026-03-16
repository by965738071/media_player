const std = @import("std");
const CircularQueue = @import("circular_queue.zig").CircularQueue;

pub fn Channel(comptime T: type, io: std.Io) type {
    return struct {
        const Self = @This();
        queue: CircularQueue(T),
        mutex: std.Io.Mutex = .init,
        not_empty: std.Io.Condition = .init,
        not_full: std.Io.Condition = .init,
        io: std.Io,
        is_closed: bool = false,

        pub fn init(data: []T) Self {
            return Self{
                .queue = CircularQueue(T).init(data),
                .io = io,
            };
        }
        pub fn push(self: *Self, item: T) !void {
            try self.mutex.lock(self.io);
            defer self.mutex.unlock(self.io);

            while (self.queue.isFull()) {
                if (self.is_closed) return error.Closed;
                try self.not_full.wait(io, &self.mutex);
            }

            self.queue.push(item);
            self.not_empty.signal(self.io);
        }

        pub fn pop(self: *Self) !?T {
            try self.mutex.lock(self.io);
            defer self.mutex.unlock(self.io);

            while (self.queue.isEmpty()) {
                if (self.is_closed) return null;
                try self.not_empty.wait(self.io, &self.mutex);
            }

            const item = self.queue.pop();
            self.not_full.signal(self.io);
            return item;
        }
        pub fn tryPush(self: *Self, item: T) !bool {
            try self.mutex.lock(self.io);
            defer self.mutex.unlock(self.io);

            if (self.queue.isFull() or self.queue.isFull()) return false;

            self.queue.push(item);
            self.not_empty.signal(self.io);
            return true;
        }

        pub fn tryPop(self: *Self) !?T {
            try self.mutex.lock(self.io);
            defer self.mutex.unlock(self.io);
            if (self.is_closed or self.queue.isEmpty()) return null;
            const item = self.queue.pop();
            self.not_full.signal(self.io);
            return item;
        }

        pub fn close(self: *Self) void {
            self.mutex.lock(self.io);
            defer self.mutex.unlock(self.io);
            self.is_closed = true;
            self.not_empty.broadcast(self.io);
            self.not_full.broadcast(self.io);
        }
    };
}

test "channel" {
    const io = std.testing.io;
    var items: [10]usize = undefined;
    var channel = Channel(usize, io).init(&items);
    for (0..6) |i| {
        try channel.push(i);
    }
    for (0..6) |x| {
        const item = try channel.pop();
        try std.testing.expectEqual(item, x);
    }
}
