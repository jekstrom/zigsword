const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("objects/state.zig");

pub const Die = struct {
    name: [:0]const u8,
    sides: u8,

    pub fn roll(self: @This(), state: *s.State) u8 {
        return state.rand.intRangeAtMost(u8, 1, self.sides);
    }
};
