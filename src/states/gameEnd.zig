const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const sm = @import("smState.zig");
const concatStrings = @import("../stringutils.zig").concatStrings;

// Game End state, shows what has happened this run handles any unlocks
pub const GameEndState = struct {
    nextState: ?*sm.SMState,
    startTime: f64,
    isComplete: bool,
    messageHandled: bool = false,

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
        const waitSeconds: f64 = 2.0;
        if (!self.messageHandled) {
            try self.showGameEndDialog(state);
        } else if (self.messageHandled and rl.getTime() - self.startTime > waitSeconds) {
            self.isComplete = true;
        }
    }

    pub fn showGameEndDialog(self: *@This(), state: *s.State) !void {
        // Get the list of things that happened this game from state
        // Calculate score?
        // Display leaderboard (local)
        // Show unlocks
        // achievements this run ?
        var string = std.ArrayList(u8).init(state.allocator);
        defer string.deinit();
        const st = try std.fmt.allocPrint(state.allocator, "{d} Kills", .{state.player.monstersKilled});
        defer state.allocator.free(st);
        try string.appendSlice(st);

        const center = state.grid.getCenterPos();
        const messageHeight = 200;
        const messageWidth = 500;

        const sresult = try state.allocator.allocSentinel(u8, string.items.len, 0);
        defer state.allocator.free(sresult);
        @memcpy(sresult.ptr[0..string.items.len], string.items.ptr[0..string.items.len]);

        const messageRect: rl.Rectangle = .{
            .height = messageHeight,
            .width = messageWidth,
            .x = center.x - (messageWidth / 2),
            .y = center.y - (messageHeight / 2),
        };
        const result = ui.guiMessageBox(
            messageRect,
            "Game Over",
            sresult,
            "done;",
        );

        if (result == 0 or result == 1) {
            self.messageHandled = true;
            return;
        }
    }

    pub fn smState(self: *GameEndState, allocator: *const std.mem.Allocator) !*sm.SMState {
        return try sm.SMState.init(self, .GAMEEND, self.nextState, allocator);
    }
};
