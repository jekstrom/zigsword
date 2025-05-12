const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("../objects/state.zig");

pub const HealthPotion = struct {
    healAmount: u8,

    pos: rl.Vector2,
    hovered: bool,
    selected: bool,
    texture: ?rl.Texture,
    index: usize,

    pub fn init(healAmount: u8, state: *s.State) HealthPotion {
        return .{
            .healAmount = healAmount,
            .texture = state.textureMap.get(.HEALTHPOTION),
            .pos = .{ .x = 0, .y = 0 },
            .selected = false,
            .hovered = false,
            .index = 0,
        };
    }

    pub fn draw(self: *@This(), state: *s.State) void {
        _ = state;
        if (self.texture) |txt| {
            var renderY = self.pos.y;
            if (self.hovered or self.selected) {
                renderY -= 32;
            }
            rl.drawTexturePro(
                txt,
                .{
                    .x = 0,
                    .y = 0,
                    .width = 512,
                    .height = 512,
                },
                .{
                    .x = self.pos.x,
                    .y = renderY,
                    .width = 128,
                    .height = 128,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }
    }

    pub fn update(self: *@This(), state: *s.State) !void {
        const mousepos = rl.getMousePosition();

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
            rl.drawRectangle(
                @as(i32, @intFromFloat(mousepos.x)),
                @as(i32, @intFromFloat(mousepos.y)) - 100,
                150,
                70,
                rl.getColor(0x0000D0),
            );

            const st = try std.fmt.allocPrintZ(state.allocator, "Heal adventurer {d}", .{self.healAmount});
            defer state.allocator.free(st);
            rl.drawText(
                st,
                @as(i32, @intFromFloat(mousepos.x)) + 10,
                @as(i32, @intFromFloat(mousepos.y)) - 90,
                20,
                .gray,
            );

            self.hovered = true;

            if (rl.isMouseButtonPressed(rl.MouseButton.left) and hover) {
                self.selected = !self.selected;
            }
        } else {
            self.hovered = false;
        }
    }
};
