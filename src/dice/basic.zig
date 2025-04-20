const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("../objects/state.zig");
const Die = @import("../die.zig").Die;
const RollResult = @import("rollresult.zig").RollResult;
const concatStrings = @import("../stringutils.zig").concatStrings;

pub const BasicDie = struct {
    name: [:0]const u8,
    sides: u16,
    nextResult: u16 = 0,
    pos: rl.Vector2,
    hovered: bool,
    selected: bool,
    texture: ?rl.Texture,
    index: usize,
    breakChance: u7,
    broken: bool,
    tooltip: [:0]const u8,

    pub fn getSides(ptr: *anyopaque) anyerror!u16 {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        return self.sides;
    }

    pub fn getNextResult(ptr: *anyopaque) anyerror!u16 {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        return self.nextResult;
    }

    pub fn getPos(ptr: *anyopaque) anyerror!rl.Vector2 {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        return self.pos;
    }

    pub fn getHovered(ptr: *anyopaque) anyerror!bool {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        return self.hovered;
    }

    pub fn getSelected(ptr: *anyopaque) anyerror!bool {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        return self.selected;
    }

    pub fn setSelected(ptr: *anyopaque, val: bool) anyerror!void {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        self.selected = val;
    }

    pub fn getTexture(ptr: *anyopaque) anyerror!?rl.Texture {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        return self.texture;
    }

    pub fn getIndex(ptr: *anyopaque) anyerror!usize {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        return self.index;
    }

    pub fn setIndex(ptr: *anyopaque, newIndex: usize) anyerror!void {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        self.index = newIndex;
    }

    pub fn getTooltip(ptr: *anyopaque) anyerror![:0]const u8 {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        return self.tooltip;
    }

    pub fn setTooltip(ptr: *anyopaque, newTooltip: [:0]const u8) anyerror!void {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        std.debug.print("Set tooltip ", .{});
        std.debug.print("{s} on die {s}\n", .{ self.name, newTooltip });
        self.tooltip = newTooltip;
    }

    pub fn getBroken(ptr: *anyopaque) anyerror!bool {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        return self.broken;
    }

    pub fn roll(ptr: *anyopaque, state: *s.State, prevRollResult: *const std.ArrayList(RollResult)) anyerror!RollResult {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        const result = self.nextResult;
        std.debug.print("Roll result {d}/{d}\n", .{ result, self.sides });
        var curTotal: u32 = 0;
        if (prevRollResult.items.len > 0) {
            curTotal = prevRollResult.items[prevRollResult.items.len - 1].num;
        }

        if (self.breakChance > 0) {
            const broke = state.rand.intRangeAtMost(u7, 1, std.math.maxInt(u7));
            self.broken = self.breakChance <= broke;
        }

        self.nextResult = 0;
        const tooltip = "";
        if (self.tooltip.len > 0) {
            state.allocator.free(self.tooltip);
        }
        self.tooltip = tooltip;

        return .{
            .num = result + curTotal,
            .baseNum = result,
            .sides = self.sides,
            .rarity = 0,
            .color = 0,
            .broken = self.broken,
        };
    }

    pub fn update(ptr: *anyopaque, state: *s.State) !void {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));

        const mousepos = rl.getMousePosition();
        const dice = state.player.dice;
        var currentlySelectedDice: u8 = 0;
        const numDice = dice.?.items.len;

        if (self.nextResult == 0) {
            std.debug.print("sides: {d}\n", .{self.sides});
            self.nextResult = state.rand.intRangeAtMost(u16, 1, self.sides);
        }

        if (dice == null) {
            // This should be impossible.
            std.debug.assert(false);
        }

        for (0..numDice) |i| {
            const d = dice.?.items[i];
            if (try d.getSelected()) {
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
            var string = std.ArrayList(u8).init(state.allocator);
            defer string.deinit();
            if (self.tooltip.len > 0) {
                const tt = try concatStrings(state.allocator, self.name, self.tooltip);
                defer state.allocator.free(tt);
                try string.appendSlice(tt);
            } else {
                try string.appendSlice(self.name);
            }

            rl.drawRectangle(
                @as(i32, @intFromFloat(mousepos.x)),
                @as(i32, @intFromFloat(mousepos.y)) - 100,
                150,
                70,
                rl.getColor(0x0000D0),
            );

            const sresult = try state.allocator.allocSentinel(u8, string.items.len, 0);
            defer state.allocator.free(sresult);
            @memcpy(sresult.ptr[0..string.items.len], string.items.ptr[0..string.items.len]);

            rl.drawText(
                sresult,
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

    pub fn draw(ptr: *anyopaque, state: *s.State) void {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));

        // TODO: Abstract this out of individual die
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

    pub fn deinit(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *BasicDie = @ptrCast(@alignCast(ptr));
        if (self.tooltip.len > 0) {
            state.allocator.free(self.tooltip);
        }
    }

    pub fn die(self: *BasicDie, allocator: *const std.mem.Allocator) !*Die {
        return try Die.init(
            self,
            self.name,
            self.sides,
            self.pos,
            self.hovered,
            self.selected,
            self.texture,
            self.index,
            self.breakChance,
            self.tooltip,
            allocator,
        );
    }
};
