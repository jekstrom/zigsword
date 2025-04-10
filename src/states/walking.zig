const rl = @import("raylib");
const std = @import("std");
const s = @import("../objects/state.zig");
const sm = @import("smState.zig");

// Tracks behavior in the battle state
pub const WalkingState = struct {
    nextState: ?*sm.SMState,
    startTime: f64,
    isComplete: bool = false,
    doExit: bool = false,

    pub fn getIsComplete(ptr: *anyopaque) anyerror!bool {
        const self: *WalkingState = @ptrCast(@alignCast(ptr));
        return self.isComplete;
    }

    pub fn enter(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *WalkingState = @ptrCast(@alignCast(ptr));
        self.startTime = rl.getTime();

        // Set starting position for the adventurer
        state.adventurer.pos = .{
            .x = -100,
            .y = state.grid.getGroundY() - 110,
        };
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
        const entered = state.adventurer.enter(state, rl.getFrameTime());

        if (self.doExit and curTime - self.startTime > waitSeconds and state.adventurer.exit(state)) {
            self.isComplete = true;
        }
        if (!self.doExit and entered and curTime - self.startTime > waitSeconds) {
            if (currentMapNode) |cn| {
                if (cn.altarEvent != null) {
                    try cn.altarEvent.?.handle(state);
                    if (cn.altarEvent.?.baseEvent.handled and (curTime - self.startTime) > waitSeconds) {
                        // Reset the clock to give time to finish the altar event
                        self.startTime = rl.getTime();
                        self.doExit = true;
                    }
                } else if ((curTime - self.startTime) > waitSeconds) {
                    self.doExit = true;
                }
                // handle other events during walking
            } else {
                std.debug.print("No map node in walking event\n", .{});
                std.debug.assert(false);
            }
        }
    }

    pub fn smState(self: *WalkingState, allocator: *const std.mem.Allocator) !*sm.SMState {
        return try sm.SMState.init(self, .WALKING, self.nextState, allocator);
    }
};
