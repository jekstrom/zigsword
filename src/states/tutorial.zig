const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const sm = @import("smState.zig");
const concatStrings = @import("../stringutils.zig").concatStrings;

// Tracks behavior in the starting state
pub const TutorialState = struct {
    nextState: ?*sm.SMState,
    tutorialStep: *u4,
    startTime: f64,
    isComplete: bool,

    pub fn getIsComplete(ptr: *anyopaque) anyerror!bool {
        const self: *TutorialState = @ptrCast(@alignCast(ptr));
        return self.isComplete;
    }

    pub fn enter(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *TutorialState = @ptrCast(@alignCast(ptr));
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
        const self: *TutorialState = @ptrCast(@alignCast(ptr));
        const waitSeconds: f64 = 2.0;

        if (self.tutorialStep.* >= 4 and rl.getTime() - self.startTime > waitSeconds and state.adventurer.exit(state)) {
            self.isComplete = true;
        }

        const entered = state.adventurer.enter(state, rl.getFrameTime());

        // TODO: Redo phases..
        if (entered and state.phase == .START) {
            const messageRect: rl.Rectangle = .{
                .height = 200,
                .width = 500,
                .x = (state.grid.getWidth() - 500) / 2,
                .y = (state.grid.getHeight() - state.grid.getGroundY()) / 2,
            };

            if (self.tutorialStep.* == 0) {
                if (ui.guiMessageBox(
                    messageRect,
                    "YOU",
                    "Greetings Adventurer!",
                    "next",
                ) > 0) {
                    self.tutorialStep.* = 1;
                    return;
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

            if (self.tutorialStep.* == 1) {
                const messageRect2: rl.Rectangle = .{
                    .height = 200,
                    .width = 500,
                    .x = (state.grid.getWidth() - 500) / 2,
                    .y = (state.grid.getHeight() - state.grid.getGroundY()) / 2,
                };
                if (ui.guiTextInputBox(
                    messageRect2,
                    "ADVENTURER",
                    "Woah, a talking sword! What do they call you?",
                    "next",
                    state.newName,
                    10,
                    null,
                ) > 0) {
                    state.player.name = state.newName;
                    self.tutorialStep.* = 2;
                    return;
                }

                state.adventurer.drawPortrait(
                    state,
                    .{
                        .height = 60,
                        .width = 60,
                        .x = messageRect.x + 10,
                        .y = messageRect.y + 30,
                    },
                );
            }

            if (self.tutorialStep.* == 2) {
                var buffer: [13 + 10:0]u8 = std.mem.zeroes([13 + 10:0]u8);
                _ = std.fmt.bufPrint(
                    &buffer,
                    "They call me {s}.",
                    .{state.player.name},
                ) catch "";

                if (ui.guiMessageBox(
                    messageRect,
                    state.player.name,
                    &buffer,
                    "next",
                ) > 0) {
                    self.tutorialStep.* = 3;
                    return;
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

            if (self.tutorialStep.* == 3) {
                const sx = try concatStrings(
                    state.allocator,
                    state.player.name,
                    "? stange name for a sword. Let's go!",
                );
                defer state.allocator.free(sx);
                if (ui.guiMessageBox(
                    messageRect,
                    "ADVENTURER",
                    sx,
                    "next",
                ) > 0) {
                    self.tutorialStep.* = 4;
                    return;
                }
                state.adventurer.drawPortrait(
                    state,
                    .{
                        .height = 60,
                        .width = 60,
                        .x = messageRect.x + 10,
                        .y = messageRect.y + 30,
                    },
                );
            }
        }
    }

    pub fn smState(self: *TutorialState, allocator: *const std.mem.Allocator) !*sm.SMState {
        return try sm.SMState.init(self, .TUTORIAL, self.nextState, allocator);
    }
};
