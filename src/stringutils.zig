const std = @import("std");

pub fn concatStrings(allocator: std.mem.Allocator, str1: [:0]const u8, str2: [:0]const u8) ![:0]u8 {
    const len1 = str1.len;
    const len2 = str2.len;

    var chars1: usize = 0;
    for (0..len1) |i| {
        if (str1[i] > 0) {
            chars1 += 1;
        }
    }

    var chars2: usize = 0;
    for (0..len2) |i| {
        if (str2[i] > 0) {
            chars2 += 1;
        }
    }

    const totalContentLen = chars1 + chars2;

    const result = try allocator.allocSentinel(u8, totalContentLen, 0);
    errdefer allocator.free(result);

    @memcpy(result.ptr[0..chars1], str1.ptr[0..chars1]);
    @memcpy(result.ptr[chars1 .. chars1 + chars2], str2.ptr[0..chars2]);
    return result;
}
