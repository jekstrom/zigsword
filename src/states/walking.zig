const rl = @import("raylib");
const std = @import("std");
const s = @import("../objects/state.zig");
const sm = @import("smState.zig");

// Tracks behavior in the battle state
pub const WalkingState = struct {
    nextState: ?*sm.SMState,
    startTime: f64,
    isComplete: bool = false,

    pub fn getIsComplete(ptr: *anyopaque) anyerror!bool {
        const self: *WalkingState = @ptrCast(@alignCast(ptr));
        std.debug.print("WALKING {*} getIsComplete: {}\n", .{ self, self.isComplete });
        return self.isComplete;
    }

    pub fn enter(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *WalkingState = @ptrCast(@alignCast(ptr));
        self.startTime = rl.getTime();
        _ = state.adventurer.enter(state, rl.getFrameTime());
    }

    pub fn exit(ptr: *anyopaque, state: *s.State) anyerror!void {
        _ = ptr;
        _ = state;
    }

    pub fn update(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *WalkingState = @ptrCast(@alignCast(ptr));
        const currentMapNode = try state.getCurrentMapNode();
        const waitSeconds: f64 = 2.0;
        const curTime = rl.getTime();
        var doExit = false;
        std.debug.print("WALKING {*} update: {}\n", .{ self, self.isComplete });

        if (curTime - self.startTime > waitSeconds) {
            if (currentMapNode) |cn| {
                if (cn.monsters != null and cn.monsters.?.items.len > 0) {
                    // battle
                    // TODO: transition here?
                } else if (cn.altarEvent != null) {
                    try cn.altarEvent.?.handle(state);
                    if (cn.altarEvent.?.baseEvent.handled and (curTime - self.startTime) > waitSeconds) {
                        doExit = true;
                    }
                } else if ((curTime - self.startTime) > waitSeconds) {
                    doExit = true;
                }
                // handle other events during walking
            }
            if (doExit and state.adventurer.exit(state)) {
                std.debug.print("WALKING STATE IS COMPLETE\n", .{});
                self.isComplete = true;
            }
        }
    }

    pub fn smState(self: *WalkingState, allocator: *const std.mem.Allocator) !*sm.SMState {
        return try sm.SMState.init(self, .WALKING, self.nextState, allocator);
    }
};
