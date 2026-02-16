const std = @import("std");
const testing = std.testing;
const Writer = std.io.Writer;

const Direction = @import("direction.zig").Intercardinal;
const abs_diff = @import("math.zig").abs_diff;

const Self = @This();

x: usize,
y: usize,

/// Point at the origin of the cartesian plane `(0, 0)`
pub const origin: Self = .{ .x = 0, .y = 0 };

/// Duplicate of `origin` constant since I'll likely forget `origin` exists
pub const default: Self = .{ .x = 0, .y = 0 };

/// Point with both components (x, y) at `std.math.maxInt(usize)`
pub const max: Self = .{
    .x = std.math.maxInt(usize),
    .y = std.math.maxInt(usize),
};

pub inline fn distance(self: Self, other: Self) usize {
    const x = std.math.pow(usize, abs_diff(usize, self.x, other.x), 2);
    const y = std.math.pow(usize, abs_diff(usize, self.y, other.y), 2);
    return std.math.sqrt(x + y);
}
test "point distance" {
    const p1: Self = .{ .x = 1, .y = 1 };
    const p2: Self = .{ .x = 4, .y = 5 };

    try testing.expectEqual(p1.distance(p2), 5);
}

/// Euclidean distance without applying the final square-root
pub inline fn distance_squared(self: Self, other: Self) usize {
    const x = std.math.pow(usize, abs_diff(usize, self.x, other.x), 2);
    const y = std.math.pow(usize, abs_diff(usize, self.y, other.y), 2);
    return x + y;
}

/// Divide two points. Returns null if division by zero would occur.
pub inline fn div(numerator: Self, denominator: Self) ?Self {
    if (denominator.x == 0 or denominator.y == 0) return null;
    const x = numerator.x / denominator.x;
    const y = numerator.y / denominator.y;
    return .{ .x = x, .y = y };
}

/// Divides numerator in-place via mutation. May cause underflow or division by 0 errors
pub inline fn mut_div(numerator: *Self, denominator: Self) void {
    numerator.x /= denominator.x;
    numerator.y /= denominator.y;
}

/// Divide two points. Assumes division by 0 will not occur.
pub inline fn unchecked_div(numerator: Self, denominator: Self) Self {
    return .{
        .x = numerator.x / denominator.x,
        .y = numerator.y / denominator.y,
    };
}

/// Divide two points. "Saturates" on division by zero (clamps to maxInt).
pub inline fn saturating_div(numerator: Self, denominator: Self) Self {
    // const max = std.math.maxInt(usize);
    const x = if (denominator.x == 0)
        std.math.maxInt(usize)
    else
        numerator.x / denominator.x;

    const y = if (denominator.y == 0)
        std.math.maxInt(usize)
    else
        numerator.y / denominator.y;

    return .{ .x = x, .y = y };
}

/// Divide two points. "Wraps" division by zero to 0 to keep behavior defined.
pub inline fn wrapping_div(numerator: Self, denominator: Self) Self {
    const x = if (denominator.x == 0) 0 else numerator.x / denominator.x;
    const y = if (denominator.y == 0) 0 else numerator.y / denominator.y;
    return .{ .x = x, .y = y };
}

/// Multiply a point by some factor. returns null if an overflow occurs
pub inline fn times(self: Self, n: usize) ?Self {
    const x = std.math.mul(usize, self.x, n) catch return null;
    const y = std.math.mul(usize, self.y, n) catch return null;
    return .{ .x = x, .y = y };
}

/// Multiply self by a factor in-place via mutation.
/// Does not check for overflow
pub inline fn mut_times(self: *Self, n: usize) void {
    self.x *= n;
    self.y *= n;
}

/// Multiply two points. Assumes operation will not overflow.
pub inline fn unchecked_times(self: Self, n: usize) Self {
    return .{
        .x = self.x * n,
        .y = self.y * n,
    };
}

/// Multiply both parts of a point by a factor.
/// Clamps to max value if an overflow occurs
pub inline fn saturating_times(self: Self, n: usize) Self {
    return .{
        .x = self.x *| n,
        .y = self.y *| n,
    };
}

/// Multiply both parts of a point by a factor.
/// Will wrap when an overflow occurs
pub inline fn wrapping_times(self: Self, n: usize) Self {
    return .{
        .x = self.x *% n,
        .y = self.y *% n,
    };
}

/// Multiply two points. returns null if an overflow occurs
pub inline fn mul(self: Self, other: Self) ?Self {
    const x = std.math.mul(usize, self.x, other.x) catch return null;
    const y = std.math.mul(usize, self.y, other.y) catch return null;
    return .{ .x = x, .y = y };
}

/// Multiply self with other by updating self in-place via mutation.
/// Does not check for overflow
pub inline fn mut_mul(self: *Self, other: Self) void {
    self.x *= other.x;
    self.y *= other.y;
}

/// Multiply two points. Assumes operation will not overflow.
pub inline fn unchecked_mul(self: Self, other: Self) Self {
    return .{
        .x = self.x * other.x,
        .y = self.y * other.y,
    };
}

/// Multiply two points. Will not overflow
pub inline fn saturating_mul(self: Self, other: Self) Self {
    const x = self.x *| other.x;
    const y = self.y *| other.y;
    return .{ .x = x, .y = y };
}

/// Multiply two points. Will wrap when an overflow occurs
pub inline fn wrapping_mul(self: Self, other: Self) Self {
    return .{
        .x = self.x *% other.x,
        .y = self.y *% other.y,
    };
}

/// Sum two points. Returns null if an overflow occurs
pub inline fn add(self: Self, other: Self) ?Self {
    const x = std.math.add(usize, self.x, other.x) catch return null;
    const y = std.math.add(usize, self.y, other.y) catch return null;
    return .{ .x = x, .y = y };
}

/// Sum two points by mutating self.
/// Does not check for overflow
pub inline fn mut_add(self: *Self, other: Self) void {
    self.x += other.x;
    self.y += other.y;
}

/// Sum two points. Does not check for overflow.
pub inline fn unchecked_add(self: Self, other: Self) Self {
    return .{
        .x = self.x + other.x,
        .y = self.y + other.y,
    };
}

/// Subtract two points. Wraps to maxInt if an underflow occurs
pub inline fn wrapping_add(self: Self, other: Self) Self {
    return .{
        .x = self.x +% other.x,
        .y = self.y +% other.y,
    };
}

pub inline fn saturating_add(self: Self, other: Self) Self {
    return .{
        .x = self.x +| other.x,
        .y = self.y +| other.y,
    };
}

/// Subtract two points. Returns null if an underflow occurs
pub inline fn sub(self: Self, other: Self) ?Self {
    const x = std.math.sub(usize, self.x, other.x) catch return null;
    const y = std.math.sub(usize, self.y, other.y) catch return null;
    return .{ .x = x, .y = y };
}

/// Subtract two points by mutating self.
/// Does not check for division by 0 or overflows
pub inline fn mut_sub(self: *Self, other: Self) void {
    self.x -= other.x;
    self.y -= other.y;
}

/// Subtract two points. Assumes underflows will not occur
pub inline fn unchecked_sub(self: Self, other: Self) Self {
    return .{
        .x = self.x - other.x,
        .y = self.y - other.y,
    };
}

/// Subtract two points. Wraps to maxInt if an underflow occurs
pub inline fn wrapping_sub(self: Self, other: Self) Self {
    return .{
        .x = self.x -% other.x,
        .y = self.y -% other.y,
    };
}

pub inline fn saturating_sub(self: Self, other: Self) Self {
    return .{
        .x = self.x -| other.x,
        .y = self.y -| other.y,
    };
}

pub inline fn eql(self: Self, other: Self) bool {
    return self.x == other.x and self.y == other.y;
}
test "point eql" {
    const p1: Self = .{ .x = 10, .y = 12 };
    const p2: Self = .{ .x = 0, .y = 1 };
    const p3: Self = .{ .x = 0, .y = 1 };

    try testing.expect(p2.eql(p3));
    try testing.expect(!p1.eql(p3));
}

pub fn unit_step(self: Self, d: Direction) Self {
    const x = self.x;
    const y = self.y;

    return switch (d) {
        .north => .{ .x = x, .y = y -% 1 },
        .south => .{ .x = x, .y = y +% 1 },
        .west => .{ .x = x -% 1, .y = y },
        .east => .{ .x = x +% 1, .y = y },
        .northeast => .{ .x = x +% 1, .y = y -% 1 },
        .northwest => .{ .x = x -% 1, .y = y -% 1 },
        .southeast => .{ .x = x +% 1, .y = y +% 1 },
        .southwest => .{ .x = x -% 1, .y = y +% 1 },
    };
}

pub fn unit_step_opt(self: Self, d: Direction) ?Self {
    const x = self.x;
    const y = self.y;
    const usize_max = std.math.maxInt(usize);

    const bad_n = y == 0;
    const bad_s = y == usize_max;
    const bad_w = x == 0;
    const bad_e = x == usize_max;

    // zig fmt: off
        return switch (d) {
            .north     => return if (bad_n         ) null else .{ .x = x    , .y = y - 1 },
            .south     => return if (bad_s         ) null else .{ .x = x    , .y = y + 1 },
            .west      => return if (bad_w         ) null else .{ .x = x - 1, .y = y     },
            .east      => return if (bad_e         ) null else .{ .x = x + 1, .y = y     },
            .northeast => return if (bad_e or bad_n) null else .{ .x = x + 1, .y = y - 1 },
            .northwest => return if (bad_w or bad_n) null else .{ .x = x - 1, .y = y - 1 },
            .southeast => return if (bad_e or bad_s) null else .{ .x = x + 1, .y = y + 1 },
            .southwest => return if (bad_w or bad_s) null else .{ .x = x - 1, .y = y + 1 },
        };
        // zig fmt: on
}

/// Returns a new point shifted one unit north
pub inline fn north(self: Self) Self {
    return self.unit_step(Direction.north);
}

/// Returns a new point shifted one unit south
pub inline fn south(self: Self) Self {
    return self.unit_step(Direction.south);
}

/// Returns a new point shifted one unit east
pub inline fn east(self: Self) Self {
    return self.unit_step(Direction.east);
}

/// Returns a new point shifted one unit west
pub inline fn west(self: Self) Self {
    return self.unit_step(Direction.west);
}

/// Returns a new point shifted one unit south-east
pub inline fn southeast(self: Self) Self {
    return self.unit_step(Direction.southeast);
}

/// Returns a new point shifted one unit south-west
pub inline fn southwest(self: Self) Self {
    return self.unit_step(Direction.southwest);
}

/// Returns a new point shifted one unit north-east
pub inline fn northeast(self: Self) Self {
    return self.unit_step(Direction.northeast);
}

/// Returns a new point shifted one unit north-west
pub inline fn northwest(self: Self) Self {
    return self.unit_step(Direction.northwest);
}

/// Optionally returns a new point shifted one unit north
pub inline fn north_opt(self: Self) ?Self {
    return self.unit_step_opt(Direction.north);
}

/// Optionally returns a new point shifted one unit south
pub inline fn south_opt(self: Self) ?Self {
    return self.unit_step_opt(Direction.south);
}

/// Optionally returns a new point shifted one unit east
pub inline fn east_opt(self: Self) ?Self {
    return self.unit_step_opt(Direction.east);
}

/// Optionally returns a new point shifted one unit west
pub inline fn west_opt(self: Self) ?Self {
    return self.unit_step_opt(Direction.west);
}

/// Optionally returns a new point shifted one unit south-east
pub inline fn southeast_opt(self: Self) ?Self {
    return self.unit_step_opt(Direction.southeast);
}

/// Optionally returns a new point shifted one unit south-west
pub inline fn southwest_opt(self: Self) ?Self {
    return self.unit_step_opt(Direction.southwest);
}

/// Optionally returns a new point shifted one unit north-east
pub inline fn northeast_opt(self: Self) ?Self {
    return self.unit_step_opt(Direction.northeast);
}

/// Optionally returns a new point shifted one unit north-west
pub inline fn northwest_opt(self: Self) ?Self {
    return self.unit_step_opt(Direction.northwest);
}

fn unit_step_mut(self: *Self, d: Direction) void {
    switch (d) {
        Direction.north => self.y = self.y - 1,
        Direction.south => self.y = self.y + 1,
        Direction.west => self.x = self.x - 1,
        Direction.east => self.x = self.x + 1,
        Direction.northeast => {
            self.x = self.x + 1;
            self.y = self.y - 1;
        },
        Direction.northwest => {
            self.x = self.x - 1;
            self.y = self.y - 1;
        },
        Direction.southeast => {
            self.x = self.x + 1;
            self.y = self.y + 1;
        },
        Direction.southwest => {
            self.x = self.x - 1;
            self.y = self.y + 1;
        },
    }
}

/// Mutates this point to move one unit north
pub inline fn north_mut(self: *Self) void {
    return self.unit_step_mut(Direction.north);
}

/// Mutates this point to move one unit south
pub inline fn south_mut(self: *Self) void {
    return self.unit_step_mut(Direction.south);
}

/// Mutates this point to move one unit east
pub inline fn east_mut(self: *Self) void {
    return self.unit_step_mut(Direction.east);
}

/// Mutates this point to move one unit west
pub inline fn west_mut(self: *Self) void {
    return self.unit_step_mut(Direction.west);
}

/// Mutates this point to move one unit south-east
pub inline fn southeast_mut(self: *Self) void {
    return self.unit_step_mut(Direction.southeast);
}

/// Mutates this point to move one unit south-west
pub inline fn southwest_mut(self: *Self) void {
    return self.unit_step_mut(Direction.southwest);
}

/// Mutates this point to move one unit north-east
pub inline fn northeast_mut(self: *Self) void {
    return self.unit_step_mut(Direction.northeast);
}

/// Mutates this point to move one unit north-west
pub inline fn northwest_mut(self: *Self) void {
    return self.unit_step_mut(Direction.northwest);
}

/// Get the coordinates of all orthoganal neighbors from a given point `p`.
///
/// Order of the Array starts at `Direction.north`, rotates clockwise, and ends with
/// `Direction.west`.
pub inline fn nbor4(self: Self) [4]Self {
    return .{
        self.north(),
        self.east(),
        self.south(),
        self.west(),
    };
}

/// Get the coordinates of all orthoganal neighbors from a given point `p`.
///
/// Order of the Array starts at `Direction.north`, rotates clockwise, and ends with
/// `Direction.west`.
pub inline fn nbor4_opt(self: Self) [4]?Self {
    return .{
        self.north_opt(),
        self.east_opt(),
        self.south_opt(),
        self.west_opt(),
    };
}

/// Get the coordinates of the eight surrounding neighbors (cardinal and intercardinal directions)
/// from a given point `p`, often referred to as the [8-wind compass rose](https://en.wikipedia.org/wiki/Selfs_of_the_compass#8-wind_compass_rose).
///
/// The order of the array starts at `Direction.north` and rotates clockwise.
pub inline fn nbor8(self: Self) [8]Self {
    return .{
        self.north(),
        self.northeast(),
        self.east(),
        self.southeast(),
        self.south(),
        self.southwest(),
        self.west(),
        self.northwest(),
    };
}

/// Get the coordinates of the eight surrounding neighbors (cardinal and intercardinal directions)
/// from a given point `p`, often referred to as the [8-wind compass rose](https://en.wikipedia.org/wiki/Selfs_of_the_compass#8-wind_compass_rose).
///
/// The order of the array starts at `Direction.north` and rotates clockwise.
/// If the point overflows or underflows it will be `null`
pub inline fn nbor8_opt(self: Self) [8]?Self {
    return .{
        self.north_opt(),
        self.northeast_opt(),
        self.east_opt(),
        self.southeast_opt(),
        self.south_opt(),
        self.southwest_opt(),
        self.west_opt(),
        self.northwest_opt(),
    };
}

/// Convert this point into a string
pub inline fn to_string(self: Self, buf: []u8) ![]const u8 {
    return try std.fmt.bufPrint(buf, "({d}, {d})", .{ self.x, self.y });
}
test "point to_string" {
    const p: Self = .{ .x = 123, .y = 456 };
    var buf: [64]u8 = undefined;
    const s = try p.to_string(&buf);
    try testing.expectEqualStrings("(123, 456)", s);
}

pub inline fn format(self: Self, writer: *Writer) Writer.Error!void {
    try writer.print("Point{{ .x = {d}, .y = {d} }}", .{ self.x, self.y });
}

/// Checks if the point is inside grid boundaries
pub inline fn inside(self: Self, width: usize, height: usize) bool {
    return self.x < width and self.y < height;
}

pub inline fn from_idx(i: usize, width: usize) Self {
    return .{
        .x = i % width,
        .y = i / width,
    };
}

test "point saturating_div clamps on div-by-zero" {
    const p: Self = .{ .x = 7, .y = 9 };
    const z: Self = .{ .x = 0, .y = 1 }; // x=0 triggers clamp on x only

    const out = Self.saturating_div(p, z);
    try testing.expectEqual(out.x, std.math.maxInt(usize));
    try testing.expectEqual(out.y, 9 / 1);
}

test "point wrapping_div maps div-by-zero to 0" {
    const p: Self = .{ .x = 7, .y = 9 };
    const z: Self = .{ .x = 0, .y = 0 };

    const out = Self.wrapping_div(p, z);
    try testing.expectEqual(out.x, 0);
    try testing.expectEqual(out.y, 0);
}

test "point arithmetic" {
    const p1: Self = .{ .x = 10, .y = 20 };
    const p2: Self = .{ .x = 2, .y = 5 };

    // Test addition
    const p_add = p1.add(p2).?;
    try testing.expectEqual(p_add.x, 12);
    try testing.expectEqual(p_add.y, 25);

    // Test subtraction (unwrap the optional)
    const p_sub = p1.sub(p2).?;
    try testing.expectEqual(p_sub.x, 8);
    try testing.expectEqual(p_sub.y, 15);

    // Test multiplication
    const p_mul = p1.saturating_mul(p2);
    try testing.expectEqual(p_mul.x, 20);
    try testing.expectEqual(p_mul.y, 100);

    // Test division (new static-style signature)
    const p_div = Self.div(p1, p2).?;
    try testing.expectEqual(p_div.x, 5);
    try testing.expectEqual(p_div.y, 4);
}

test "point mut_* arithmetic" {
    var p: Self = .{ .x = 10, .y = 20 };

    p.mut_add(.{ .x = 2, .y = 3 });
    try testing.expectEqual(Self{ .x = 12, .y = 23 }, p);

    p.mut_sub(.{ .x = 1, .y = 3 });
    try testing.expectEqual(Self{ .x = 11, .y = 20 }, p);

    p.mut_mul(.{ .x = 2, .y = 5 });
    try testing.expectEqual(Self{ .x = 22, .y = 100 }, p);

    p.mut_div(.{ .x = 11, .y = 20 });
    try testing.expectEqual(Self{ .x = 2, .y = 5 }, p);
}

test "point immutable movement" {
    const p: Self = .{ .x = 5, .y = 5 };
    try testing.expectEqual(Self{ .x = 5, .y = 4 }, p.north());
    try testing.expectEqual(Self{ .x = 5, .y = 6 }, p.south());
    try testing.expectEqual(Self{ .x = 6, .y = 5 }, p.east());
    try testing.expectEqual(Self{ .x = 4, .y = 5 }, p.west());
    try testing.expectEqual(Self{ .x = 6, .y = 4 }, p.northeast());
    try testing.expectEqual(Self{ .x = 4, .y = 4 }, p.northwest());
    try testing.expectEqual(Self{ .x = 6, .y = 6 }, p.southeast());
    try testing.expectEqual(Self{ .x = 4, .y = 6 }, p.southwest());
    try testing.expectEqual(p.x, 5);
    try testing.expectEqual(p.y, 5);
}

test "point mutable movement" {
    var p: Self = .{ .x = 10, .y = 10 };

    p.north_mut();
    try testing.expectEqual(Self{ .x = 10, .y = 9 }, p);

    p.east_mut();
    try testing.expectEqual(Self{ .x = 11, .y = 9 }, p);

    p.south_mut();
    try testing.expectEqual(Self{ .x = 11, .y = 10 }, p);

    p.west_mut();
    try testing.expectEqual(Self{ .x = 10, .y = 10 }, p);
}

test "point neighbor generation" {
    const p: Self = .{ .x = 3, .y = 3 };
    const n4 = p.nbor4();
    try testing.expectEqualSlices(Self, &.{
        .{ .x = 3, .y = 2 },
        .{ .x = 4, .y = 3 },
        .{ .x = 3, .y = 4 },
        .{ .x = 2, .y = 3 },
    }, &n4);
}
test "point nbor8" {
    const p: Self = .{ .x = 3, .y = 3 };
    const n8 = p.nbor8();
    try testing.expectEqualSlices(Self, &.{
        .{ .x = 3, .y = 2 },
        .{ .x = 4, .y = 2 },
        .{ .x = 4, .y = 3 },
        .{ .x = 4, .y = 4 },
        .{ .x = 3, .y = 4 },
        .{ .x = 2, .y = 4 },
        .{ .x = 2, .y = 3 },
        .{ .x = 2, .y = 2 },
    }, &n8);
}

test "point nbor4_opt" {
    const n4 = origin.nbor4_opt();
    const expected_n4: [4]?Self = .{
        null,
        .{ .x = 1, .y = 0 },
        .{ .x = 0, .y = 1 },
        null,
    };
    try testing.expectEqualSlices(?Self, &expected_n4, &n4);
}

test "point nbor8_opt" {
    const n8 = origin.nbor8_opt();
    const expected_n8: [8]?Self = .{
        null,
        null,
        .{ .x = 1, .y = 0 },
        .{ .x = 1, .y = 1 },
        .{ .x = 0, .y = 1 },
        null,
        null,
        null,
    };
    try testing.expectEqualSlices(?Self, &expected_n8, &n8);
}
