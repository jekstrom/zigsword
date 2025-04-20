const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const enums = @import("../enums.zig");
const evt = @import("event.zig");

// This is an event that can occur while in the walking mode.
pub const AlterWalkingEvent = struct {
    name: [:0]const u8,
    eventType: evt.EventType,
    pos: rl.Vector2,
    handled: bool,
    alignment: enums.Alignment,

    pub fn getName(ptr: *anyopaque) anyerror![:0]const u8 {
        const self: *AlterWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.name;
    }

    pub fn getEventType(ptr: *anyopaque) anyerror!evt.EventType {
        const self: *AlterWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.eventType;
    }

    pub fn getPos(ptr: *anyopaque) anyerror!rl.Vector2 {
        const self: *AlterWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.pos;
    }

    pub fn getHandled(ptr: *anyopaque) anyerror!bool {
        const self: *AlterWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.handled;
    }

    pub fn draw(ptr: *anyopaque, state: *s.State) void {
        const self: *AlterWalkingEvent = @ptrCast(@alignCast(ptr));
        var texture = state.textureMap.get(.GOODALTAR);
        if (self.alignment == .EVIL) {
            texture = state.textureMap.get(.EVILALTAR);
        }

        if (texture) |t| {
            const textureOffsetRect: rl.Rectangle = .{
                .x = 0,
                .y = 0,
                .height = 128,
                .width = 128,
            };

            rl.drawTexturePro(
                t,
                textureOffsetRect,
                .{
                    .x = self.pos.x,
                    .y = self.pos.y,
                    .width = 128,
                    .height = 128,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }
    }

    pub fn handle(ptr: *anyopaque, state: *s.State) !void {
        const self: *AlterWalkingEvent = @ptrCast(@alignCast(ptr));
        if (self.handled) {
            return;
        }

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
            self.name,
            "You encounter an altar to $DEITY",
            "next;dip;pray",
        );
        if (result == 0) {
            std.debug.print("{s} x\n", .{self.name});
            self.handled = true;
            return;
        }
        if (result == 1) {
            std.debug.print("{s} next\n", .{self.name});
            self.handled = true;
        }
        if (result == 2) {
            const success = self.alignment == state.player.alignment;
            try state.player.altarHistory.?.append(.{
                .name = self.name,
                .success = success,
            });

            std.debug.print("{s} dip\n", .{self.name});
            self.handled = true;
        }
        if (result == 3) {
            std.debug.print("{s} pray\n", .{self.name});
            self.handled = true;
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
    }

    pub fn deinit(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *AlterWalkingEvent = @ptrCast(@alignCast(ptr));
        state.allocator.destroy(self);
    }

    pub fn event(self: *AlterWalkingEvent, allocator: *const std.mem.Allocator) !*evt.Event {
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
