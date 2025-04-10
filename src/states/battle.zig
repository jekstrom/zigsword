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
        const self: *BattleState = @ptrCast(@alignCast(ptr));
        self.startTime = rl.getTime();

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
                        } else if (state.turn == .PLAYER) {
                            if (ui.guiButton(.{ .x = 160, .y = 150, .height = 45, .width = 100 }, "Attack") > 0) {
                                try state.player.attack(state, monster.?);
                                self.startTime = rl.getTime();
                                state.NextTurn();
                            }
                        } else {
                            self.startTime = rl.getTime();
                            state.NextTurn();
                        }
                    } else if (state.adventurer.exit(state)) {
                        // No more monsters, we're done here.
                        self.isComplete = true;
                    }
                }
            }
        }
    }

    pub fn smState(self: *BattleState, allocator: *const std.mem.Allocator) !*sm.SMState {
        return try sm.SMState.init(self, .BATTLE, self.nextState, allocator);
    }
};
