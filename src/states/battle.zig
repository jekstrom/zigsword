const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const sm = @import("smState.zig");
const Rune = @import("../runes/rune.zig").Rune;
const concatStrings = @import("../stringutils.zig").concatStrings;

// Tracks behavior in the battle state
pub const BattleState = struct {
    nextState: ?*sm.SMState,
    startTime: f64,
    isComplete: bool,
    lootHandled: bool,

    pub fn getIsComplete(ptr: *anyopaque) anyerror!bool {
        const self: *BattleState = @ptrCast(@alignCast(ptr));
        return self.isComplete;
    }

    pub fn enter(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *BattleState = @ptrCast(@alignCast(ptr));
        _ = self;

        state.turn = .MONSTER;

        // Set starting position for the adventurer
        state.adventurer.pos = .{
            .x = -100,
            .y = state.grid.getGroundY() - 110,
        };
    }

    pub fn exit(ptr: *anyopaque, state: *s.State) anyerror!void {
        _ = state;
        _ = ptr;
    }

    pub fn update(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *BattleState = @ptrCast(@alignCast(ptr));
        const currentMapNode = try state.getCurrentMapNode();
        const waitSeconds: f64 = 2.0;
        const entered = state.adventurer.enter(state, rl.getFrameTime());

        if (entered and rl.getTime() - self.startTime > waitSeconds) {
            if (currentMapNode) |cn| {
                if (cn.monsters != null and cn.monsters.?.items.len > 0) {
                    const monster = try state.getMonster();
                    if (monster != null and !monster.?.dying) {
                        if (state.turn == .MONSTER) {
                            std.debug.print("Monster turn {s}\n", .{monster.?.name});
                            try monster.?.attack(state);
                            // TODO: handle turns better
                            self.startTime = rl.getTime();
                            state.NextTurn();
                        } else if (state.turn == .PLAYER and state.player.dice != null and state.player.dice.?.items.len > 0) {
                            if (ui.guiButton(.{ .x = 160, .y = 150, .height = 45, .width = 100 }, "Attack") > 0) {
                                try state.player.attack(state, monster.?);
                                self.startTime = rl.getTime();
                                state.NextTurn();
                            }
                        } else {
                            // TODO: Handle other turns for Environment and Adventurer
                            state.NextTurn();
                        }
                    } else if (!self.lootHandled) {
                        try self.showLootDialog(state);
                    } else if (self.lootHandled and state.adventurer.exit(state)) {
                        // No more monsters, we're done here.
                        // check for boss monster
                        // check for ascend boss
                        // if it is ascend boss, go to end screen

                        self.isComplete = true;
                    }
                }
            }
        }
    }

    pub fn showLootDialog(self: *@This(), state: *s.State) !void {
        const currentMapNode = try state.getCurrentMapNode();

        var totalGold: u8 = 0;
        var totalRunes = std.ArrayList(*Rune).init(state.allocator);
        defer totalRunes.deinit();

        if (currentMapNode) |cn| {
            for (0..cn.monsters.?.items.len) |i| {
                const monster = cn.monsters.?.items[i];
                const gold = monster.gold;
                totalGold += gold;
                const runes = monster.runes;

                if (runes != null and runes.?.items.len > 0) {
                    for (0..runes.?.items.len) |r| {
                        const rune: *Rune = runes.?.items[r];
                        try totalRunes.append(rune);
                    }
                }
            }
        }

        const center = state.grid.getCenterPos();
        const messageHeight = 200;
        const messageWidth = 500;

        const string = try std.fmt.allocPrintZ(state.allocator, " {d}gp", .{totalGold});
        defer state.allocator.free(string);

        const messageRect: rl.Rectangle = .{
            .height = messageHeight,
            .width = messageWidth,
            .x = center.x - (messageWidth / 2),
            .y = center.y - (messageHeight / 2),
        };
        const result = ui.guiMessageBox(
            messageRect,
            "Loot",
            string,
            "next;take",
        );

        for (0..totalRunes.items.len) |i| {
            var rune: *Rune = totalRunes.items[i];
            try rune.setPos(.{ .x = center.x - 60 + @as(f32, @floatFromInt(i * 50)), .y = center.y - (messageHeight / 2) + 30 });
            try rune.draw(state);
        }

        if (result == 0 or result == 1) {
            self.lootHandled = true;
            return;
        }
        if (result == 2) {
            std.debug.print("Adding {d} gold\n", .{totalGold});
            state.player.gold += totalGold;

            for (0..totalRunes.items.len) |i| {
                var rune = totalRunes.items[i];
                if (try rune.getSelected()) {
                    try rune.setSelected(false);
                    try rune.setPos(.{
                        .x = state.grid.getWidth() - 225.0 + @as(f32, @floatFromInt(i * 50)),
                        .y = state.grid.topUI() + 75.0,
                    });
                    state.currentSelectedRuneCount = 0;
                    try state.player.runes.?.append(rune);
                }
            }

            self.lootHandled = true;
            return;
        }

        state.player.drawPortrait(
            state,
            .{
                .height = 60,
                .width = 60,
                .x = messageRect.x + 10,
                .y = messageRect.y + 30,
            },
        );
    }

    pub fn smState(self: *BattleState, allocator: *const std.mem.Allocator) !*sm.SMState {
        return try sm.SMState.init(self, .BATTLE, self.nextState, allocator);
    }
};
