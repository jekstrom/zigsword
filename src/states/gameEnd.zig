const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const sm = @import("smState.zig");
const Rune = @import("../runes/rune.zig").Rune;
const concatStrings = @import("../stringutils.zig").concatStrings;

// Game End state, shows what has happened this run handles any unlocks
pub const GameEndState = struct {
    nextState: ?*sm.SMState,
    startTime: f64,
    isComplete: bool,

    pub fn getIsComplete(ptr: *anyopaque) anyerror!bool {
        const self: *GameEndState = @ptrCast(@alignCast(ptr));
        return self.isComplete;
    }

    pub fn enter(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *GameEndState = @ptrCast(@alignCast(ptr));
        self.startTime = rl.getTime();

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
        const self: *GameEndState = @ptrCast(@alignCast(ptr));
        _ = self;
        _ = state;
    }

    pub fn showGameEndDialog(self: *@This(), state: *s.state) void {
        _ = self;
        _ = state;
        // Get the list of things that happened this game from state
        // Calculate score?
        // Display leaderboard (local)
        // Show unlocks
        // achievements this run ?
    }

    pub fn smState(self: *GameEndState, allocator: *const std.mem.Allocator) !*sm.SMState {
        return try sm.SMState.init(self, .GAMEEND, self.nextState, allocator);
    }
};
