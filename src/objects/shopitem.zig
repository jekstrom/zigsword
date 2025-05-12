const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("state.zig");
const d = @import("../die.zig");
const HealthPotion = @import("./healthpotion.zig").HealthPotion;

pub const ShopItem = struct {
    name: [:0]const u8,
    die: ?*d.Die,
    healthPotion: ?*HealthPotion,
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
        if (self.pos.x < state.grid.getWidth()) {
            self.pos.x += rl.math.lerp(0, state.grid.getWidth(), 0.85 * dt);
            return false;
        }
        return true;
    }

    pub fn deinit(self: *@This(), state: *s.State) void {
        if (self.die != null) {
            state.allocator.destroy(self.die.?);
        }
        if (self.healthPotion != null) {
            state.allocator.destroy(self.healthPotion.?);
        }
    }
};
