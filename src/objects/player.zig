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
const BasicDie = @import("../dice/basic.zig").BasicDie;
const MultDie = @import("../dice/mult.zig").MultDie;
const Die = @import("../die.zig").Die;

pub const Player = struct {
    pos: rl.Vector2,
    rotation: f32,
    equiped: bool,
    name: [:0]u8,
    alignment: enums.Alignment,
    altarHistory: ?std.ArrayList(ah.AltarHistory),
    blessed: bool,
    dice: ?std.ArrayList(*d.Die),
    maxDice: u8,
    durability: u8,
    gold: i32,
    maxSelectedDice: u8,
    messages: ?std.ArrayList([:0]const u8),
    playerMsgDecay: u8 = 255,
    monstersKilled: u8 = 0,
    stateMachine: ?@import("../states/stateMachine.zig").StateMachine,
    runes: ?std.ArrayList(*Rune),
    rescued: ?std.ArrayList(enums.Rescues),
    killed: ?std.ArrayList(enums.Rescues),

    pub fn reset(self: *@This(), state: *s.State) !void {
        self.pos = .{ .x = 0, .y = 0 };
        self.rotation = 180.0;
        self.equiped = false;
        self.alignment = .GOOD;
        self.blessed = false;
        self.durability = 100;
        self.gold = 0;
        self.maxSelectedDice = 3;
        self.maxDice = 6;

        if (self.dice != null) {
            for (0..self.dice.?.items.len) |i| {
                const die = self.dice.?.items[i];
                try die.deinit(state);
                state.allocator.destroy(die);
            }
            self.dice.?.clearAndFree();
        }

        if (self.runes != null) {
            for (0..self.runes.?.items.len) |i| {
                const rune = self.runes.?.items[i];
                state.allocator.destroy(rune);
            }
            self.dice.?.clearAndFree();
        }

        if (self.altarHistory != null) {
            self.altarHistory.?.clearAndFree();
        }

        if (self.messages != null) {
            self.messages.?.clearAndFree();
        }

        if (self.rescued != null) {
            self.rescued.?.clearAndFree();
        }
        if (self.killed != null) {
            self.killed.?.clearAndFree();
        }

        // Add initial player dice
        const topUI = state.grid.cells[state.grid.cells.len - 4][0].pos.y + @as(f32, @floatFromInt(state.grid.cellSize));

        var dcount: u8 = 0;
        const numd6: u8 = 2;
        const numd4: u8 = 1 + numd6;
        var xoffset: f32 = 50.0;
        const tooltip = "";
        while (dcount < numd6) : (dcount += 1) {
            xoffset = 50 * @as(f32, @floatFromInt(dcount));
            var d6 = try state.allocator.create(BasicDie);
            d6.name = "Basic d6";
            d6.sides = 6;
            d6.sellPrice = 2;
            d6.texture = state.textureMap.get(.D6);
            d6.hovered = false;
            d6.selected = false;
            d6.broken = false;
            d6.breakChance = 0;
            d6.nextResult = 0;
            d6.index = dcount;
            d6.tooltip = tooltip;
            d6.pos = .{
                .x = state.grid.getWidth() - 550 + xoffset,
                .y = topUI + 10,
            };
            const d6die = try d6.die(&state.allocator);

            try self.dice.?.append(d6die);
        }
        xoffset += 50;
        while (dcount < numd4) : (dcount += 1) {
            xoffset = 50 * @as(f32, @floatFromInt(dcount));
            var d4 = try state.allocator.create(MultDie);
            d4.name = "Mult d4";
            d4.sides = 4;
            d4.sellPrice = 4;
            d4.texture = state.textureMap.get(.D4);
            d4.hovered = false;
            d4.selected = false;
            d4.broken = false;
            d4.breakChance = 50;
            d4.nextResult = 0;
            d4.index = dcount;
            d4.tooltip = tooltip;
            d4.pos = .{
                .x = state.grid.getWidth() - 550 + xoffset,
                .y = topUI + 10,
            };
            const d4die = try d4.die(&state.allocator);

            try self.dice.?.append(d4die);
        }
    }

    pub fn deinit(self: *@This(), state: *s.State) !void {
        std.debug.print("PLAYER DEINIT\n\n", .{});
        if (self.altarHistory) |altarHistory| {
            altarHistory.deinit();
        }
        if (self.dice) |dice| {
            for (0..dice.items.len) |i| {
                try dice.items[i].deinit(state);
                state.allocator.destroy(dice.items[i]);
            }
            dice.deinit();
        }

        if (self.messages != null) {
            for (0..self.messages.?.items.len) |i| {
                std.debug.print("Freeing player message {s}\n", .{self.messages.?.items[i]});
                state.allocator.free(self.messages.?.items[i]);
            }
            self.messages.?.deinit();
        }
        if (self.runes) |runes| {
            for (0..runes.items.len) |i| {
                var rune = runes.items[i];
                try rune.deinit(state);
            }
            runes.deinit();
        }
        if (self.rescued != null) {
            self.rescued.?.deinit();
        }
        if (self.killed != null) {
            self.killed.?.deinit();
        }
        std.debug.print("PLAYER DEINIT DONE\n", .{});
    }

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
                try die.setSelected(false);
                if (rollResults.items.len == 1) {
                    // check for dawn rune
                    if (self.runes != null and self.runes.?.items.len > 0) {
                        const runesList: []*Rune = self.runes.?.items;
                        for (0..runesList.len) |u| {
                            var r = runesList[u];
                            if (std.mem.eql(u8, try r.getName(), "Dawn")) {
                                try r.handle(state, &rollResults);
                                std.debug.print("Rune {s} activated for first die \n", .{try r.getName()});
                            }
                        }
                    }
                }
            }
        }

        if (self.runes != null and self.runes.?.items.len > 0) {
            // Handle runes
            const runesList: []*Rune = self.runes.?.items;
            for (0..runesList.len) |i| {
                var r = runesList[i];
                if (!std.mem.eql(u8, try r.getName(), "Dawn")) {
                    try r.handle(state, &rollResults);
                    std.debug.print("Rune {s} activated \n", .{try r.getName()});
                }
            }
        }

        var result: u32 = 0;
        if (rollResults.items.len > 0) {
            result = rollResults.items[rollResults.items.len - 1].num;
        }
        std.debug.print("Final Roll result: {d} from {d} dice\n", .{ result, rollResults.items.len });

        // clean up broken dice
        var i = self.dice.?.items.len;
        // Update new list with remaining dice that are not being removed.
        var newDice = std.ArrayList(*d.Die).init(state.allocator);

        var removedCount: i32 = 0;
        while (i > 0) {
            i -= 1;
            if (try self.dice.?.items[i].getBroken()) {
                removedCount += 1;
                const removedDie: *d.Die = dice.?.orderedRemove(i);
                try removedDie.deinit(state);
                state.allocator.destroy(removedDie);
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
            const st = try std.fmt.allocPrintZ(state.allocator, "{d}", .{damageScaled});
            try monster.messages.?.append(st);
        }
    }

    pub fn addDie(self: *@This(), die: *d.Die) !void {
        if (self.dice == null) {
            std.debug.assert(false);
        }

        try self.dice.?.append(die);
    }

    pub fn purchaseItem(self: *@This(), shopItem: shop.ShopItem, state: *s.State) !bool {
        if (self.dice == null) {
            std.debug.assert(false);
            return false;
        }
        if (self.gold < shopItem.price) {
            try state.messages.?.append("Not enough gold");
            return false;
        }
        if (shopItem.die != null) {
            if (self.dice.?.items.len >= self.maxDice) {
                try state.messages.?.append("No room");
                return false;
            }

            try self.dice.?.append(shopItem.die.?);
            self.gold -= shopItem.price;
        }
        if (shopItem.healthPotion != null and state.adventurer.health < 100) {
            // TODO: Add consumable inventory
            // Health potion is a consumable item.
            if (state.adventurer.health + shopItem.healthPotion.?.healAmount >= 100) {
                state.adventurer.health = 100;
            } else {
                state.adventurer.health += shopItem.healthPotion.?.healAmount;
            }
        }
        return true;
    }

    pub fn sellSelectedDice(self: *@This(), state: *s.State) !bool {
        if (self.dice == null) {
            return false;
        }
        for (0..self.dice.?.items.len) |i| {
            var die = self.dice.?.items[i];
            if (!try die.getSelected() and !try die.getSold()) {
                continue;
            }

            std.debug.print("Selling die {s} for {d}gp\n", .{ try die.getName(), try die.getSellPrice() });
            self.gold += try die.getSellPrice();
            try die.setSold(true);
        }

        var i = self.dice.?.items.len;

        // Remove sold dice.
        while (i > 0) {
            i -= 1;
            if (try self.dice.?.items[i].getSold()) {
                const removedDie: *d.Die = self.dice.?.orderedRemove(i);
                try removedDie.deinit(state);
                state.allocator.destroy(removedDie);
            }
        }

        // Update index of dice.
        for (0..self.dice.?.items.len) |x| {
            try self.dice.?.items[x].setIndex(x);
            var dd = self.dice.?.items[x];
            try dd.update(state);
        }
        return true;
    }

    // Update based on actions player has taken.
    pub fn update(self: *@This(), state: *s.State) anyerror!void {
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

        if (self.runes != null and self.runes.?.items.len > 0) {
            // Handle runes
            const runesList: []*Rune = self.runes.?.items;
            for (0..runesList.len) |i| {
                var r = runesList[i];
                try r.handle(state, null);
            }
        }

        if (self.messages == null) {
            std.debug.print("Player update. Messages == null\n", .{});
            std.debug.assert(false);
        }

        const playerMessageDisplayed = self.displayMessages(
            self.playerMsgDecay,
            rl.getFrameTime() * @as(f32, @floatFromInt(self.playerMsgDecay)),
            state,
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

    pub fn displayMessages(self: *@This(), decay: u8, dt: f32, state: *s.State) bool {
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
            const displayedMessage = self.messages.?.pop();
            state.allocator.free(displayedMessage.?);
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
