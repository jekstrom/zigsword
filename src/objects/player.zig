const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("state.zig");
const e = @import("../walkingevent.zig");
const ah = @import("../altarHistory.zig");
const d = @import("../die.zig");
const shop = @import("shopitem.zig");
const m = @import("monster.zig");

pub const Player = struct {
    pos: rl.Vector2,
    equiped: bool,
    name: [:0]u8,
    alignment: enums.Alignment,
    altarHistory: ?std.ArrayList(ah.AltarHistory),
    blessed: bool,
    dice: ?std.ArrayList(d.Die),
    durability: u8,
    gold: i32,
    maxSelectedDice: u8,
    messages: ?std.ArrayList([:0]const u8),

    pub fn attack(self: *@This(), state: *s.State, monster: *m.Monster) !void {
        // self.durability -= 20;

        var dice = self.dice;
        if (dice == null) {
            std.debug.assert(false);
        }

        // roll selected dice
        var result: i32 = 0;
        for (0..dice.?.items.len) |i| {
            const die = dice.?.items[i];
            if (die.selected) {
                const dieResult = die.roll(state);
                result += dieResult;
                std.debug.print("Roll result: {d}/{d}\n", .{ dieResult, die.sides });
            }
        }

        // remove selected dice
        var i = dice.?.items.len;
        const prevLen = dice.?.items.len;
        var removedCount: i32 = 0;
        while (i > 0) {
            i -= 1;
            if (dice.?.items[i].selected) {
                removedCount += 1;
                _ = dice.?.orderedRemove(i);
            }
        }
        // Make sure the size of the list is equal to the number of elements
        try self.dice.?.resize(prevLen - @as(usize, @intCast(removedCount)));

        var damageScaled = result;

        if (self.blessed) {
            damageScaled *= 20;
        }

        std.debug.print("Damage: {d}\n", .{damageScaled});

        if (damageScaled >= monster.health) {
            monster.health = 0;
        } else {
            monster.health -= @as(u32, @intCast(damageScaled));
        }
        if (monster.messages != null) {
            var floatLog: f16 = 1.0;
            if (damageScaled > 0) {
                floatLog = @floor(@log10(@as(f16, @floatFromInt(damageScaled))) + 1.0);
            }
            const digits: u64 = @as(u64, @intFromFloat(floatLog));
            const buffer = try state.allocator.allocSentinel(
                u8,
                digits,
                0,
            );
            _ = std.fmt.bufPrint(
                buffer,
                "{d}",
                .{damageScaled},
            ) catch "";
            try monster.messages.?.append(buffer);
        }
    }

    pub fn purchaseItem(self: *@This(), shopItem: shop.ShopItem) !bool {
        if (self.dice == null) {
            std.debug.assert(false);
            return false;
        }
        if (self.gold < shopItem.price) {
            return false;
        }

        try self.dice.?.append(shopItem.die.?);
        self.gold -= shopItem.price;
        return true;
    }

    // Update based on actions player has taken.
    pub fn update(self: *@This(), state: *s.State) !void {
        if (self.dice == null and (self.altarHistory == null or self.altarHistory.?.items.len == 0)) {
            return;
        }

        if (self.messages == null) {
            std.debug.assert(false);
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
            if (!self.blessed) {
                self.blessed = true;
                try self.messages.?.append("Blessed");
            }
        } else if (failures >= 3) {
            if (self.alignment == .GOOD) {
                self.alignment = .EVIL;
            } else if (self.alignment == .EVIL) {
                self.alignment = .GOOD;
            }
        }

        if (self.dice) |dice| {
            for (0..dice.items.len) |i| {
                dice.items[i].index = i;
                dice.items[i].update(state);
            }
        }
    }

    pub fn displayMessages(self: *@This(), decay: u8, dt: f32) bool {
        if (self.messages == null or self.messages.?.items.len == 0) {
            return false;
        }
        const last = self.messages.?.items.len - 1;
        const msg = self.messages.?.items[last];
        if (decay > 0) {
            rl.drawText(
                msg,
                @as(i32, @intFromFloat(self.pos.x + 115)),
                @as(i32, @intFromFloat(self.pos.y - 55 + (10 * dt))),
                20,
                rl.Color.init(50, 50, 250, decay),
            );
            return true;
        }
        if (decay == 0) {
            _ = self.messages.?.pop();
            return false;
        }
        return false;
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
