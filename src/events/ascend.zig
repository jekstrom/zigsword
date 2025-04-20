const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const enums = @import("../enums.zig");
const evt = @import("event.zig");

// This is an event that can occur while in the walking mode.
pub const AscendWalkingEvent = struct {
    name: [:0]const u8,
    eventType: evt.EventType,
    pos: rl.Vector2,
    handled: bool,

    pub fn getName(ptr: *anyopaque) anyerror![:0]const u8 {
        const self: *AscendWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.name;
    }

    pub fn getEventType(ptr: *anyopaque) anyerror!evt.EventType {
        const self: *AscendWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.eventType;
    }

    pub fn getPos(ptr: *anyopaque) anyerror!rl.Vector2 {
        const self: *AscendWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.pos;
    }

    pub fn getHandled(ptr: *anyopaque) anyerror!bool {
        const self: *AscendWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.handled;
    }

    pub fn draw(ptr: *anyopaque, state: *s.State) void {
        const self: *AscendWalkingEvent = @ptrCast(@alignCast(ptr));
        _ = state;
        _ = self;
    }

    pub fn handle(ptr: *anyopaque, state: *s.State) !void {
        const self: *AscendWalkingEvent = @ptrCast(@alignCast(ptr));
        if (self.handled) {
            return;
        }

        const center = state.grid.getCenterPos();
        const messageHeight = 200;
        const messageWidth = 500;

        const messageRect: rl.Rectangle = .{
            .height = messageHeight,
            .width = messageWidth,
            .x = center.x - (messageWidth / 2),
            .y = center.y - (messageHeight / 2),
        };

        if (state.player.runes.?.items.len >= 3) {
            const msg = "You have recovered enough memories to attempt to restore your past. To ascend, you will have to leave a tithe of all your gold. Would you like to ascend?";
            const result = ui.guiMessageBox(
                messageRect,
                "Ascend",
                msg,
                "no;yes",
            );
            if (result == 0 or result == 1) {
                self.handled = true;
                return;
            }
            if (result == 2) {
                //const lostGold = state.player.gold;
                // The player loses all their gold.
                // Depending on how much gold the player tithes, they get a buff.
                state.player.gold = 0;
                self.handled = true;
                // Go to boss fight.
                try state.generateNextMap("Ascend Boss", .ASCENDBOSS);
                return;
            }
        } else {
            const msg = "You lack the runes necessary to ascend.";
            const result = ui.guiMessageBox(
                messageRect,
                "Ascend",
                msg,
                "ok",
            );
            if (result == 0 or result == 1) {
                self.handled = true;
                return;
            }
        }

        state.player.drawPortrait(
            state,
            .{
                .height = 60,
                .width = 60,
                .x = messageRect.x + 10,
                .y = messageRect.y + 30,
            },
        );
        self.handled = false;
    }

    pub fn deinit(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *AscendWalkingEvent = @ptrCast(@alignCast(ptr));
        state.allocator.destroy(self);
    }

    pub fn event(self: *AscendWalkingEvent, allocator: *const std.mem.Allocator) !*evt.Event {
        return try evt.Event.init(
            self,
            self.name,
            self.eventType,
            self.pos,
            self.handled,
            allocator,
        );
    }
};
