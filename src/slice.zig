const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub fn SliceTuple(comptime T: type) type {
    return struct { []const T, []const T };
}

/// Checks `haystack` for `needle`.
/// Returns `true` if found, otherwise `false`;
pub inline fn contains(comptime T: type, haystack: []const T, needle: anytype) bool {
    if (@TypeOf(needle) == T or @TypeOf(needle) == comptime_int) {
        return mem.indexOfScalar(T, haystack, needle) != null;
    } else {
        const needle_slice: []const T = needle;
        return mem.indexOf(T, haystack, needle_slice) != null;
    }
}

pub inline fn split_once_scalar(comptime T: type, s: []const T, delim: T) SliceTuple(T) {
    var it = mem.splitScalar(T, s, delim);

    return .{
        it.next().?,
        it.next() orelse &[0]T{},
    };
}

pub inline fn split_once_sequence(
    comptime T: type,
    s: []const T,
    delimiters: []const T,
) SliceTuple(T) {
    @setEvalBranchQuota(100_000);

    var it = mem.splitSequence(T, trim(s), delimiters);
    return .{
        it.next().?,
        it.next() orelse &[0]T{},
    };
}

test "slice split_once_by_slice" {
    const hello, const world = split_once_sequence(u8, "hello+++world", "+++");
    try testing.expectEqualStrings("hello", hello);
    try testing.expectEqualStrings("world", world);
}

/// Splits an input slice in half at it's middle index.
/// If the slice has an odd number of digits, then `snd` will contain the extra T
pub inline fn split_evenly(comptime T: type, s: []const T) SliceTuple(T) {
    const half_len = s.len / 2;

    return .{
        s[0..half_len],
        s[half_len..],
    };
}

test "slice split_evenly" {
    const a, const b = split_evenly(u8, "123456");
    try testing.expectEqualStrings("123", a);
    try testing.expectEqualStrings("456", b);

    const x, const y = split_evenly(u8, "1234567");
    try testing.expectEqualStrings("123", x);
    try testing.expectEqualStrings("4567", y);
}

/// Split a slice at a given index.
/// The second slice in the returned tuple will contain the value at the index
/// Will return `.{ s, "" }` if the provided index is greater-than or equal-to the length of the slice.
///
/// # Example
/// ```zig
/// const std = @import("std");
///
/// const s = "hello world";
/// const first, const second = split_once_at_inclusive(u8, s, 5);
/// try std.testing.expectEqualStrings(first, "hello");
/// try std.testing.expectEqualStrings(second, " world");
/// ```
pub inline fn split_once_at_inclusive(comptime T: type, s: []const T, index: usize) SliceTuple(T) {
    if (index >= s.len) return .{ s, "" };
    return .{ s[0..index], s[index..] };
}
test "slice split_once_at_inclusive" {
    const s = "hello world";
    const s1a, const s1b = split_once_at_inclusive(u8, s, 5);
    try testing.expectEqualStrings(s1a, "hello");
    try testing.expectEqualStrings(s1b, " world");

    // way too big
    const s2a, const s2b = split_once_at_inclusive(u8, s, 15);
    try testing.expectEqualStrings(s2a, "hello world");
    try testing.expectEqualStrings(s2b, "");

    // index == s.len
    const s3a, const s3b = split_once_at_inclusive(u8, s, s.len);
    try testing.expectEqualStrings(s3a, "hello world");
    try testing.expectEqualStrings(s3b, "");

    // index == s.len - 1
    const s4a, const s4b = split_once_at_inclusive(u8, s, s.len - 1);
    try testing.expectEqualStrings(s4a, "hello worl");
    try testing.expectEqualStrings(s4b, "d");
}

/// Split a slice at a given index.
/// The second slice in the returned tuple will **not** contain the value at the index
/// Will return `.{ s, "" }` if the provided index is greater-than or equal-to the length of the slice.
///
/// # Example
/// ```zig
/// const std = @import("std");
///
/// const s = "hello world";
/// const first, const second = split_once_at_exclusive(u8, s, 5);
/// try std.testing.expectEqualStrings(first, "hello");
/// try std.testing.expectEqualStrings(second, "world");
/// ```
pub inline fn split_once_at_exclusive(comptime T: type, s: []const T, index: usize) SliceTuple(T) {
    if (index >= s.len) return .{ s, "" };
    return .{ s[0..index], s[index + 1 ..] };
}
test "slice split_once_at_exclusive" {
    const s = "hello world";
    const s1a, const s1b = split_once_at_exclusive(u8, s, 5);
    try testing.expectEqualStrings(s1a, "hello");
    try testing.expectEqualStrings(s1b, "world");

    // way too big
    const s2a, const s2b = split_once_at_exclusive(u8, s, 15);
    try testing.expectEqualStrings(s2a, "hello world");
    try testing.expectEqualStrings(s2b, "");

    const s3a, const s3b = split_once_at_exclusive(u8, s, s.len);
    try testing.expectEqualStrings(s3a, "hello world");
    try testing.expectEqualStrings(s3b, "");

    const s4a, const s4b = split_once_at_exclusive(u8, s, s.len - 1);
    try testing.expectEqualStrings(s4a, "hello worl");
    try testing.expectEqualStrings(s4b, "");

    const s5a, const s5b = split_once_at_exclusive(u8, s, s.len - 2);
    try testing.expectEqualStrings(s5a, "hello wor");
    try testing.expectEqualStrings(s5b, "d");
}

pub inline fn chunks_needed(comptime N: usize, len: usize) usize {
    comptime if (N == 0) @compileError("N must be > 0");
    return (len + N - 1) / N;
}

pub fn chunks(
    comptime T: type,
    comptime N: usize,
    s: []const T,
    out: [][]const T,
) ![]const []const T {
    comptime if (N == 0) @compileError("N must be > 0");

    const need = chunks_needed(N, s.len);
    if (out.len < need) {
        return error.BufferTooSmall;
    }

    var off: usize = 0;
    var wrote: usize = 0;
    while (off < s.len) : (off += N) {
        const end = @min(off + N, s.len);
        out[wrote] = s[off..end];
        wrote += 1;
    }
    return out[0..wrote];
}

/// Returns an iterator over the lines in a slice
pub inline fn lines(s: []const u8) mem.SplitIterator(u8, .scalar) {
    @setEvalBranchQuota(500_000);
    const trimmed = mem.trim(u8, s, "\n");
    return mem.splitScalar(u8, trimmed, '\n');
}

pub inline fn line_count(comptime s: []const u8) usize {
    var result: usize = 0;
    var it = lines(s);
    while (it.next()) |_| : (result += 1) {}
    return result;
}

/// gets the total number of bytes for the first line of a given string.
/// The newline at the end will *NOT* be included in the count.
/// Again, this will **only check the first line**
pub inline fn line_len(s: []const u8) usize {
    var it = lines(s);
    return it.peek().?.len;
}

test "slice line_len" {
    const s =
        \\foo
        \\bar
        \\baz
    ;

    try testing.expectEqual(3, line_len(s));
}

/// only use on strings!
pub inline fn trim(s: []const u8) []const u8 {
    return std.mem.trim(u8, s, &.{'\n'});
}

test "slice lines" {
    const s =
        \\
        \\foo
        \\bar
        \\baz
        \\
    ;
    var lines_it = lines(s);
    var i: usize = 0;

    while (lines_it.next()) |line| : (i += 1) {
        switch (i) {
            0 => try testing.expectEqualSlices(u8, "foo", line),
            1 => try testing.expectEqualSlices(u8, "bar", line),
            2 => try testing.expectEqualSlices(u8, "baz", line),
            else => unreachable,
        }
    }
}

test "slice contains generic" {
    try testing.expect(contains(u8, "barbazquux", "baz"));
    try testing.expect(!contains(u8, "barbazquux", "yes"));
    try testing.expect(contains(u8, "abcdefg", "a"));
    try testing.expect(contains(u8, "abcdefg", "abcdefg"));
    try testing.expect(contains(u8, "foooooo", ""));

    var h1 = [_]u8{ 'a', 'b', 'c' };
    try testing.expect(contains(u8, &h1, 'b'));
    try testing.expect(!contains(u8, &h1, 'd'));

    var h2 = [_]usize{ 1, 2, 3, 4, 5 };
    try testing.expect(contains(usize, &h2, 1));
    try testing.expect(contains(usize, &h2, 5));
    try testing.expect(!contains(usize, &h2, 6));
}
