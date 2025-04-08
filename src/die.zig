const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("objects/state.zig");

pub const Die = struct {
    name: [:0]const u8,
    sides: u8,
    pos: rl.Vector2,
    hovered: bool,
    selected: bool,
    texture: ?rl.Texture,
    index: usize,

    pub fn roll(self: @This(), state: *s.State) u8 {
        return state.rand.intRangeAtMost(u8, 1, self.sides);
    }

    pub fn update(self: *@This(), state: *s.State) void {
        const mousepos = rl.getMousePosition();
        const dice = state.player.dice;
        var currentlySelectedDice: u8 = 0;
        const numDice = dice.?.items.len;

        if (dice == null) {
            // This should be impossible.
            std.debug.assert(false);
        }

        for (0..numDice) |i| {
            const die = dice.?.items[i];
            if (die.selected) {
                currentlySelectedDice += 1;
            }
        }

        // Update positions
        var xoffset: f32 = 50.0;
        xoffset = 50.0 * @as(f32, @floatFromInt(self.index));
        self.pos.x = state.grid.getWidth() - 550 + xoffset;
        self.pos.y = state.grid.topUI() + 10;

        // handle hover and select
        var renderY = self.pos.y;
        var renderHeight: f32 = 64;
        if (self.hovered or self.selected) {
            renderY -= 32;
            renderHeight += 32;
        }
        const collisionRect = rl.Rectangle.init(
            self.pos.x,
            renderY,
            64,
            renderHeight,
        );

        const hover = collisionRect.checkCollision(.{
            .x = mousepos.x,
            .y = mousepos.y,
            .height = 2,
            .width = 2,
        });

        if (s.DEBUG_MODE) {
            rl.drawRectangleRec(collisionRect, .magenta);
        }

        if (hover) {
            var buffer: [64:0]u8 = std.mem.zeroes([64:0]u8);
            _ = std.fmt.bufPrintZ(
                &buffer,
                "{s}",
                .{self.name},
            ) catch "";

            rl.drawRectangle(
                @as(i32, @intFromFloat(mousepos.x)),
                @as(i32, @intFromFloat(mousepos.y)) - 100,
                100,
                70,
                rl.getColor(0x0000D0),
            );

            rl.drawText(
                &buffer,
                @as(i32, @intFromFloat(mousepos.x)) + 10,
                @as(i32, @intFromFloat(mousepos.y)) - 90,
                20,
                .gray,
            );

            self.hovered = true;

            if (rl.isMouseButtonPressed(rl.MouseButton.left) and hover) {
                if (state.player.maxSelectedDice > currentlySelectedDice or self.selected) {
                    self.selected = !self.selected;
                }
            }
        } else {
            self.hovered = false;
        }
    }

    pub fn draw(self: @This(), state: *s.State) void {
        var texture: ?rl.Texture = null;
        if (self.sides == 4) {
            texture = state.textureMap.get(.D4);
        } else if (self.sides == 6) {
            texture = state.textureMap.get(.D6);
        }
        if (texture) |txt| {
            var renderY = self.pos.y;
            if (self.hovered or self.selected) {
                renderY -= 32;
            }
            rl.drawTexturePro(
                txt,
                .{
                    .x = 0,
                    .y = 0,
                    .width = 128,
                    .height = 128,
                },
                .{
                    .x = self.pos.x,
                    .y = renderY,
                    .width = 64,
                    .height = 64,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }
    }
};
