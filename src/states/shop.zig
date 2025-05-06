const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const sm = @import("smState.zig");

// Tracks behavior in the shopping state
pub const ShopState = struct {
    nextState: ?*sm.SMState,
    startTime: f64,
    isComplete: bool,

    pub fn getIsComplete(ptr: *anyopaque) anyerror!bool {
        const self: *ShopState = @ptrCast(@alignCast(ptr));
        return self.isComplete;
    }

    pub fn enter(ptr: *anyopaque, state: *s.State) anyerror!void {
        _ = state;
        const self: *ShopState = @ptrCast(@alignCast(ptr));
        _ = self;
    }

    pub fn exit(ptr: *anyopaque, state: *s.State) anyerror!void {
        _ = ptr;
        _ = state.adventurer.exit(state);
    }

    pub fn update(ptr: *anyopaque, state: *s.State) anyerror!void {
        _ = state;
        const self: *ShopState = @ptrCast(@alignCast(ptr));

        if (ui.guiButton(.{ .x = 160, .y = 150, .height = 45, .width = 100 }, "Exit Shop") > 0) {
            self.isComplete = true;
        }
    }

    pub fn smState(self: *ShopState, allocator: *const std.mem.Allocator) !*sm.SMState {
        return try sm.SMState.init(self, .SHOP, self.nextState, allocator);
    }
};
