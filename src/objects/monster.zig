const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("state.zig");

pub const Monster = struct {
    name: [:0]const u8,
    pos: rl.Vector2,
    nameKnown: bool,
    speed: f32,
    health: u8,
    damageRange: u8,

    pub fn enter(self: *@This(), state: *s.State, dt: f32) bool {
        if (self.pos.x > state.grid.getGroundCenterPos().x + 200) {
            self.pos.x -= rl.math.lerp(0, state.grid.getGroundCenterPos().x + 200, self.speed * dt);
            return false;
        }
        return true;
    }

    pub fn exit(self: *@This(), state: *s.State, dt: f32) bool {
        if (self.pos.x < state.grid.getWidth()) {
            state.adventurer.pos.x += rl.math.lerp(0, state.grid.getWidth(), self.speed * dt);
            return false;
        }
        return true;
    }

    pub fn attack(self: @This(), state: *s.State) void {
        const damage = state.rand.intRangeAtMost(u8, 1, self.damageRange);
        std.debug.print("Monster did damage: {d}\n", .{damage});
        if (damage > state.adventurer.health) {
            state.adventurer.health = 0;
        } else {
            state.adventurer.health -= damage;
        }
    }

    pub fn draw(self: @This(), state: *s.State) void {
        const textureWidth = 128;
        const textureHeight = 128;
        if (self.health <= 0) {
            return;
        }

        if (std.mem.eql(u8, self.name, "Green Goblin")) {
            if (state.textureMap.get(.GREENGOBLIN)) |texture| {
                rl.drawTexturePro(
                    texture,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = -textureWidth,
                        .height = textureHeight,
                    },
                    .{
                        .height = textureHeight,
                        .width = textureWidth,
                        .x = self.pos.x,
                        .y = self.pos.y,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .white,
                );
            }
        }

        if (std.mem.eql(u8, self.name, "Red Goblin")) {
            if (state.textureMap.get(.REDGOBLIN)) |texture| {
                rl.drawTexturePro(
                    texture,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = textureWidth,
                        .height = textureHeight,
                    },
                    .{
                        .height = textureHeight,
                        .width = textureWidth,
                        .x = self.pos.x,
                        .y = self.pos.y,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .white,
                );
            }
        }

        if (self.health > 0) {
            rl.drawRectanglePro(
                .{
                    .height = 7,
                    .width = @as(f32, @floatFromInt(self.health)),
                    .x = self.pos.x + 8,
                    .y = self.pos.y - 5,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .red,
            );
        }
    }

    pub fn drawPortrait(self: @This(), state: *s.State, dest: rl.Rectangle) void {
        _ = self;
        const textureWidth = 30;
        const textureHeight = 30;

        if (state.textureMap.get(.Adventurer)) |texture| {
            rl.drawTexturePro(
                texture,
                .{
                    .x = 30,
                    .y = 0,
                    .width = textureWidth,
                    .height = textureHeight,
                },
                dest,
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }
    }

    pub fn collides(self: @This(), other: rl.Vector2) bool {
        return rl.Vector2.distance(self.pos.normalize(), other.normalize()) <= 1;
    }
};
