const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

/// A double-ended queue (deque) container, available in two variants:
///
/// - **`Deque(T).Dynamic`**: A growable, heap-allocated deque that manages its own memory.
///   It must be initialized with an allocator and deinitialized to prevent memory leaks.
///
/// - **`Deque(T).Static(N)`**: A fixed-size, stack-allocated deque with a compile-time
///   known capacity of `N`. It can hold up to `N-1` elements. The capacity `N`
///   must be a power of two. This variant does not require an allocator.
///
/// ## Usage
///
/// ### Dynamic Deque
/// ```zig
/// const allocator = std.testing.allocator;
///
/// // Initialize an empty dynamic deque
/// var dq_dyn: Deque(u8).Dynamic = .empty;
/// defer dq_dyn.deinit(allocator);
///
/// // Push items
/// try dq_dyn.push_back(allocator, 10);
/// try dq_dyn.push_front(allocator, 9);
///
/// // Initialize with a minimum capacity
/// var dq_cap: Deque(u8).Dynamic = try .init_capacity(allocator, 100);
/// defer dq_cap.deinit(allocator);
/// ```
///
/// ### Static Deque
/// ```zig
/// // Initialize a static deque with capacity 16 (can hold 15 items)
/// var dq_static: Deque(u8).Static(16) = .{};
///
/// // Push items (returns error.DequeFull if capacity is reached)
/// try dq_static.push_back(10);
/// try dq_static.push_front(9);
/// ```
pub fn Deque(comptime T: type) type {
    return struct {
        pub const Dynamic = DequeDynamic(T);
        pub fn Static(comptime N: usize) type {
            return DequeStatic(T, N);
        }
    };
}

fn DequeStatic(comptime T: type, comptime N: usize) type {
    return struct {
        const Self = @This();
        comptime {
            std.debug.assert(std.math.isPowerOfTwo(N) and N > 0);
        }

        /// tail and head are pointers into the buffer. Tail always points
        /// to the first element that could be read, Head always points
        /// to where data should be written.
        /// If tail == head the buffer is empty. The length of the ringbuffer
        /// is defined as the distance between the two.
        tail: usize = 0,
        head: usize = 0,
        /// Users should **NOT** use this field directly.
        /// In order to access an item with an index, use `get` method.
        /// If you want to iterate over the items, call `iterator` method to get an iterator.
        buf: [N]T = undefined,
        /// Capacity of the deque. The deque can hold N-1 items.
        cap: usize = N,

        /// Similar functionality to the DequeDynamic method `clear_retaining_capacity`.
        /// Does not remove any existing data, simply resets both the `head` and `tail` pointers.
        pub inline fn reset(self: *Self) void {
            self.tail = 0;
            self.head = 0;
        }

        pub const CAP = N;

        /// Returns the number of elements in the deque.
        pub inline fn len(self: Self) usize {
            return count(self.tail, self.head, CAP);
        }

        /// Returns true if the deque is empty.
        pub inline fn is_empty(self: Self) bool {
            return self.tail == self.head;
        }

        /// Returns true if the deque is at full capacity.
        pub inline fn is_full(self: Self) bool {
            return self.len() == CAP - 1;
        }

        /// Gets a pointer to the element with the given index, if any.
        /// Otherwise it returns `null`.
        pub inline fn get(self: *const Self, index: usize) ?*const T {
            if (index >= self.len()) return null;

            const idx = self.wrap_add(self.tail, index);
            return &self.buf[idx];
        }

        /// Gets a mutable pointer to the element with the given index, if any.
        /// Otherwise it returns `null`.
        pub inline fn get_mut(self: *Self, index: usize) ?*T {
            if (index >= self.len()) return null;

            const idx = self.wrap_add(self.tail, index);
            return &self.buf[idx];
        }

        /// Gets a pointer to the first element, if any.
        pub inline fn front(self: *const Self) ?*const T {
            return self.get(0);
        }

        /// Gets a pointer to the last element, if any.
        pub inline fn back(self: *const Self) ?*const T {
            const last_idx = std.math.sub(usize, self.len(), 1) catch return null;
            return self.get(last_idx);
        }

        /// Adds the given element to the back of the deque. Returns an error if full.
        pub fn push_back(self: *Self, item: T) error{DequeFull}!void {
            if (self.is_full()) return error.DequeFull;

            const head = self.head;
            self.head = self.wrap_add(self.head, 1);
            self.buf[head] = item;
        }

        /// Adds the given element to the front of the deque. Returns an error if full.
        pub inline fn push_front(self: *Self, item: T) error{DequeFull}!void {
            if (self.is_full()) return error.DequeFull;

            self.tail = self.wrap_sub(self.tail, 1);
            const tail = self.tail;
            self.buf[tail] = item;
        }

        /// Pops and returns the last element of the deque.
        pub inline fn pop_back(self: *Self) ?T {
            if (self.is_empty()) return null;
            self.head = self.wrap_sub(self.head, 1);
            return self.buf[self.head];
        }

        /// Pops and returns the first element of the deque.
        pub fn pop_front(self: *Self) ?T {
            if (self.is_empty()) return null;

            const tail = self.tail;
            self.tail = self.wrap_add(self.tail, 1);
            return self.buf[tail];
        }

        /// Adds all the elements in the given slice to the back of the deque.
        pub fn append_slice(self: *Self, items: []const T) error{DequeFull}!void {
            if (self.len() + items.len >= CAP) return error.DequeFull;
            for (items) |item| {
                try self.push_back(item);
            }
        }

        /// Adds all the elements in the given slice to the front of the deque.
        pub fn prepend_slice(self: *Self, items: []const T) error{DequeFull}!void {
            if (self.len() + items.len >= CAP) return error.DequeFull;
            if (items.len == 0) return;

            var i: usize = items.len - 1;
            while (true) : (i -= 1) {
                const item = items[i];
                try self.push_front(item);
                if (i == 0) break;
            }
        }

        /// Returns an iterator over the deque.
        /// Modifying the deque may invalidate this iterator.
        pub fn iterator(self: Self) DequeDynamic(T).Iterator {
            return .{
                .head = self.head,
                .tail = self.tail,
                .ring = self.buf[0..],
            };
        }

        pub fn format(self: Self, writer: *std.io.Writer) std.io.Writer.Error!void {
            try writer.print("Deque.Static({}){{\n    .buf = {{\n", .{T});

            var it = self.iterator();
            if (it.next()) |val| try writer.print("        {any}", .{val.*});
            while (it.next()) |val| try writer.print(",\n        {any}", .{val.*});

            try writer.print(
                \\
                \\    }},
                \\    .head = {},
                \\    .tail = {},
                \\    .len = {},
                \\}}
            , .{
                self.head,
                self.tail,
                self.len(),
            });
        }

        fn wrap_add(_: Self, idx: usize, addend: usize) usize {
            return wrap_index(idx +% addend, CAP);
        }

        fn wrap_sub(_: Self, idx: usize, subtrahend: usize) usize {
            return wrap_index(idx -% subtrahend, CAP);
        }
    };
}

fn DequeDynamic(comptime T: type) type {
    return struct {
        /// tail and head are pointers into the buffer. Tail always points
        /// to the first element that could be read, Head always points
        /// to where data should be written.
        /// If tail == head the buffer is empty. The length of the ringbuffer
        /// is defined as the distance between the two.
        tail: usize,
        head: usize,
        /// Users should **NOT** use this field directly.
        /// In order to access an item with an index, use `get` method.
        /// If you want to iterate over the items, call `iterator` method to get an iterator.
        buf: []T,

        const Self = @This();
        const INITIAL_CAPACITY = 7; // 2^3 - 1
        const MINIMUM_CAPACITY = 1; // 2 - 1

        pub const empty: Self = .{
            .tail = 0,
            .head = 0,
            .buf = &.{},
        };

        /// Creates an empty deque with space for at least `capacity` elements.
        ///
        /// Note that there is no guarantee that the created Deque has the specified capacity.
        /// If it is too large, this method gives up meeting the capacity requirement.
        /// In that case, it will instead create a Deque with the default capacity anyway.
        ///
        /// Deinitialize with `deinit`.
        pub fn init_capacity(gpa: Allocator, capacity: usize) Allocator.Error!Self {
            const effective_cap =
                std.math.ceilPowerOfTwo(usize, @max(capacity +| 1, MINIMUM_CAPACITY + 1)) catch
                    std.math.ceilPowerOfTwoAssert(usize, INITIAL_CAPACITY + 1);
            const buf = try gpa.alloc(T, effective_cap);
            return .{
                .tail = 0,
                .head = 0,
                .buf = buf,
            };
        }

        /// Clears the Deque without freeing allocated memory.
        /// Invalidates any existing element pointers
        pub fn clear_retaining_capacity(self: *Self) void {
            self.tail = 0;
            self.head = 0;
        }

        /// Release all allocated memory.
        pub fn deinit(self: Self, gpa: Allocator) void {
            if (self.cap() > 0) gpa.free(self.buf);
        }

        /// Returns the length of the already-allocated buffer.
        pub inline fn cap(self: Self) usize {
            return self.buf.len;
        }

        /// Returns the number of elements in the deque.
        pub inline fn len(self: Self) usize {
            if (self.cap() == 0) return 0;
            return count(self.tail, self.head, self.cap());
        }

        /// Gets the pointer to the element with the given index, if any.
        /// Otherwise it returns `null`.
        pub inline fn get(self: Self, index: usize) ?*T {
            if (index >= self.len()) return null;

            const idx = self.wrap_add(self.tail, index);
            return &self.buf[idx];
        }

        /// Gets the pointer to the first element, if any.
        pub inline fn front(self: Self) ?*T {
            return self.get(0);
        }

        /// Gets the pointer to the last element, if any.
        pub inline fn back(self: Self) ?*T {
            const last_idx = std.math.sub(usize, self.len(), 1) catch return null;
            return self.get(last_idx);
        }

        /// Adds the given element to the back of the deque.
        pub inline fn push_back(self: *Self, gpa: Allocator, item: T) Allocator.Error!void {
            if (self.cap() == 0) {
                const new_cap = std.math.ceilPowerOfTwoAssert(usize, INITIAL_CAPACITY + 1);
                self.buf = try gpa.alloc(T, new_cap);
                self.head = 0;
                self.tail = 0;
            } else if (self.is_full()) {
                try self.grow(gpa);
            }

            const head = self.head;
            self.head = self.wrap_add(self.head, 1);
            self.buf[head] = item;
        }

        /// Adds the given element to the front of the deque.
        pub inline fn push_front(self: *Self, gpa: Allocator, item: T) Allocator.Error!void {
            if (self.cap() == 0) {
                const new_cap = std.math.ceilPowerOfTwoAssert(usize, INITIAL_CAPACITY + 1);
                self.buf = try gpa.alloc(T, new_cap);
                self.head = 0;
                self.tail = 0;
            } else if (self.is_full()) {
                try self.grow(gpa);
            }

            self.tail = self.wrap_sub(self.tail, 1);
            const tail = self.tail;
            self.buf[tail] = item;
        }

        /// Pops and returns the last element of the deque.
        pub inline fn pop_back(self: *Self) ?T {
            if (self.len() == 0) return null;

            self.head = self.wrap_sub(self.head, 1);
            return self.buf[self.head];
        }

        /// Pops and returns the first element of the deque.
        pub inline fn pop_front(self: *Self) ?T {
            if (self.len() == 0) return null;

            const tail = self.tail;
            self.tail = self.wrap_add(self.tail, 1);
            return self.buf[tail];
        }

        /// Adds all the elements in the given slice to the back of the deque.
        pub inline fn append_slice(self: *Self, gpa: Allocator, items: []const T) Allocator.Error!void {
            for (items) |item| try self.push_back(gpa, item);
        }

        /// Adds all the elements in the given slice to the front of the deque.
        pub inline fn prepend_slice(self: *Self, gpa: Allocator, items: []const T) Allocator.Error!void {
            if (items.len == 0) return;

            var i: usize = items.len - 1;

            while (true) : (i -= 1) {
                const item = items[i];
                try self.push_front(gpa, item);
                if (i == 0) break;
            }
        }

        /// Returns an iterator over the deque.
        /// Modifying the deque may invalidate this iterator.
        pub fn iterator(self: Self) Iterator {
            return .{
                .head = self.head,
                .tail = self.tail,
                .ring = self.buf,
            };
        }

        pub fn format(self: Self, writer: *std.io.Writer) std.io.Writer.Error!void {
            try writer.print("Deque({}){{\n    .buf = {{\n", .{T});

            var it = self.iterator();
            if (it.next()) |val| try writer.print("        {any}", .{val.*});
            while (it.next()) |val| try writer.print(",\n        {any}", .{val.*});

            try writer.print(
                \\
                \\    }},
                \\    .head = {},
                \\    .tail = {},
                \\    .len = {},
                \\}}
            , .{
                self.head,
                self.tail,
                self.len(),
            });
        }

        pub const Iterator = struct {
            head: usize,
            tail: usize,
            ring: []T,

            pub fn next(it: *Iterator) ?*T {
                if (it.head == it.tail) return null;

                const tail = it.tail;
                it.tail = wrap_index(it.tail +% 1, it.ring.len);
                return &it.ring[tail];
            }

            pub fn next_back(it: *Iterator) ?*T {
                if (it.head == it.tail) return null;

                it.head = wrap_index(it.head -% 1, it.ring.len);
                return &it.ring[it.head];
            }
        };

        /// Returns `true` if the buffer is at full capacity.
        fn is_full(self: Self) bool {
            return self.cap() - self.len() == 1;
        }

        fn grow(self: *Self, gpa: Allocator) Allocator.Error!void {
            std.debug.assert(self.is_full());
            const old_cap = self.cap();
            const new_cap = old_cap * 2;

            // Reserve additional space to accomodate more items
            self.buf = try gpa.realloc(self.buf, new_cap);

            // Update `tail` and `head` pointers accordingly
            self.handle_capacity_increase(old_cap);

            std.debug.assert(self.cap() >= new_cap);
            std.debug.assert(!self.is_full());
        }

        /// Updates `tail` and `head` values to handle the fact that we just reallocated the internal buffer.
        fn handle_capacity_increase(self: *Self, old_capacity: usize) void {
            const new_capacity = self.cap();
            if (self.tail <= self.head) {
                // (A), Nop
            } else if (self.head < old_capacity - self.tail) {
                self.copy_non_overlapping(old_capacity, 0, self.head);
                self.head += old_capacity;
                std.debug.assert(self.head > self.tail);
            } else {
                const new_tail = new_capacity - (old_capacity - self.tail);
                self.copy_non_overlapping(new_tail, self.tail, old_capacity - self.tail);
                self.tail = new_tail;
                std.debug.assert(self.head < self.tail);
            }
            std.debug.assert(self.head < self.cap());
            std.debug.assert(self.tail < self.cap());
        }

        fn copy_non_overlapping(self: *Self, dest: usize, src: usize, length: usize) void {
            std.debug.assert(dest + length <= self.cap());
            std.debug.assert(src + length <= self.cap());
            @memcpy(self.buf[dest .. dest + length], self.buf[src .. src + length]);
        }

        fn wrap_add(self: Self, idx: usize, addend: usize) usize {
            return wrap_index(idx +% addend, self.cap());
        }

        fn wrap_sub(self: Self, idx: usize, subtrahend: usize) usize {
            return wrap_index(idx -% subtrahend, self.cap());
        }
    };
}

fn count(tail: usize, head: usize, size: usize) usize {
    std.debug.assert(std.math.isPowerOfTwo(size));
    return (head -% tail) & (size - 1);
}

fn wrap_index(index: usize, size: usize) usize {
    std.debug.assert(std.math.isPowerOfTwo(size));
    return index & (size - 1);
}

test "DequeDynamic works" {
    var deque: Deque(usize).Dynamic = .empty;
    defer deque.deinit(testing.allocator);

    // empty deque
    try testing.expectEqual(@as(usize, 0), deque.len());
    try testing.expect(deque.get(0) == null);
    try testing.expect(deque.front() == null);
    try testing.expect(deque.back() == null);
    try testing.expect(deque.pop_back() == null);
    try testing.expect(deque.pop_front() == null);

    // push_back
    try deque.push_back(testing.allocator, 101);
    try testing.expectEqual(@as(usize, 1), deque.len());
    try testing.expectEqual(@as(usize, 101), deque.get(0).?.*);
    try testing.expectEqual(@as(usize, 101), deque.front().?.*);
    try testing.expectEqual(@as(usize, 101), deque.back().?.*);

    // push_front
    try deque.push_front(testing.allocator, 100);
    try testing.expectEqual(@as(usize, 2), deque.len());
    try testing.expectEqual(@as(usize, 100), deque.get(0).?.*);
    try testing.expectEqual(@as(usize, 100), deque.front().?.*);
    try testing.expectEqual(@as(usize, 101), deque.get(1).?.*);
    try testing.expectEqual(@as(usize, 101), deque.back().?.*);

    // more items
    {
        var i: usize = 99;
        while (true) : (i -= 1) {
            try deque.push_front(testing.allocator, i);
            if (i == 0) break;
        }
    }
    {
        var i: usize = 102;
        while (i < 200) : (i += 1) {
            try deque.push_back(testing.allocator, i);
        }
    }

    try testing.expectEqual(@as(usize, 200), deque.len());
    {
        var i: usize = 0;
        while (i < deque.len()) : (i += 1) {
            try testing.expectEqual(i, deque.get(i).?.*);
        }
    }
    {
        var i: usize = 0;
        var it = deque.iterator();
        while (it.next()) |val| : (i += 1) {
            try testing.expectEqual(i, val.*);
        }
        try testing.expectEqual(@as(usize, 200), i);
    }
}

test "init_capacity with too large capacity" {
    var deque: Deque(i32).Dynamic = try .init_capacity(
        testing.allocator,
        std.math.maxInt(usize),
    );
    defer deque.deinit(testing.allocator);
    try testing.expectEqual(@as(usize, 8), deque.buf.len);
}

test "append_slice and prepend_slice" {
    var deque: Deque(usize).Dynamic = .empty;
    defer deque.deinit(testing.allocator);

    try deque.prepend_slice(testing.allocator, &[_]usize{ 1, 2, 3, 4, 5, 6 });
    try deque.append_slice(testing.allocator, &[_]usize{ 7, 8, 9 });
    try deque.prepend_slice(testing.allocator, &[_]usize{0});
    try deque.append_slice(testing.allocator, &[_]usize{ 10, 11, 12, 13, 14 });

    var i: usize = 0;
    while (i <= 14) : (i += 1) {
        try testing.expectEqual(i, deque.get(i).?.*);
    }
}

test "next_back" {
    var deque: Deque(usize).Dynamic = .empty;
    defer deque.deinit(testing.allocator);

    try deque.append_slice(testing.allocator, &[_]usize{ 5, 4, 3, 2, 1, 0 });

    {
        var i: usize = 0;
        var it = deque.iterator();
        while (it.next_back()) |val| : (i += 1) {
            try testing.expectEqual(i, val.*);
        }
    }
}

test "code sample in README" {
    var deque: Deque(usize).Dynamic = .empty;
    defer deque.deinit(testing.allocator);

    try deque.push_back(testing.allocator, 1);
    try deque.push_back(testing.allocator, 2);
    try deque.push_front(testing.allocator, 0);

    std.debug.assert(deque.get(0).?.* == @as(usize, 0));
    std.debug.assert(deque.get(1).?.* == @as(usize, 1));
    std.debug.assert(deque.get(2).?.* == @as(usize, 2));
    std.debug.assert(deque.get(3) == null);

    var it = deque.iterator();
    var sum: usize = 0;
    while (it.next()) |val| {
        sum += val.*;
    }
    std.debug.assert(sum == 3);

    std.debug.assert(deque.pop_front().? == @as(usize, 0));
    std.debug.assert(deque.pop_back().? == @as(usize, 2));
}

test "DequeStatic works" {
    var deque: Deque(u8).Static(8) = .{};

    try testing.expectEqual(@as(usize, 8), deque.cap);
    try testing.expectEqual(@as(usize, 0), deque.len());
    try testing.expect(deque.is_empty());
    try testing.expect(!deque.is_full());
    try testing.expect(deque.get(0) == null);
    try testing.expect(deque.pop_front() == null);

    try deque.push_back(10);
    try testing.expectEqual(@as(usize, 1), deque.len());
    try testing.expectEqual(@as(u8, 10), deque.back().?.*);
    try testing.expectEqual(@as(u8, 10), deque.front().?.*);

    try deque.push_front(9);
    try testing.expectEqual(@as(usize, 2), deque.len());
    try testing.expectEqual(@as(u8, 9), deque.get(0).?.*);
    try testing.expectEqual(@as(u8, 10), deque.get(1).?.*);

    try testing.expectEqual(@as(u8, 10), deque.pop_back().?);
    try testing.expectEqual(@as(usize, 1), deque.len());
    try testing.expectEqual(@as(u8, 9), deque.pop_front().?);
    try testing.expectEqual(@as(usize, 0), deque.len());
    try testing.expect(deque.is_empty());
}

test "DequeStatic is_full" {
    var deque = Deque(i32).Static(4){};

    try deque.push_back(1);
    try deque.push_back(2);
    try testing.expect(!deque.is_full());

    try deque.push_back(3);
    try testing.expect(deque.is_full());
    try testing.expectEqual(@as(usize, 3), deque.len());
    try testing.expectError(error.DequeFull, deque.push_back(4));
    _ = deque.pop_front();
    try testing.expect(!deque.is_full());
}

test "DequeStatic wrapping" {
    var deque = Deque(usize).Static(4){};

    try deque.push_back(1);
    try deque.push_back(2);
    try deque.push_back(3);
    try testing.expect(deque.is_full());

    try testing.expectEqual(@as(usize, 1), deque.pop_front().?);
    try testing.expectEqual(@as(usize, 2), deque.len());

    try deque.push_back(4);
    try testing.expect(deque.is_full());
    try testing.expectEqual(@as(usize, 2), deque.get(0).?.*);
    try testing.expectEqual(@as(usize, 3), deque.get(1).?.*);
    try testing.expectEqual(@as(usize, 4), deque.get(2).?.*);
}

test "DequeStatic slice operations" {
    var deque: Deque(u16).Static(16) = .{};

    try deque.append_slice(&[_]u16{ 10, 11, 12 });
    try testing.expectEqual(@as(usize, 3), deque.len());
    try testing.expectEqual(@as(u16, 12), deque.back().?.*);

    try deque.prepend_slice(&[_]u16{ 9, 8 });
    try testing.expectEqual(@as(usize, 5), deque.len());

    try testing.expectEqual(@as(u16, 9), deque.front().?.*);
    try testing.expectEqual(@as(u16, 9), deque.get(0).?.*);
    try testing.expectEqual(@as(u16, 8), deque.get(1).?.*);
    try testing.expectEqual(@as(u16, 10), deque.get(2).?.*);

    const err = deque.append_slice(&[_]u16{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 });
    try testing.expectError(error.DequeFull, err);
}
