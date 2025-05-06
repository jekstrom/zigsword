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
        if (self.state != null) {
            try self.state.?.exit(state);
            try self.clearState();
        }
        self.state = newState;
        std.debug.print("Entering state: {*}\n", .{newState});
        try self.state.?.enter(state);
    }

    pub fn clearState(self: *@This()) anyerror!void {
        if (self.state != null) {
            std.debug.print("CLEAR STATE {*}{}\n", .{ self.state.?, self.state.?.smType });
            self.allocator.destroy(self.state.?);
            self.state = null;
        }
    }
};
