const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");

pub const AltarHistory = struct {
    name: [:0]const u8,
    success: bool,
};
