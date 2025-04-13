const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("state.zig");
const e = @import("../walkingevent.zig");
const ah = @import("../altarHistory.zig");
const d = @import("../die.zig");
const shop = @import("shopitem.zig");
const m = @import("monster.zig");
const RollResult = @import("../dice/rollresult.zig").RollResult;
const Rune = @import("../runes/rune.zig").Rune;

pub const Player = struct {
    pos: rl.Vector2,
    rotation: f32,
    equiped: bool,
    name: [:0]u8,
    alignment: enums.Alignment,
    altarHistory: ?std.ArrayList(ah.AltarHistory),
    blessed: bool,
    dice: ?std.ArrayList(*d.Die),
    durability: u8,
    gold: i32,
    maxSelectedDice: u8,
    messages: ?std.ArrayList([:0]const u8),
    playerMsgDecay: u8 = 255,
    stateMachine: ?@import("../states/stateMachine.zig").StateMachine,
    runes: ?std.ArrayList(*Rune),

    pub fn attack(self: *@This(), state: *s.State, monster: *m.Monster) anyerror!void {
        // self.durability -= 20;

        var dice = self.dice;
        if (dice == null) {
            std.debug.assert(false);
        }

        // roll selected dice
        const rollResultsList = std.ArrayList(RollResult);
        var rollResults: rollResultsList = rollResultsList.init(state.allocator);
        defer rollResults.deinit();

        for (0..dice.?.items.len) |i| {
            const die = dice.?.items[i];
            if (try die.getSelected()) {
                const rollResult = try die.roll(state, &rollResults);
                try rollResults.append(rollResult);
            }
        }
        var result: u16 = 0;
        if (rollResults.items.len > 0) {
            result = rollResults.items[rollResults.items.len - 1].num;
        }
        std.debug.print("Final Roll result: {d} from {d} dice\n", .{ result, rollResults.items.len });

        if (self.runes != null and self.runes.?.items.len > 0) {
            // Handle runes
            const runesList: []*Rune = self.runes.?.items;
            for (0..runesList.len) |i| {
                var r = runesList[i];
                try r.handle(state, &rollResults);
                std.debug.print("Rune {s} activated \n", .{try r.getName()});
            }
        }

        // remove selected dice
        var i = self.dice.?.items.len;
        // Update new list with remaining dice that are not being removed.
        var newDice = std.ArrayList(*d.Die).init(state.allocator);

        var removedCount: i32 = 0;
        while (i > 0) {
            i -= 1;
            if (try self.dice.?.items[i].getSelected() and try self.dice.?.items[i].getBroken()) {
                removedCount += 1;
                _ = dice.?.orderedRemove(i);
            } else {
                try newDice.insert(0, self.dice.?.items[i]);
            }
        }

        self.dice.?.clearAndFree();
        self.dice.?.deinit();
        self.dice = newDice;

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

    pub fn addDie(self: *@This(), die: *d.Die) !void {
        if (self.dice == null) {
            std.debug.assert(false);
        }

        try self.dice.?.append(die);
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
    pub fn update(self: *@This(), state: *s.State) anyerror!void {
        // if (self.stateMachine != null and self.stateMachine.?.state.getIsComplete()) {
        //     // do state transition
        //     const nextState: ?*@import("../states/smState.zig").SMState = self.stateMachine.?.state.nextState;
        //     if (nextState != null) {
        //         std.debug.print("Player Next state: {}\n", .{nextState.?.smType});
        //         try self.stateMachine.?.setState(nextState.?, state);
        //     } else {
        //         std.debug.print("Player Next state is null\n", .{});
        //     }
        // }

        // if (self.stateMachine != null) {
        //     try self.stateMachine.?.state.update(state);
        // }

        if (state.adventurer.health <= 0) {
            // Reset -- wait for next adventurer
            self.equiped = false;
            state.adventurer.pos.x = -200;
            state.mode = .ADVENTURERDEATH;
            self.rotation = 180.0;
        } else if (state.adventurer.entered(state)) {
            // This is a toggle, not a continuous check
            self.equiped = true;
        }

        if (self.equiped) {
            self.rotation = 0.0;
            self.pos.y = state.adventurer.pos.y;
        }

        if (self.dice == null and (self.altarHistory == null or self.altarHistory.?.items.len == 0)) {
            return;
        }

        if (self.messages == null) {
            std.debug.print("Player update. Messages == null\n", .{});
            std.debug.assert(false);
        }

        const playerMessageDisplayed = self.displayMessages(
            self.playerMsgDecay,
            rl.getFrameTime() * @as(f32, @floatFromInt(self.playerMsgDecay)),
        );
        if (self.playerMsgDecay == 0) {
            self.playerMsgDecay = 255;
        }

        if (playerMessageDisplayed) {
            const ddiff = @as(u8, @intFromFloat(rl.math.clamp(230 * rl.getFrameTime(), 0, 255)));
            const rs = @subWithOverflow(self.playerMsgDecay, ddiff);
            if (rs[1] != 0) {
                self.playerMsgDecay = 0;
            } else {
                self.playerMsgDecay -= ddiff;
            }
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

        if (successes >= 3) {
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
                try dice.items[i].setIndex(i);
                var dd = dice.items[i];
                try dd.update(state);
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
                @as(i32, @intFromFloat(self.pos.y - 105 + (10 * dt))),
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

    pub fn draw(self: *@This(), state: *s.State) void {
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
                self.rotation,
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
