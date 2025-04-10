const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("state.zig");

pub const Adventurer = struct {
    name: [:0]const u8,
    pos: rl.Vector2,
    nameKnown: bool,
    speed: f32,
    health: u8,
    texture: rl.Texture,

    pub fn entered(self: @This(), state: *s.State) bool {
        return self.pos.x >= state.grid.getGroundCenterPos().x;
    }

    pub fn enter(self: *@This(), state: *s.State, dt: f32) bool {
        if (self.pos.x < state.grid.getGroundCenterPos().x) {
            state.adventurer.pos.x += rl.math.lerp(0, state.grid.getGroundCenterPos().x, self.speed * dt);
            return false;
        }
        return true;
    }

    pub fn exit(self: *@This(), state: *s.State) bool {
        if (self.pos.x < state.grid.getWidth()) {
            state.adventurer.pos.x += rl.math.lerp(0, state.grid.getWidth(), self.speed * rl.getFrameTime());
            return false;
        }
        return true;
    }

    pub fn draw(self: @This(), state: *s.State) void {
        _ = state;
        const textureWidth = 100;
        const textureHeight = 124;

        rl.drawTexturePro(
            self.texture,
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
