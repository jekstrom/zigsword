const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");

pub var DEBUG_MODE = false;

pub const State = struct {
    player: @import("player.zig").Player,
    adventurer: @import("adventurer.zig").Adventurer,
    grid: @import("grid.zig").Grid,
    mousePos: rl.Vector2,
    textureMap: std.AutoHashMap(enums.TextureType, rl.Texture),
    phase: enums.GamePhase,
    mode: enums.GameMode,

    pub fn NextPhase(self: @This()) enums.GamePhase {
        var nextPhase: enums.GamePhase = .START;
        if (self.phase == .START) {
            nextPhase = .PLAY;
        } else if (self.phase == .PLAY) {
            nextPhase = .DEATH;
        } else if (self.phase == .DEATH) {
            nextPhase = .END;
        }
        std.debug.print("Transitioning from phase {} to {}\n", .{ self.phase, nextPhase });
        return nextPhase;
    }
};
