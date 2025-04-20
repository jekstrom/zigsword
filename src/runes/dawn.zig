const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const Rune = @import("rune.zig").Rune;
const RollResult = @import("../dice/rollresult.zig").RollResult;
const Die = @import("../die.zig").Die;
const BasicDie = @import("../dice/basic.zig").BasicDie;

// A ᛞ Dawn Rune gives you bonus damage on the first die rolled.
pub const DawnRune = struct {
    name: [:0]const u8 = "Dawn",
    pos: rl.Vector2,
    hovered: bool = false,
    selected: bool = false,

    pub fn getName(ptr: *anyopaque) anyerror![:0]const u8 {
        const self: *DawnRune = @ptrCast(@alignCast(ptr));
        return self.name;
    }

    pub fn getPos(ptr: *anyopaque) anyerror!rl.Vector2 {
        const self: *DawnRune = @ptrCast(@alignCast(ptr));
        return self.pos;
    }

    pub fn setPos(ptr: *anyopaque, newPos: rl.Vector2) anyerror!void {
        const self: *DawnRune = @ptrCast(@alignCast(ptr));
        self.pos = newPos;
    }

    pub fn getSelected(ptr: *anyopaque) anyerror!bool {
        const self: *DawnRune = @ptrCast(@alignCast(ptr));
        return self.selected;
    }

    pub fn setSelected(ptr: *anyopaque, val: bool) anyerror!void {
        const self: *DawnRune = @ptrCast(@alignCast(ptr));
        self.selected = val;
    }

    pub fn deinit(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *DawnRune = @ptrCast(@alignCast(ptr));
        state.allocator.destroy(self);
    }

    pub fn draw(ptr: *anyopaque, state: *s.State) void {
        const self: *DawnRune = @ptrCast(@alignCast(ptr));

        const textureWidth = 128;
        const textureHeight = 128;

        const mousepos = rl.getMousePosition();

        const tooltip: [:0]const u8 = "Dawn\n First die rolled\ngets bonus damage";

        // handle hover and select
        var renderY = self.pos.y;
        var renderHeight: f32 = 64;
        if (self.selected) {
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

        if (state.textureMap.get(.DAWNRUNE)) |texture| {
            rl.drawTexturePro(
                texture,
                .{
                    .x = 0,
                    .y = 0,
                    .width = textureWidth,
                    .height = textureHeight,
                },
                .{
                    .height = 64,
                    .width = 64,
                    .x = self.pos.x,
                    .y = renderY,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }

        if (s.DEBUG_MODE) {
            rl.drawRectangleRec(collisionRect, .magenta);
        }

        if (hover) {
            rl.drawRectangle(
                @as(i32, @intFromFloat(mousepos.x)) - 160,
                @as(i32, @intFromFloat(mousepos.y)) - 100,
                300,
                100,
                rl.getColor(0x0000D0),
            );

            rl.drawText(
                tooltip,
                @as(i32, @intFromFloat(mousepos.x)) - 150,
                @as(i32, @intFromFloat(mousepos.y)) - 90,
                20,
                .gray,
            );

            self.hovered = true;

            if (rl.isMouseButtonPressed(rl.MouseButton.left) and hover) {
                if (self.selected or state.currentSelectedRuneCount < state.maxSelectedRunes) {
                    self.selected = !self.selected;
                    if (self.selected) {
                        state.currentSelectedRuneCount += 1;
                    } else {
                        state.currentSelectedRuneCount -= 1;
                    }
                }
            }
        } else {
            self.hovered = false;
        }
    }

    pub fn handle(ptr: *anyopaque, state: *s.State, rollResults: ?*std.ArrayList(RollResult)) !void {
        const self: *DawnRune = @ptrCast(@alignCast(ptr));
        _ = self;

        // pick a random die and show the what the next result will be
        if (state.player.dice == null) {
            std.debug.print("No dice\n", .{});
            std.debug.assert(false);
        }

        if (state.player.dice.?.items.len == 0 or rollResults == null) {
            return;
        }

        rollResults.?.items[0].num += 10;
    }

    pub fn rune(self: *DawnRune, allocator: *const std.mem.Allocator) !*Rune {
        return try Rune.init(
            self,
            self.name,
            allocator,
        );
    }
};
