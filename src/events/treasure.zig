const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const evt = @import("event.zig");

// This is an event that can occur while in the walking mode.
pub const TreasureWalkingEvent = struct {
    name: [:0]const u8,
    eventType: evt.EventType,
    pos: rl.Vector2,
    handled: bool,
    gold: i32 = 1,

    pub fn getName(ptr: *anyopaque) anyerror![:0]const u8 {
        const self: *TreasureWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.name;
    }

    pub fn getEventType(ptr: *anyopaque) anyerror!evt.EventType {
        const self: *TreasureWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.eventType;
    }

    pub fn getPos(ptr: *anyopaque) anyerror!rl.Vector2 {
        const self: *TreasureWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.pos;
    }

    pub fn getHandled(ptr: *anyopaque) anyerror!bool {
        const self: *TreasureWalkingEvent = @ptrCast(@alignCast(ptr));
        return self.handled;
    }

    pub fn draw(ptr: *anyopaque, state: *s.State) void {
        const self: *TreasureWalkingEvent = @ptrCast(@alignCast(ptr));
        const texture = state.textureMap.get(.TREASURECHEST);

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
        const self: *TreasureWalkingEvent = @ptrCast(@alignCast(ptr));
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
            "You find a treasure chest",
            "next;open",
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
            // TODO: Failure event - mimic battle?
            state.player.gold += self.gold;

            std.debug.print("{s} open\n", .{self.name});
            std.debug.print("Added {d} gold to player\n", .{self.gold});
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
        const self: *TreasureWalkingEvent = @ptrCast(@alignCast(ptr));
        state.allocator.destroy(self);
    }

    pub fn event(self: *TreasureWalkingEvent, allocator: *const std.mem.Allocator) !*evt.Event {
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
