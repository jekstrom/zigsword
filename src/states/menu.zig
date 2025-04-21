const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const sm = @import("smState.zig");
const concatStrings = @import("../stringutils.zig").concatStrings;

// Tracks behavior in the main menu
pub const MenuState = struct {
    nextState: ?*sm.SMState,
    startTime: f64,
    isComplete: bool,

    pub fn getIsComplete(ptr: *anyopaque) anyerror!bool {
        const self: *MenuState = @ptrCast(@alignCast(ptr));
        return self.isComplete;
    }

    pub fn enter(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *MenuState = @ptrCast(@alignCast(ptr));
        self.startTime = rl.getTime();
        _ = state;
    }

    pub fn exit(ptr: *anyopaque, state: *s.State) anyerror!void {
        _ = ptr;
        _ = state;
    }

    pub fn update(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *MenuState = @ptrCast(@alignCast(ptr));
        const center = state.grid.getCenterPos();

        rl.drawTexturePro(
            state.textureMap.get(.MENUBACKGROUND).?,
            .{
                .x = 0,
                .y = 0,
                .width = 2011,
                .height = 2008,
            },
            .{
                .x = 0,
                .y = 0,
                .width = state.grid.getWidth() - 10,
                .height = state.grid.getHeight() - 10,
            },
            .{ .x = 0, .y = 0 },
            0.0,
            .white,
        );

        if (ui.guiButton(.{ .x = center.x - 40, .y = center.y, .height = 40, .width = 100 }, "Start") > 0) {
            std.debug.print("Menu start: {}\n", .{self.isComplete});
            self.isComplete = true;
        }
    }

    pub fn smState(self: *MenuState, allocator: *const std.mem.Allocator) !*sm.SMState {
        return try sm.SMState.init(self, .MENU, self.nextState, allocator);
    }
};
