const std = @import("std");
const Allocator = std.mem.Allocator;
const Writer = std.io.Writer;

pub const char = @import("char.zig");
pub const Deque = @import("deque.zig").Deque;
pub const direction = @import("direction.zig");
pub const Grid = @import("grid.zig").Grid;
pub const math = @import("math.zig");
pub const Point = @import("point.zig");
pub const slice = @import("slice.zig");
pub const Stack = @import("stack.zig").Stack;
pub const time = @import("time.zig");

/// An enum representing days for Advent of Code problems (1-25).
/// Each variant corresponds to a day number in the challenge.
pub const Day = enum {
    @"01",
    @"02",
    @"03",
    @"04",
    @"05",
    @"06",
    @"07",
    @"08",
    @"09",
    @"10",
    @"11",
    @"12",
    @"13",
    @"14",
    @"15",
    @"16",
    @"17",
    @"18",
    @"19",
    @"20",
    @"21",
    @"22",
    @"23",
    @"24",
    @"25",

    pub inline fn format(self: @This(), writer: *Writer) !void {
        try writer.print("Day {s}", .{@tagName(self)});
    }
};

pub const Part = enum {
    one,
    two,

    pub inline fn format(self: Part, writer: *Writer) !void {
        try writer.print("Part {s}", .{@tagName(self)});
    }
};

pub const Solver = struct {
    f: fn (Allocator) anyerror!usize,
    expected: usize,
};

pub const Solution = struct {
    p1: Solver,
    p2: Solver,
    day: Day,

    pub fn solve(self: @This(), allocator: Allocator) !u64 {
        const p1_time = try validate(allocator, self.p1.f, self.p1.expected, self.day, .one);
        const p2_time = try validate(allocator, self.p2.f, self.p2.expected, self.day, .two);
        return p1_time + p2_time;
    }
};

pub fn validate(
    allocator: Allocator,
    f: fn (Allocator) anyerror!usize,
    expected: usize,
    d: Day,
    p: Part,
) !u64 {
    const start: std.time.Instant = try .now();
    const result = try f(allocator);
    const end: std.time.Instant = try .now();
    const elapsed = end.since(start);

    if (result != expected) {
        std.debug.print(
            \\===========================
            \\  Failed to solve!
            \\      Expected: {d}
            \\      Found   : {d}
            \\===========================
            \\
        , .{
            expected,
            result,
        });
        @panic("shit");
    }

    var buf: [64]u8 = undefined;
    const time_str = try time.color(elapsed, &buf);
    std.debug.print("{f} {f} solved in {s}\n", .{ d, p, time_str });
    return elapsed;
}

test {
    @import("std").testing.refAllDeclsRecursive(@This());
}
