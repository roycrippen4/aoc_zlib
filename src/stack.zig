const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

pub fn is_primitive_type(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .bool, .void, .noreturn, .@"opaque", .type => true,
        else => false,
    };
}

test "stack is_primitive_type" {
    try testing.expect(is_primitive_type(usize));
    try testing.expect(is_primitive_type(bool));
    try testing.expect(!is_primitive_type([]const u8));
    try testing.expect(!is_primitive_type(struct { bar: bool }));
}

pub fn Stack(comptime T: type, comptime N: usize) type {
    return struct {
        /// Number of items currently used by the stack
        len: usize = 0,

        /// Underlying data inside the stack
        items: [N]T = undefined,

        /// Total capacity for this stack
        capacity: usize = N,

        const Self = @This();

        /// Fills out the backing array with a default value.
        /// Does not change the length of the backing array or the pointer to the first element.
        /// Clobbers any existing data in the array.
        pub inline fn fill(self: *Self, value: T) void {
            self.items = @splat(value);
            self.len = 0;
        }

        /// Access an item in the stack
        /// Returns null if the index is out of bounds
        pub inline fn idx(self: *const Self, i: usize) ?T {
            if (i >= self.len) return null;
            return self.items[i];
        }

        /// Clears out the stack.
        /// Does not clobber existing data
        pub inline fn clear(self: *Self) void {
            self.len = 0;
        }

        /// Clears out the stack and sets contents to undefined
        pub inline fn clear_and_clean(self: *Self) void {
            self.items = undefined;
            self.len = 0;
        }

        /// Push an item onto the slice.
        /// Does not grow the slice.
        /// Does not check for out of bounds insertion
        pub inline fn push(self: *Self, item: T) void {
            self.items[self.len] = item;
            self.len += 1;
        }

        pub inline fn to_slice(self: Self) []const T {
            return self.items[0..self.len];
        }

        pub inline fn push_safe(self: *Self, item: T) !void {
            if (self.len == self.capacity) return error.NoCapacity;
            self.items[self.len] = item;
            self.len += 1;
        }

        /// Pop an item off the stack.
        /// Returns null if this function is called on an empty stack
        pub inline fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            self.len -= 1;
            const value = self.items[self.len];
            self.items[self.len] = undefined;
            return value;
        }

        /// Pop an item off the stack.
        /// Returns null if this function is called on an empty stack.
        /// Same as `pop`, but does not set the popped element to `undefined` in the backing array;
        pub inline fn pop_noclear(self: *Self) ?T {
            if (self.len == 0) return null;
            self.len -= 1;
            return self.items[self.len];
        }

        /// Returns a copy the contents of the stack's backing array.
        /// The caller owns the returned memory and is expected to free it.
        pub fn copy(self: Self, gpa: Allocator) ![]T {
            const buf = try gpa.alloc(T, self.capacity);
            @memcpy(buf, &self.items);
            return buf;
        }

        /// Returns the value at the top of the stack without removing it.
        /// Returns null if the stack is empty.
        pub inline fn peek(self: *const Self) ?T {
            if (self.len == 0) return null;
            return self.items[self.len - 1];
        }

        pub inline fn is_empty(self: *const Self) bool {
            return self.len == 0;
        }

        pub inline fn iterator(self: *const Self) StackIterator(T) {
            return .{ .items = self.items[0..self.len] };
        }

        /// Returns `true` if the stack contains the `needle` within its initialized memory slice.
        pub fn contains(self: *const Self, needle: T) bool {
            const items = self.items[0..self.len];

            if (comptime is_primitive_type(T)) {
                return std.mem.indexOfScalar(T, items, needle) != null;
            } else {
                for (items) |item| if (std.meta.eql(item, needle)) return true;
                return false;
            }
        }

        pub fn format(self: Self, writer: *std.io.Writer) std.io.Writer.Error!void {
            if (self.is_empty()) {
                try writer.print("Stack{{ len = 0, capacity = {d}, items = {{}} }}", .{self.capacity});
                return;
            }

            const fmt = switch (@typeInfo(T)) {
                .int => "        {d},\n",
                .float => "        {d.5}\n",
                .bool => "        {},\n",
                .null => "        null,\n",
                else => "        {any},\n",
            };

            try writer.print("Stack{{\n    len = {d},\n    capacity = {d},\n    items = {{\n", .{ self.len, self.capacity });
            for (self.items[0..self.len]) |item| try writer.print(fmt, .{item});
            try writer.print("    }}\n}}", .{});
        }
    };
}
test "stack contains" {
    var s: Stack(usize, 10) = .{
        .items = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
        .len = 10,
        .capacity = 10,
    };

    try testing.expect(!s.contains(11));
    try testing.expect(s.contains(6));
    try testing.expect(s.contains(9));
}

fn StackIterator(comptime T: type) type {
    return struct {
        items: []const T,
        index: usize = 0,

        const Self = @This();

        pub inline fn next(self: *Self) ?T {
            if (self.index >= self.items.len) return null;

            const item = self.items[self.index];
            self.index += 1;
            return item;
        }

        pub inline fn peek(self: *Self) ?T {
            if (self.index == self.items.len) return null;
            return self.items[self.index];
        }
    };
}

test "stack push and pop" {
    var stack: Stack(u32, 5) = .{};
    try testing.expectEqual(@as(usize, 0), stack.len);
    try testing.expect(stack.is_empty());

    stack.push(10);
    try testing.expectEqual(@as(usize, 1), stack.len);
    try testing.expect(!stack.is_empty());

    stack.push(20);
    try testing.expectEqual(@as(usize, 2), stack.len);

    const item1 = stack.pop().?;
    try testing.expectEqual(@as(u32, 20), item1);
    try testing.expectEqual(@as(usize, 1), stack.len);

    const item2 = stack.pop().?;
    try testing.expectEqual(@as(u32, 10), item2);
    try testing.expectEqual(@as(usize, 0), stack.len);
    try testing.expect(stack.is_empty());
}

test "stack push to capacity" {
    var stack: Stack(i8, 3) = .{};

    try stack.push_safe(1);
    try stack.push_safe(2);
    try stack.push_safe(3);

    try testing.expectEqual(@as(usize, 3), stack.len);
    try testing.expectEqual(stack.len, stack.capacity);

    const result = stack.push_safe(4);
    try testing.expectError(error.NoCapacity, result);
    try testing.expectEqual(@as(usize, 3), stack.len);
}

test "stack pop from empty" {
    var stack: Stack(bool, 5) = .{};
    const result = stack.pop();
    try testing.expectEqual(null, result);
    try testing.expectEqual(@as(usize, 0), stack.len);
}

test "stack peek" {
    var stack: Stack(u16, 4) = .{};

    stack.push(100);
    stack.push(200);

    const top_value = stack.peek();
    try testing.expectEqual(200, top_value);
    try testing.expectEqual(2, stack.len);

    _ = stack.pop();

    const next_top_value = stack.peek();
    try testing.expectEqual(100, next_top_value);
    try testing.expectEqual(1, stack.len);
}

test "stack peek on empty stack" {
    const stack: Stack(f32, 3) = .{};
    const result = stack.peek();
    try testing.expectEqual(null, result);
}

test "stack idx access" {
    var stack: Stack(u8, 10) = .{};
    stack.push(5);
    stack.push(10);
    stack.push(15);

    try testing.expectEqual(@as(u8, 5), stack.idx(0).?);
    try testing.expectEqual(@as(u8, 10), stack.idx(1).?);
    try testing.expectEqual(@as(u8, 15), stack.idx(2).?);
    try testing.expectEqual(null, stack.idx(3));
    try testing.expectEqual(null, stack.idx(9));
}

test "stack copy" {
    const gpa = testing.allocator;

    var stack: Stack(usize, 4) = .{};
    stack.push(11);
    stack.push(22);

    const copied_slice = try stack.copy(gpa);
    defer gpa.free(copied_slice);

    try testing.expectEqualSlices(usize, &.{
        11,
        22,
        undefined,
        undefined,
    }, copied_slice);

    _ = stack.pop();
    stack.push(33);

    try testing.expectEqualSlices(usize, &.{ 11, 33 }, stack.items[0..stack.len]);
    try testing.expectEqualSlices(usize, &.{ 11, 22, undefined, undefined }, copied_slice);
}
