const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const sm = @import("smState.zig");

// Tracks behavior in the battle state
pub const BattleState = struct {
    nextState: ?*sm.SMState,
    startTime: f64,
    isComplete: bool,

    pub fn getIsComplete(ptr: *anyopaque) anyerror!bool {
        const self: *BattleState = @ptrCast(@alignCast(ptr));
        return self.isComplete;
    }

    pub fn enter(ptr: *anyopaque, state: *s.State) anyerror!void {
        _ = state;
        const self: *BattleState = @ptrCast(@alignCast(ptr));
        self.startTime = rl.getTime();
    }

    pub fn exit(ptr: *anyopaque, state: *s.State) anyerror!void {
        _ = ptr;
        _ = state.adventurer.exit(state);
    }

    pub fn update(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *BattleState = @ptrCast(@alignCast(ptr));
        const currentMapNode = try state.getCurrentMapNode();
        const waitSeconds: f64 = 2.0;

        if (currentMapNode) |cn| {
            if (cn.monsters != null and cn.monsters.?.items.len > 0) {
                const monster = try state.getMonster();
                if (monster != null and !monster.?.dying) {
                    if (state.turn == .MONSTER) {
                        std.debug.print("Monster turn {s}\n", .{monster.?.name});
                        try monster.?.attack(state);
                        // TODO: handle turns better
                        state.NextTurn();
                    } else if (state.turn == .PLAYER) {
                        if (ui.guiButton(.{ .x = 160, .y = 150, .height = 45, .width = 100 }, "Attack") > 0) {
                            try state.player.attack(state, monster.?);
                            state.NextTurn();
                        }
                    } else if (@intFromEnum(state.turn) >= 4) {
                        // TODO Wait for a second before continuing
                        // if (rl.getTime() - turnWaitStart.* > turnWaitSeconds) {
                        //     state.NextTurn();
                        // }
                    } else {
                        state.NextTurn();
                    }
                }
            } else if (rl.getTime() - self.startTime > waitSeconds) {
                self.isComplete = true;
            }
        }
    }

    pub fn smState(self: *BattleState, allocator: *const std.mem.Allocator) !*sm.SMState {
        return try sm.SMState.init(self, .BATTLE, self.nextState, allocator);
    }
};
