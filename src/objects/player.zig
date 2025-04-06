const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("state.zig");
const e = @import("../walkingevent.zig");
const ah = @import("../altarHistory.zig");
const d = @import("../die.zig");

pub const Player = struct {
    pos: rl.Vector2,
    equiped: bool,
    name: [:0]u8,
    alignment: enums.Alignment,
    altarHistory: ?std.ArrayList(ah.AltarHistory),
    blessed: bool,
    dice: ?std.ArrayList(d.Die),
    durability: u7,

    // Update based on actions player has taken.
    pub fn update(self: *@This(), state: *s.State) void {
        _ = state;

        if (self.altarHistory == null or self.altarHistory.?.items.len == 0) {
            return;
        }

        var successes: u8 = 0;
        var failures: u8 = 0;
        for (self.altarHistory.?.items) |item| {
            if (item.success) {
                successes += 1;
            } else {
                failures += 1;
            }
        }

        if (successes >= 1) {
            self.blessed = true;
        } else if (failures >= 3) {
            if (self.alignment == .GOOD) {
                self.alignment = .EVIL;
            } else if (self.alignment == .EVIL) {
                self.alignment = .GOOD;
            }
        }
    }

    pub fn draw(self: *@This(), state: *s.State, rotation: f32) void {
        if (self.equiped) {
            self.pos.x = state.adventurer.pos.x - 128 + 15;
            self.pos.y = state.adventurer.pos.y - 40;
        }

        const textureOffset: rl.Rectangle = .{
            .height = -128,
            .width = 128,
            .x = 0,
            .y = 0,
        };
        if (state.textureMap.get(.Sword)) |texture| {
            rl.drawTexturePro(
                texture,
                textureOffset,
                .{
                    .x = self.pos.x + (128 / 2),
                    .y = self.pos.y,
                    .width = 100,
                    .height = 100,
                },
                .{ .x = 0, .y = 0 },
                rotation,
                .white,
            );
        }

        if (self.blessed) {
            rl.drawCircle(
                @as(i32, @intFromFloat(self.pos.x + (128 / 2) + 50)),
                @as(i32, @intFromFloat(self.pos.y)),
                4.0,
                .yellow,
            );
        }
    }

    pub fn drawPortrait(self: @This(), state: *s.State, dest: rl.Rectangle) void {
        _ = self;
        const textureWidth = 128;
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
