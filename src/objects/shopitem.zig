const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("state.zig");
const d = @import("../die.zig");

pub const ShopItem = struct {
    name: [:0]const u8,
    die: ?*d.Die,
    price: u8,
    pos: rl.Vector2,
    texture: rl.Texture,
    purchased: bool,
    // Add other types of items here

    pub fn enter(self: *@This(), dest: f32, dt: f32) bool {
        if (self.pos.x < dest) {
            self.pos.x += rl.math.lerp(0, dest, 0.75 * dt);
            return false;
        }
        return true;
    }

    pub fn exit(self: *@This(), state: *s.State, dt: f32) bool {
        if (self.pos.x < state.grid.constconstgetWidth()) {
            self.pos.x += rl.math.lerp(0, state.grid.getWidth(), 0.85 * dt);
            return false;
        }
        return true;
    }
};
