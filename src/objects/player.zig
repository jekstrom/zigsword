const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("state.zig");

pub const Player = struct {
    pos: rl.Vector2,
    equiped: bool,
    name: [:0]u8,

    pub fn draw(self: @This(), state: *s.State, rotation: f32) void {
        const textureOffset: rl.Rectangle = .{
            .height = 128,
            .width = 50,
            .x = 0,
            .y = 0,
        };
        if (state.textureMap.get(.Sword)) |texture| {
            rl.drawTexturePro(
                texture,
                textureOffset,
                .{
                    .x = self.pos.x,
                    .y = self.pos.y,
                    .width = 40,
                    .height = 100,
                },
                .{ .x = 0, .y = 0 },
                rotation,
                .white,
            );
        }
    }

    pub fn drawPortrait(self: @This(), state: *s.State, dest: rl.Rectangle) void {
        _ = self;
        const textureWidth = 50;
        const textureHeight = 128;

        if (state.textureMap.get(.Sword)) |texture| {
            rl.drawTexturePro(
                texture,
                .{
                    .x = 0,
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
};
