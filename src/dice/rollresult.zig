const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("../objects/state.zig");
const Die = @import("../die.zig").Die;

// Linked List of dice roll results
pub const RollResult = struct {
    num: u16,
    sides: u16,
    rarity: u8,
    color: i32,
};
