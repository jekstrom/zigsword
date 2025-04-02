const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("state.zig");

pub const Adventurer = struct {
    name: [:0]const u8,
    pos: rl.Vector2,
    nameKnown: bool,

    pub fn draw(self: @This(), state: *s.State) void {
        const textureWidth = 100;
        const textureHeight = 124;

        if (state.textureMap.get(.Adventurer)) |texture| {
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
};
