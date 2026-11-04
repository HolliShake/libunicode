const std = @import("std");
const unicode = @import("unicode");

test "public case conversion and identifier APIs" {
    var converted: [3]u32 = undefined;

    try std.testing.expectEqual(@as(c_int, 1), unicode.lre_case_conv(&converted, 'a', 0));
    try std.testing.expectEqual(@as(u32, 'A'), converted[0]);
    try std.testing.expectEqual(@as(unicode.BOOL, unicode.TRUE), unicode.lre_is_id_start(0x03b1));
    try std.testing.expectEqual(@as(u32, 'a'), @as(u32, @intCast(unicode.lre_canonicalize('A', unicode.TRUE))));
}

fn rangeContains(range: *const unicode.CharRange, codepoint: u32) bool {
    var index: usize = 0;
    while (index < @as(usize, @intCast(range.len))) : (index += 2) {
        if (range.points[index] <= codepoint and codepoint < range.points[index + 1]) return true;
    }
    return false;
}

test "NFD decomposes a precomposed Latin character" {
    const source = [_]u32{0x00e9};
    var output: [*c]u32 = null;
    const output_len = unicode.unicode_normalize(&output, &source, source.len, unicode.UNICODE_NFD, null, null);
    defer _ = unicode.realloc(@ptrCast(output), 0);

    try std.testing.expectEqual(@as(c_int, 2), output_len);
    try std.testing.expectEqual(@as(u32, 'e'), output[0]);
    try std.testing.expectEqual(@as(u32, 0x0301), output[1]);
}

test "NFKD applies compatibility decomposition to no-break space" {
    const source = [_]u32{0x00a0};
    var output: [*c]u32 = null;
    const output_len = unicode.unicode_normalize(&output, &source, source.len, unicode.UNICODE_NFKD, null, null);
    defer _ = unicode.realloc(@ptrCast(output), 0);

    try std.testing.expectEqual(@as(c_int, 1), output_len);
    try std.testing.expectEqual(@as(u32, ' '), output[0]);
}

test "general category lookup returns uppercase letters" {
    var range: unicode.CharRange = undefined;
    unicode.cr_init(&range, null, null);
    defer unicode.cr_free(&range);

    try std.testing.expectEqual(@as(c_int, 0), unicode.unicode_general_category(&range, "Lu"));
    try std.testing.expect(rangeContains(&range, 'A'));
    try std.testing.expect(!rangeContains(&range, 'a'));
}

test "White_Space property includes whitespace but not letters" {
    var range: unicode.CharRange = undefined;
    unicode.cr_init(&range, null, null);
    defer unicode.cr_free(&range);

    try std.testing.expectEqual(@as(c_int, 0), unicode.unicode_prop(&range, "White_Space"));
    try std.testing.expect(rangeContains(&range, ' '));
    try std.testing.expect(!rangeContains(&range, 'A'));
}
