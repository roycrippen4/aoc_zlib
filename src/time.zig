const std = @import("std");
const bprint = std.fmt.bufPrint;

pub const Unit = enum {
    secs,
    ms_s,
    ms_m,
    ms_f,
    @"µs",
    nanos,

    pub fn from_ns(ns: u64) Unit {
        const time = as_secs(ns);
        if (time > 1.0) return .secs;
        if (time > 0.1) return .ms_s;
        if (time > 0.01) return .ms_m;
        if (time > 0.001) return .ms_f;
        if (time > 0.000001) return .@"µs";

        return .nanos;
    }
};

fn as_secs(ns: u64) f64 {
    const ns_f: f64 = @floatFromInt(ns);
    const ns_per_s_f: f64 = @floatFromInt(std.time.ns_per_s);
    return ns_f / ns_per_s_f;
}

fn as_millis(ns: u64) f64 {
    const ns_f: f64 = @floatFromInt(ns);
    const ns_per_ms_f: f64 = @floatFromInt(std.time.ns_per_ms);
    return ns_f / ns_per_ms_f;
}

fn as_micros(ns: u64) f64 {
    const ns_f: f64 = @floatFromInt(ns);
    const ns_per_us_f: f64 = @floatFromInt(std.time.ns_per_us);
    return ns_f / ns_per_us_f;
}

/// Convenience wrapper around `std.time.Instant`
pub const Stopwatch = struct {
    _start: ?std.time.Instant = null,
    label: ?[]const u8 = null,

    const Self = @This();

    pub fn start(self: Self) Self {
        return .{
            ._start = std.time.Instant.now() catch unreachable,
            .label = self.label,
        };
    }

    pub fn with_label(self: Self, label: []const u8) Self {
        return .{
            ._start = self._start,
            .label = label,
        };
    }

    pub fn stop(self: *const Self) void {
        var buf: [64]u8 = undefined;

        const now = std.time.Instant.now() catch unreachable;
        const elapsed = now.since(self._start.?);
        const timestr = color(elapsed, &buf) catch unreachable;

        if (self.label) |label| {
            std.debug.print("[{s}]: Time taken: {s}\n", .{ label, timestr });
        } else {
            std.debug.print("Time taken: {s}\n", .{timestr});
        }
    }
}{
    ._start = null,
    .label = null,
};

pub fn color(ns: u64, buf: []u8) ![]u8 {
    // zig fmt: off
    return try switch (Unit.from_ns(ns)) {
        .secs  => bprint(buf, "\x1b[38;2;255;0;0m{d:.3}s\x1b[0m"   , .{as_secs(ns)}),
        .ms_s  => bprint(buf, "\x1b[38;2;255;82;0m{d:.3}ms\x1b[0m" , .{as_millis(ns)}),
        .ms_m  => bprint(buf, "\x1b[38;2;255;165;0m{d:.3}ms\x1b[0m", .{as_millis(ns)}),
        .ms_f  => bprint(buf, "\x1b[38;2;127;210;0m{d:.3}ms\x1b[0m", .{as_millis(ns)}),
        .@"µs" => bprint(buf, "\x1b[38;2;0;255;0m{d:.3}µs\x1b[0m"  , .{as_micros(ns)}),
        .nanos => bprint(buf, "\x1b[38;2;0;255;0m{d:.3}ns\x1b[0m"  , .{ns}),
    };
    // zig fmt: on
}

fn rgb(r: u8, g: u8, b: u8, s: []const u8, buf: []u8) ![]u8 {
    return try bprint(
        &buf,
        "\x1b[38;2;{d};{d};{d}m{s}\x1b[0m",
        .{ r, g, b, s },
    );
}
