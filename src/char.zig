const std = @import("std");
const testing = std.testing;

pub const MIN: u8 = 0;
pub const MAX: u8 = std.math.maxInt(u8);

/// If the bit selected by this mask is set, ascii is lower case.
const ASCII_CASE_MASK: u8 = 0b0010_0000;

/// Assumes char is ascii
inline fn change_case_unchecked(c: u8) u8 {
    return c ^ ASCII_CASE_MASK;
}

/// Checks if the value is an ASCII lowercase character:
/// U+0061 'a' ..= U+007A 'z'.
pub inline fn is_lowercase(c: u8) bool {
    return switch (c) {
        'a'...'z' => true,
        else => false,
    };
}
test "char is_lowercase" {
    const uppercase_a = 'A';
    const uppercase_g = 'G';
    const a = 'a';
    const g = 'g';
    const zero = '0';
    const percent = '%';
    const space = ' ';
    const lf = '\n';
    const esc = '\x1b';

    try std.testing.expect(!is_lowercase(uppercase_a));
    try std.testing.expect(!is_lowercase(uppercase_g));
    try std.testing.expect(is_lowercase(a));
    try std.testing.expect(is_lowercase(g));
    try std.testing.expect(!is_lowercase(zero));
    try std.testing.expect(!is_lowercase(percent));
    try std.testing.expect(!is_lowercase(space));
    try std.testing.expect(!is_lowercase(lf));
    try std.testing.expect(!is_lowercase(esc));
}

/// Checks if the value is an ASCII lowercase character:
/// U+0061 'a' ..= U+007A 'z'.
pub inline fn is_uppercase(c: u8) bool {
    return switch (c) {
        'A'...'Z' => true,
        else => false,
    };
}
test "char is_uppercase" {
    const uppercase_a = 'A';
    const uppercase_g = 'G';
    const a = 'a';
    const g = 'g';
    const zero = '0';
    const percent = '%';
    const space = ' ';
    const lf = '\n';
    const esc = '\x1b';

    try testing.expect(is_uppercase(uppercase_a));
    try testing.expect(is_uppercase(uppercase_g));
    try testing.expect(!is_uppercase(a));
    try testing.expect(!is_uppercase(g));
    try testing.expect(!is_uppercase(zero));
    try testing.expect(!is_uppercase(percent));
    try testing.expect(!is_uppercase(space));
    try testing.expect(!is_uppercase(lf));
    try testing.expect(!is_uppercase(esc));
}

/// Checks if the value is an ASCII control character:
/// U+0000 NUL ..= U+001F UNIT SEPARATOR, or U+007F DELETE.
/// Note that most ASCII whitespace characters are control
/// characters, but SPACE is not.
pub inline fn is_control(c: u8) bool {
    return switch (c) {
        0...'\x1F' => true,
        '\x7F' => true,
        else => false,
    };
}
test "char is_control" {
    const uppercase_a = 'A';
    const uppercase_g = 'G';
    const a = 'a';
    const g = 'g';
    const zero = '0';
    const percent = '%';
    const space = ' ';
    const lf = '\n';
    const esc = '\x1b';

    try testing.expect(!is_control(uppercase_a));
    try testing.expect(!is_control(uppercase_g));
    try testing.expect(!is_control(a));
    try testing.expect(!is_control(g));
    try testing.expect(!is_control(zero));
    try testing.expect(!is_control(percent));
    try testing.expect(!is_control(space));
    try testing.expect(is_control(lf));
    try testing.expect(is_control(esc));
}

pub fn is_numeric(c: u8) bool {
    return switch (c) {
        '0'...'9' => true,
        else => false,
    };
}
test "char is_numeric" {
    try testing.expect(is_numeric('7'));
    try testing.expect(!is_numeric('a'));
}

pub fn is_alphabetic(c: u8) bool {
    return switch (c) {
        'a'...'z' => true,
        'A'...'Z' => true,
        else => false,
    };
}
test "char is_alphabetic" {
    try testing.expect(is_alphabetic('a'));
    try testing.expect(!is_alphabetic('3'));
}

pub fn is_alphanumeric(c: u8) bool {
    return is_numeric(c) or is_alphabetic(c);
}
test "char is_alphanumeric" {
    try testing.expect(is_numeric('7'));
    try testing.expect(!is_numeric('a'));
}

/// Checks if the value is within the ASCII range.
pub inline fn is_ascii(c: u8) bool {
    return c <= 0x7F;
}

/// Makes a copy of the value in its ASCII lower case equivalent.
///
/// ASCII letters 'A' to 'Z' are mapped to 'a' to 'z',
/// but non-ASCII letters are unchanged.
///
/// To lowercase the value in-place, use [`make_lowercase()`].
pub fn to_lowercase(c: u8) u8 {
    return if (is_uppercase(c))
        change_case_unchecked(c)
    else
        c;
}
test "char to_lowercase" {
    try testing.expectEqual(to_lowercase('A'), 'a');
    try testing.expectEqual(to_lowercase('a'), 'a');
}

/// Converts this type to its ASCII lower case equivalent in-place.
///
/// ASCII letters 'A' to 'Z' are mapped to 'a' to 'z',
/// but non-ASCII letters are unchanged.
///
/// To return a new lowercased value without modifying the existing one, use
/// [`to_lowercase()`].
pub inline fn make_lowercase(c: *u8) void {
    c.* = to_lowercase(c.*);
}
test "char make_lowercase" {
    var ascii: u8 = 'A';
    make_lowercase(&ascii);
    try testing.expectEqual('a', ascii);
}

/// Makes a copy of the value in its ASCII upper case equivalent.
///
/// ASCII letters 'a' to 'z' are mapped to 'A' to 'Z',
/// but non-ASCII letters are unchanged.
///
/// To uppercase the value in-place, use [`make_ascii_uppercase()`].
pub inline fn to_uppercase(c: u8) u8 {
    return if (is_lowercase(c))
        change_case_unchecked(c)
    else
        c;
}
test "char to_uppercase" {
    try testing.expectEqual('A', to_uppercase('a'));
}
/// Converts this type to its ASCII lower case equivalent in-place.
///
/// ASCII letters 'A' to 'Z' are mapped to 'a' to 'z',
/// but non-ASCII letters are unchanged.
///
/// To return a new lowercased value without modifying the existing one, use
/// [`to_lowercase()`].
pub inline fn make_uppercase(c: *u8) void {
    c.* = to_uppercase(c.*);
}
test "char make_uppercase" {
    var ascii: u8 = 'A';
    make_uppercase(&ascii);
    try testing.expectEqual('A', ascii);

    ascii = 'a';
    make_uppercase(&ascii);
    try testing.expectEqual('A', ascii);
}

/// Checks if the value is an ASCII hexadecimal digit:
///
/// - U+0030 '0' ..= U+0039 '9', or
/// - U+0041 'A' ..= U+0046 'F', or
/// - U+0061 'a' ..= U+0066 'f'.
pub inline fn is_hexdigit(c: u8) bool {
    return switch (c) {
        '0'...'9' => true,
        'A'...'F' => true,
        'a'...'f' => true,
        else => false,
    };
}
test "char is_hexdigit" {
    const uppercase_a = 'A';
    const uppercase_g = 'G';
    const a = 'a';
    const g = 'g';
    const zero = '0';
    const percent = '%';
    const space = ' ';
    const lf = '\n';
    const esc = '\x1b';

    try testing.expect(is_hexdigit(uppercase_a));
    try testing.expect(!is_hexdigit(uppercase_g));
    try testing.expect(is_hexdigit(a));
    try testing.expect(!is_hexdigit(g));
    try testing.expect(is_hexdigit(zero));
    try testing.expect(!is_hexdigit(percent));
    try testing.expect(!is_hexdigit(space));
    try testing.expect(!is_hexdigit(lf));
    try testing.expect(!is_hexdigit(esc));
}

/// Checks if the value is an ASCII octal digit:
/// U+0030 '0' ..= U+0037 '7'.
pub inline fn is_octdigit(c: u8) bool {
    return switch (c) {
        '0'...'7' => true,
        else => false,
    };
}
test "char is_octdigit" {
    const uppercase_a = 'A';
    const a = 'a';
    const zero = '0';
    const seven = '7';
    const nine = '9';
    const percent = '%';
    const lf = '\n';

    try testing.expect(!is_octdigit(uppercase_a));
    try testing.expect(!is_octdigit(a));
    try testing.expect(is_octdigit(zero));
    try testing.expect(is_octdigit(seven));
    try testing.expect(!is_octdigit(nine));
    try testing.expect(!is_octdigit(percent));
    try testing.expect(!is_octdigit(lf));
}

/// Checks if the value is an ASCII punctuation character:
///
/// - U+0021 ..= U+002F `! " # $ % & ' ( ) * + , - . /`, or
/// - U+003A ..= U+0040 `: ; < = > ? @`, or
/// - U+005B ..= U+0060 ``[ \ ] ^ _ ` ``, or
/// - U+007B ..= U+007E `{ | } ~`
pub inline fn is_punctuation(c: u8) bool {
    return switch (c) {
        '!'...'/' => true,
        ':'...'@' => true,
        '['...'`' => true,
        '{'...'~' => true,
        else => false,
    };
}
test "char is_punctuation" {
    const uppercase_a = 'A';
    const uppercase_g = 'G';
    const a = 'a';
    const g = 'g';
    const zero = '0';
    const percent = '%';
    const space = ' ';
    const lf = '\n';
    const esc = '\x1b';

    try testing.expect(!is_punctuation(uppercase_a));
    try testing.expect(!is_punctuation(uppercase_g));
    try testing.expect(!is_punctuation(a));
    try testing.expect(!is_punctuation(g));
    try testing.expect(!is_punctuation(zero));
    try testing.expect(is_punctuation(percent));
    try testing.expect(!is_punctuation(space));
    try testing.expect(!is_punctuation(lf));
    try testing.expect(!is_punctuation(esc));
}

/// Checks if the value is an ASCII graphic character:
/// U+0021 '!' ..= U+007E '~'.
pub inline fn is_graphic(c: u8) bool {
    return switch (c) {
        '!'...'~' => true,
        else => false,
    };
}
test "char is_graphic" {
    const uppercase_a = 'A';
    const uppercase_g = 'G';
    const a = 'a';
    const g = 'g';
    const zero = '0';
    const percent = '%';
    const space = ' ';
    const lf = '\n';
    const esc = '\x1b';

    try testing.expect(is_graphic(uppercase_a));
    try testing.expect(is_graphic(uppercase_g));
    try testing.expect(is_graphic(a));
    try testing.expect(is_graphic(g));
    try testing.expect(is_graphic(zero));
    try testing.expect(is_graphic(percent));
    try testing.expect(!is_graphic(space));
    try testing.expect(!is_graphic(lf));
    try testing.expect(!is_graphic(esc));
}

/// Checks if the value is an ASCII whitespace character:
/// U+0020 SPACE, U+0009 HORIZONTAL TAB, U+000A LINE FEED,
/// U+000C FORM FEED, or U+000D CARRIAGE RETURN.
pub inline fn is_whitespace(c: u8) bool {
    return switch (c) {
        '\t' => true,
        '\n' => true,
        '\x0C' => true,
        '\r' => true,
        ' ' => true,
        else => false,
    };
}
test "char is_whitespace" {
    const uppercase_a = 'A';
    const uppercase_g = 'G';
    const a = 'a';
    const g = 'g';
    const zero = '0';
    const percent = '%';
    const space = ' ';
    const lf = '\n';
    const esc = '\x1b';

    try testing.expect(!is_whitespace(uppercase_a));
    try testing.expect(!is_whitespace(uppercase_g));
    try testing.expect(!is_whitespace(a));
    try testing.expect(!is_whitespace(g));
    try testing.expect(!is_whitespace(zero));
    try testing.expect(!is_whitespace(percent));
    try testing.expect(is_whitespace(space));
    try testing.expect(is_whitespace(lf));
    try testing.expect(!is_whitespace(esc));
}

pub fn to_digit(comptime T: type, c: u8) ?T {
    if (!is_numeric(c)) return null;
    return @as(T, c - '0');
}
pub fn to_digit_unchecked(comptime T: type, c: u8) T {
    return @as(T, c - '0');
}
pub fn as_usize(ascii_byte: u8) usize {
    return to_digit_unchecked(usize, ascii_byte);
}

test "char to_digit" {
    try testing.expectEqual(9, to_digit(usize, '9'));
    try testing.expectEqual(null, to_digit(usize, 'a'));
    try testing.expectEqual(null, to_digit(usize, '\n'));
}
