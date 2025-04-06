const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const e = @import("../walkingevent.zig");
const enums = @import("../enums.zig");

// This is an event that can occur while in the walking mode.
pub const AlterWalkingEvent = struct {
    baseEvent: e.WalkingEvent,
    alignment: enums.Alignment,

    pub fn draw(self: @This(), state: *s.State) void {
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
                    .x = self.baseEvent.pos.x,
                    .y = self.baseEvent.pos.y,
                    .width = 128,
                    .height = 128,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }
    }

    pub fn handle(self: *@This(), state: *s.State) !void {
        if (self.baseEvent.handled) {
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
            self.baseEvent.name,
            "You encounter an altar to $DEITY",
            "next;dip;pray",
        );
        if (result == 0) {
            std.debug.print("{s} x\n", .{self.baseEvent.name});
            self.baseEvent.handled = true;
            return;
        }
        if (result == 1) {
            std.debug.print("{s} next\n", .{self.baseEvent.name});
            self.baseEvent.handled = true;
        }
        if (result == 2) {
            const success = self.alignment == state.player.alignment;
            try state.player.altarHistory.?.append(.{
                .name = self.baseEvent.name,
                .success = success,
            });

            std.debug.print("{s} dip\n", .{self.baseEvent.name});
            self.baseEvent.handled = true;
        }
        if (result == 3) {
            std.debug.print("{s} pray\n", .{self.baseEvent.name});
            self.baseEvent.handled = true;
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
};
