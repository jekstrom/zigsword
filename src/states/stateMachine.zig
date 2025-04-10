const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("../objects/state.zig");
const sm = @import("smState.zig");

// State Machine tracks the transition between states
pub const StateMachine = struct {
    state: ?*sm.SMState,
    allocator: *const std.mem.Allocator,

    pub fn setState(self: *@This(), newState: *sm.SMState, state: *s.State) anyerror!void {
        if (self.state == null or self.state.?.smType != newState.smType) {
            if (self.state != null) {
                try self.state.?.exit(state);
            }
            self.state = newState;
            // try self.state.update(state);
            try self.state.?.enter(state);
        }
    }

    pub fn clearState(self: *@This()) anyerror!void {
        self.allocator.destroy(self.state.?);
        self.state = null;
    }
};
