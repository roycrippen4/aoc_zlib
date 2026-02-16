const std = @import("std");

/// Primary + Secondary compass directions
pub const Intercardinal = enum {
    north,
    northwest,
    west,
    southwest,
    south,
    southeast,
    east,
    northeast,
    const Self = @This();

    /// Converts the direction into a string
    pub fn to_string(self: Self) []const u8 {
        return switch (self) {
            .north => "north",
            .south => "south",
            .east => "east",
            .west => "west",
            .northeast => "northeast",
            .northwest => "northwest",
            .southeast => "southeast",
            .southwest => "southwest",
        };
    }

    /// Debug print the direction with a trailing newline
    pub fn display(self: Self) !void {
        std.debug.print("{s}\n", .{self.to_string()});
    }
};

/// Primary compass directions
pub const Cardinal = enum {
    north,
    south,
    east,
    west,
    const Self = @This();

    /// Converts the direction into a string
    pub fn to_string(self: Self) []const u8 {
        return switch (self) {
            .north => "^",
            .south => "v",
            .east => "<",
            .west => ">",
        };
    }

    /// Debug print the direction with a trailing newline
    pub fn display(self: Self) !void {
        std.debug.print("{s}\n", .{self.to_string()});
    }
};

/// Same as `Cardinal`, but with different labels, different ordinal values, and a different order.
pub const Orthogonal = enum {
    up,
    right,
    down,
    left,
    const Self = @This();

    /// Converts the direction into a string
    pub fn to_string(self: Self) []const u8 {
        return switch (self) {
            .up => "^",
            .down => "v",
            .left => "<",
            .right => ">",
        };
    }

    /// Debug print the direction with a trailing newline
    pub fn display(self: Self) !void {
        std.debug.print("{s}\n", .{self.to_string()});
    }
};

test "direction Intercardinal.to_string" {
    try std.testing.expectEqualStrings("north", Intercardinal.north.to_string());
    try std.testing.expectEqualStrings("south", Intercardinal.south.to_string());
    try std.testing.expectEqualStrings("east", Intercardinal.east.to_string());
    try std.testing.expectEqualStrings("west", Intercardinal.west.to_string());
    try std.testing.expectEqualStrings("northeast", Intercardinal.northeast.to_string());
    try std.testing.expectEqualStrings("northwest", Intercardinal.northwest.to_string());
    try std.testing.expectEqualStrings("southeast", Intercardinal.southeast.to_string());
    try std.testing.expectEqualStrings("southwest", Intercardinal.southwest.to_string());
}
