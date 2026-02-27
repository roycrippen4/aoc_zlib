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

    const Self = @This();

    pub inline fn format(self: @This(), writer: *Writer) !void {
        try writer.print("Day {s}", .{@tagName(self)});
    }

    fn to_url(self: Self) []const u8 {
        return switch (self) {
            .@"01" => "https://adventofcode.com/2025/day/1/input",
            .@"02" => "https://adventofcode.com/2025/day/2/input",
            .@"03" => "https://adventofcode.com/2025/day/3/input",
            .@"04" => "https://adventofcode.com/2025/day/4/input",
            .@"05" => "https://adventofcode.com/2025/day/5/input",
            .@"06" => "https://adventofcode.com/2025/day/6/input",
            .@"07" => "https://adventofcode.com/2025/day/7/input",
            .@"08" => "https://adventofcode.com/2025/day/8/input",
            .@"09" => "https://adventofcode.com/2025/day/9/input",
            .@"10" => "https://adventofcode.com/2025/day/10/input",
            .@"11" => "https://adventofcode.com/2025/day/11/input",
            .@"12" => "https://adventofcode.com/2025/day/12/input",
            .@"13" => "https://adventofcode.com/2025/day/13/input",
            .@"14" => "https://adventofcode.com/2025/day/14/input",
            .@"15" => "https://adventofcode.com/2025/day/15/input",
            .@"16" => "https://adventofcode.com/2025/day/16/input",
            .@"17" => "https://adventofcode.com/2025/day/17/input",
            .@"18" => "https://adventofcode.com/2025/day/18/input",
            .@"19" => "https://adventofcode.com/2025/day/19/input",
            .@"20" => "https://adventofcode.com/2025/day/20/input",
            .@"21" => "https://adventofcode.com/2025/day/21/input",
            .@"22" => "https://adventofcode.com/2025/day/22/input",
            .@"23" => "https://adventofcode.com/2025/day/23/input",
            .@"24" => "https://adventofcode.com/2025/day/24/input",
            .@"25" => "https://adventofcode.com/2025/day/25/input",
        };
    }

    fn to_filepath(self: Self) []const u8 {
        return switch (self) {
            .@"01" => "src/data/day01.txt",
            .@"02" => "src/data/day02.txt",
            .@"03" => "src/data/day03.txt",
            .@"04" => "src/data/day04.txt",
            .@"05" => "src/data/day05.txt",
            .@"06" => "src/data/day06.txt",
            .@"07" => "src/data/day07.txt",
            .@"08" => "src/data/day08.txt",
            .@"09" => "src/data/day09.txt",
            .@"10" => "src/data/day10.txt",
            .@"11" => "src/data/day11.txt",
            .@"12" => "src/data/day12.txt",
            .@"13" => "src/data/day13.txt",
            .@"14" => "src/data/day14.txt",
            .@"15" => "src/data/day15.txt",
            .@"16" => "src/data/day16.txt",
            .@"17" => "src/data/day17.txt",
            .@"18" => "src/data/day18.txt",
            .@"19" => "src/data/day19.txt",
            .@"20" => "src/data/day20.txt",
            .@"21" => "src/data/day21.txt",
            .@"22" => "src/data/day22.txt",
            .@"23" => "src/data/day23.txt",
            .@"24" => "src/data/day24.txt",
            .@"25" => "src/data/day25.txt",
        };
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
