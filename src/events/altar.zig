const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const e = @import("../walkingevent.zig");

// This is an event that can occur while in the walking mode.
pub const AlterWalkingEvent = struct {
    baseEvent: e.WalkingEvent,

    pub fn draw(self: @This()) void {
        rl.drawRectangle(
            @as(i32, @intFromFloat(self.baseEvent.pos.x)),
            @as(i32, @intFromFloat(self.baseEvent.pos.y)),
            150,
            150,
            .magenta,
        );
    }

    pub fn handle(self: @This(), state: *s.State) void {
        const center = state.grid.getCenterPos();
        const messageHeight = 200;
        const messageWidth = 500;

        const messageRect: rl.Rectangle = .{
            .height = messageHeight,
            .width = messageWidth,
            .x = center.x - (messageHeight / 2),
            .y = center.y - (messageWidth / 2),
        };
        const result = ui.guiMessageBox(
            messageRect,
            self.baseEvent.name,
            "You encounter an altar to $DEITY",
            "next;dip;pray",
        );
        if (result == 0) {
            std.debug.print("0", .{});
            return;
        }
        if (result == 1) {
            std.debug.print("1", .{});
        }
        if (result == 2) {
            std.debug.print("2", .{});
        }
        if (result == 3) {
            std.debug.print("3", .{});
        }

        state.player.drawPortrait(
            state,
            .{
                .height = 60,
                .width = 20,
                .x = messageRect.x + 10,
                .y = messageRect.y + 30,
            },
        );
    }
};
