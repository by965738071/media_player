const std = @import("std");
const assert = std.debug.assert;

pub fn CircularQueue(comptime T: type) type {
    return struct {
        const Self = @This();
        const Index = usize;
        items: [*]T,
        mask: Index,
        head: Index = 0,
        tail: Index = 0,
        count: Index = 0,

        pub fn init(data: []T) Self {
            return Self{
                .items = data.ptr,
                .mask = data.len - 1,
            };
        }
        pub fn index(self: *const Self, i: Index) Index {
            // return @mod(i, self.items.len);
            return i % self.mask;
        }
        pub fn isEmpty(self: *const Self) bool {
            return self.head == self.tail;
        }
        pub fn isFull(self: *const Self) bool {
            return self.head == self.index(self.tail + 1);
        }

        pub fn push(self: *Self, item: T) void {
            assert(!self.isFull());
            self.items[self.tail] = item;
            self.tail = self.index(self.tail + 1);
            self.count += 1;
        }
        pub fn pop(self: *Self) T {
            assert(!self.isEmpty());
            const item = self.items[self.head];
            self.head = self.index(self.head + 1);
            self.count -= 1;
            return item;
        }
    };
}
