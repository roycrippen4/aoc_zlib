const std = @import("std");
const testing = std.testing;

/// Calculates the absolute difference between two values
pub fn abs_diff(comptime T: type, x: T, y: T) T {
    return if (x > y) x - y else y - x;
}

/// Calculates the number of digits in a number
pub fn digits(comptime n: usize) usize {
    if (n == 0) {
        return 1;
    }

    var tmp = n;
    var count: usize = 0;
    while (tmp != 0) : (count += 1) {
        tmp /= 10;
    }

    return count;
}
test "math digits" {
    try testing.expectEqual(9, digits(123456789));
    try testing.expectEqual(1, digits(0));
    try testing.expectEqual(2, digits(10));
    try testing.expectEqual(18, digits(0xC55F7BC23038E38));
}

test "util absDiff" {
    try testing.expectEqual(2, abs_diff(usize, 3, 1));
}

pub fn int(comptime T: type) type {
    if (@typeInfo(T) != std.builtin.Type.int) {
        @compileError("int: must be an integer type");
    }

    return struct {
        const Self = @This();
        const Gcd = GCD(T);

        /// Greatest common denominator implementation.
        pub fn gcd(a: T, b: T) T {
            return Gcd.binary(a, b);
        }
        /// Greatest commmon denominator using the euclidean algorithm
        pub fn gcd_euclid(a: T, b: T) T {
            return Gcd.euclid(a, b);
        }

        /// Least common multiple
        pub fn lcm(a: T, b: T) T {
            return (a / gcd(a, b)) * b;
        }

        pub fn hamming_distance(a: T, b: T) T {
            return @popCount((a ^ b));
        }

        pub fn is_even(n: T) bool {
            return n & 1 == 0;
        }

        pub fn digits(n: T) usize {
            const POW_OF_10 = [21]usize{
                0,
                1,
                10,
                100,
                1000,
                10000,
                100000,
                1000000,
                10000000,
                100000000,
                1000000000,
                10000000000,
                100000000000,
                1000000000000,
                10000000000000,
                100000000000000,
                1000000000000000,
                10000000000000000,
                100000000000000000,
                1000000000000000000,
                10000000000000000000,
            };

            const MAX_DIGITS = [65]u8{
                1,  1,  1,  1,  2,  2,  2,  3,  3,  3,  4,  4,  4,  4,  5,  5,  5,  6,  6,  6,  7,  7,  7,  7,  8,  8,  8,  9,  9,
                9,  10, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13, 13, 13, 14, 14, 14, 15, 15, 15, 16, 16, 16, 16, 17, 17, 17, 18,
                18, 18, 19, 19, 19, 19, 20,
            };

            if (n == 0) return 1;

            const a = if (n < 0) n * -1 else n;

            var dgts = @as(usize, MAX_DIGITS[bits(a)]);
            if (a < POW_OF_10[dgts]) {
                dgts -= 1;
            }

            return dgts;
        }

        pub fn bits(n: T) usize {
            return @sizeOf(T) * 8 - @clz(n);
        }

        pub fn coprime(a: T, b: T) bool {
            return Gcd.binary(a, b) == 1;
        }
    };
}

test "lcm" {
    const U32 = int(u32);
    try testing.expectEqual(36, U32.lcm(12, 18));
    try testing.expectEqual(42, U32.lcm(21, 6));
    try testing.expectEqual(0, U32.lcm(10, 0));
    try testing.expectEqual(0, U32.lcm(0, 10));
    try testing.expectEqual(10, U32.lcm(10, 1));
    try testing.expectEqual(10, U32.lcm(1, 10));
    try testing.expectEqual(U32.lcm(123, 456), U32.lcm(456, 123));
    try testing.expectEqual(300, int(u64).lcm(25, 60));
}

test "hamming_distance" {
    const U32 = int(u32);
    try testing.expectEqual(0, U32.hamming_distance(123, 123));
    try testing.expectEqual(2, U32.hamming_distance(0b101010, 0b100000));
    try testing.expectEqual(5, U32.hamming_distance(100, 123)); // 0b01100100 ^ 0b01111011
    try testing.expectEqual(32, U32.hamming_distance(0, std.math.maxInt(u32)));
    try testing.expectEqual(U32.hamming_distance(123, 456), U32.hamming_distance(456, 123));

    const I8 = int(i8);
    try testing.expectEqual(2, I8.hamming_distance(0b0101, 0b0011));
    try testing.expectEqual(8, I8.hamming_distance(-1, 0)); // -1 is 0b11111111 in i8
    try testing.expectEqual(1, I8.hamming_distance(-1, -2)); // -1 (0b11111111) ^ -2 (0b11111110)
}

test "is_even" {
    const U = int(u32);
    try testing.expect(U.is_even(0));
    try testing.expect(U.is_even(2));
    try testing.expect(U.is_even(100));
    try testing.expect(!U.is_even(1));
    try testing.expect(!U.is_even(101));

    const S = int(i32);
    try testing.expect(S.is_even(0));
    try testing.expect(S.is_even(-2));
    try testing.expect(S.is_even(-100));
    try testing.expect(!S.is_even(-1));
    try testing.expect(!S.is_even(-101));
}

test "digits" {
    const U64 = int(u64);
    try testing.expectEqual(1, U64.digits(0));
    try testing.expectEqual(1, U64.digits(9));
    try testing.expectEqual(2, U64.digits(10));
    try testing.expectEqual(3, U64.digits(100));
    try testing.expectEqual(10, U64.digits(4294967295)); // u32.max
    try testing.expectEqual(20, U64.digits(18446744073709551615)); // u64.max

    try testing.expectEqual(3, U64.digits(999));
    try testing.expectEqual(4, U64.digits(1000));

    const I32 = int(i32);
    try testing.expectEqual(1, I32.digits(-1));
    try testing.expectEqual(3, I32.digits(-100));
}

test "bits" {
    const U16 = int(u16);
    try testing.expectEqual(0, U16.bits(0));
    try testing.expectEqual(1, U16.bits(1));
    try testing.expectEqual(2, U16.bits(2));
    try testing.expectEqual(2, U16.bits(3));
    try testing.expectEqual(3, U16.bits(4));
    try testing.expectEqual(8, U16.bits(255));
    try testing.expectEqual(9, U16.bits(256));
    try testing.expectEqual(16, U16.bits(std.math.maxInt(u16)));
    try testing.expectEqual(16, U16.bits(32768)); // 1 << 15
}

test "int coprime" {
    const U32 = int(u32);
    try testing.expect(U32.coprime(2, 3));
    try testing.expect(U32.coprime(7, 10));
    try testing.expect(U32.coprime(15, 28));
    try testing.expect(U32.coprime(1, 100));
    try testing.expect(U32.coprime(100, 1));
    try testing.expect(U32.coprime(1, 0));
    try testing.expect(U32.coprime(0, 1));

    try testing.expect(!U32.coprime(2, 4));
    try testing.expect(!U32.coprime(6, 9));
    try testing.expect(!U32.coprime(10, 100));
    try testing.expect(!U32.coprime(0, 0));
    try testing.expect(!U32.coprime(2, 0));

    try testing.expect(U32.coprime(3, 2) == U32.coprime(2, 3));
    try testing.expect(U32.coprime(4, 2) == U32.coprime(2, 4));
}

fn GCD(comptime T: type) type {
    if (@typeInfo(T) != std.builtin.Type.int) {
        @compileError("Gcd: must be an integer type");
    }

    return struct {
        /// Binary GCD implementation
        pub fn binary(u_in: T, v_in: T) T {
            var u = u_in;
            var v = v_in;

            if (u == 0) return v;
            if (v == 0) return u;

            const S = std.math.Log2Int(T);
            const shift: S = @intCast(@ctz(u | v));

            u >>= shift;
            v >>= shift;

            const tz_u: S = @intCast(@ctz(u));
            u >>= tz_u;

            while (true) {
                const tz_v: S = @intCast(@ctz(v));
                v >>= tz_v;

                if (u > v) std.mem.swap(T, &u, &v);
                v -= u;

                if (v == 0) break;
            }

            return u << shift;
        }

        /// Euclidean GCD implementation
        pub fn euclid(a_in: T, b_in: T) T {
            var a, var b = if (a_in > b_in)
                .{ a_in, b_in }
            else
                .{ b_in, a_in };

            while (b != 0) {
                std.mem.swap(T, &a, &b);
                b = @mod(b, a);
            }

            return a;
        }
    };
}

fn assertGcdPair(
    comptime T: type,
    a: T,
    b: T,
    expected: T,
) !void {
    const G = GCD(T);
    const g_bin = G.binary(a, b);
    const g_eu = G.euclid(a, b);

    try testing.expectEqual(expected, g_bin);
    try testing.expectEqual(expected, g_eu);
    try testing.expectEqual(expected, G.binary(b, a));
    try testing.expectEqual(expected, G.euclid(b, a));

    if (expected != 0) {
        try testing.expectEqual(@mod(a, expected), 0);
        try testing.expectEqual(@mod(b, expected), 0);
    }
}

fn fuzzUnsignedGcd(comptime T: type) !void {
    const G = GCD(T);

    var prng: std.Random.DefaultPrng = .init(0xdead_beef_1234_5678);
    const rand = prng.random();

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const a = rand.int(T);
        const b = rand.int(T);
        const g_bin = G.binary(a, b);
        const g_eu = G.euclid(a, b);

        try testing.expectEqual(g_eu, g_bin);

        if (g_bin != 0) {
            try testing.expect(a % g_bin == 0);
            try testing.expect(b % g_bin == 0);
        } else {
            try testing.expect(a == 0 and b == 0);
        }
    }
}

test "Gcd known values u32" {
    try assertGcdPair(u32, 0, 0, 0);
    try assertGcdPair(u32, 0, 1, 1);
    try assertGcdPair(u32, 1, 0, 1);
    try assertGcdPair(u32, 0, 42, 42);
    try assertGcdPair(u32, 42, 0, 42);
    try assertGcdPair(u32, 1, 1, 1);
    try assertGcdPair(u32, 2, 4, 2);
    try assertGcdPair(u32, 4, 6, 2);
    try assertGcdPair(u32, 8, 12, 4);
    try assertGcdPair(u32, 12, 18, 6);
    try assertGcdPair(u32, 48, 180, 12);
    try assertGcdPair(u32, 270, 192, 6);
    try assertGcdPair(u32, 17, 29, 1);
    try assertGcdPair(u32, 35, 64, 1);
    try assertGcdPair(u32, 1_000_000, 2, 2);
    try assertGcdPair(u32, 1_000_001, 2, 1);
    try assertGcdPair(u32, 1 << 10, 1 << 15, 1 << 10);
    try assertGcdPair(u32, (1 << 31) - 1, (1 << 31) - 3, 1);
}

test "Gcd known values u64" {
    try assertGcdPair(u64, 0, 0, 0);
    try assertGcdPair(u64, 1, 1, 1);
    try assertGcdPair(u64, 2, 2, 2);
    try assertGcdPair(u64, 2, 10, 2);
    try assertGcdPair(u64, 21, 14, 7);
    try assertGcdPair(u64, 2_147_483_648, 1_073_741_824, 1_073_741_824);
    try assertGcdPair(u64, 12_345_678_900, 9_876_543_000, 300);
}

test "Gcd known values small unsigned types" {
    try assertGcdPair(u8, 0, 0, 0);
    try assertGcdPair(u8, 25, 15, 5);
    try assertGcdPair(u8, 100, 40, 20);
    try assertGcdPair(u16, 300, 150, 150);
    try assertGcdPair(u16, 65535, 255, 255);
}

test "Gcd fuzz unsigned types" {
    try fuzzUnsignedGcd(u8);
    try fuzzUnsignedGcd(u16);
    try fuzzUnsignedGcd(u32);
    try fuzzUnsignedGcd(u64);
    try fuzzUnsignedGcd(usize);
}

test "Gcd signed non-negative values" {
    try assertGcdPair(i32, 0, 0, 0);
    try assertGcdPair(i32, 12, 18, 6);
    try assertGcdPair(i32, 48, 180, 12);
    try assertGcdPair(i32, 270, 192, 6);
}
