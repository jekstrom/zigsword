const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const Rune = @import("rune.zig").Rune;
const RollResult = @import("../dice/rollresult.zig").RollResult;
const Die = @import("../die.zig").Die;
const BasicDie = @import("../dice/basic.zig").BasicDie;

// A Kin Rune cares about pairs of dice.
// If a pair is rolled, it adds a bonus.
pub const KinRune = struct {
    name: [:0]const u8 = "ᛟ Kin",
    pos: rl.Vector2,
    hovered: bool = false,
    selected: bool = false,

    pub fn getName(ptr: *anyopaque) anyerror![:0]const u8 {
        const self: *KinRune = @ptrCast(@alignCast(ptr));
        return self.name;
    }

    pub fn getPos(ptr: *anyopaque) anyerror!rl.Vector2 {
        const self: *KinRune = @ptrCast(@alignCast(ptr));
        return self.pos;
    }

    pub fn setPos(ptr: *anyopaque, newPos: rl.Vector2) anyerror!void {
        const self: *KinRune = @ptrCast(@alignCast(ptr));
        self.pos = newPos;
    }

    pub fn getSelected(ptr: *anyopaque) anyerror!bool {
        const self: *KinRune = @ptrCast(@alignCast(ptr));
        return self.selected;
    }

    pub fn setSelected(ptr: *anyopaque, val: bool) anyerror!void {
        const self: *KinRune = @ptrCast(@alignCast(ptr));
        self.selected = val;
    }

    pub fn draw(ptr: *anyopaque, state: *s.State) void {
        const self: *KinRune = @ptrCast(@alignCast(ptr));

        const textureWidth = 128;
        const textureHeight = 128;

        const mousepos = rl.getMousePosition();

        const tooltip: [:0]const u8 = "Kin\n Creates another die \nfor each pair rolled";

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

        if (state.textureMap.get(.KINRUNE)) |texture| {
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
        if (rollResults == null) {
            return;
        }

        const self: *KinRune = @ptrCast(@alignCast(ptr));
        _ = self;
        var seen = std.AutoHashMap(u16, u16).init(state.allocator);
        defer seen.deinit();

        for (0..rollResults.?.items.len) |i| {
            // Check for pairs
            // Results are considered pairs if the value matches, regardless of the number of sides of the dice.
            const result = rollResults.?.items[i];
            if (seen.get(result.baseNum)) |cnt| {
                try seen.put(result.baseNum, cnt + 1);
            } else {
                try seen.put(result.baseNum, 1);
            }
        }

        var it = seen.valueIterator();
        while (it.next()) |value_ptr| {
            const val = value_ptr.*;
            if (val >= 2) {
                std.debug.print("Kin Rune found duplicate with value: {d}\n", .{val});
                // Add a die that is at least as big as the value seen
                var dieToAdd: ?*Die = null;
                const lastDieIndex = state.player.dice.?.items.len;
                if (val <= 4) {
                    var d4 = try state.allocator.create(BasicDie);
                    d4.name = "Basic d4";
                    d4.sides = 4;
                    d4.texture = state.textureMap.get(.D4);
                    d4.hovered = false;
                    d4.selected = false;
                    d4.index = lastDieIndex;
                    d4.pos = .{
                        .x = state.grid.getWidth() - 550,
                        .y = state.grid.topUI() + 10,
                    };
                    dieToAdd = try d4.die(&state.allocator);
                } else {
                    var d6 = try state.allocator.create(BasicDie);
                    d6.name = "Basic d6";
                    d6.sides = 6;
                    d6.texture = state.textureMap.get(.D6);
                    d6.hovered = false;
                    d6.selected = false;
                    d6.index = lastDieIndex;
                    d6.pos = .{
                        .x = state.grid.getWidth() - 550,
                        .y = state.grid.topUI() + 10,
                    };
                    dieToAdd = try d6.die(&state.allocator);
                }

                std.debug.print("Adding die {s}\n", .{dieToAdd.?.name});
                try state.player.addDie(dieToAdd.?);
            }
        }
    }

    pub fn rune(self: *KinRune, allocator: *const std.mem.Allocator) !*Rune {
        return try Rune.init(
            self,
            self.name,
            allocator,
        );
    }
};
