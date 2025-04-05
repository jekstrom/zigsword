const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const m = @import("../map/map.zig");
const g = @import("grid.zig");

pub var DEBUG_MODE = false;

pub const State = struct {
    player: @import("player.zig").Player,
    adventurer: @import("adventurer.zig").Adventurer,
    grid: g.Grid,
    mousePos: rl.Vector2,
    textureMap: std.AutoHashMap(enums.TextureType, rl.Texture),
    phase: enums.GamePhase,
    mode: enums.GameMode,
    allocator: std.mem.Allocator,
    currentMap: u8,
    currentNode: u8,
    map: ?m.Map,
    rand: std.Random,
    randomNumbers: [g.Grid.numRows][g.Grid.numCols]u16,

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

    pub fn drawCurrentMapNode(self: *@This()) !void {
        if (self.map) |map| {
            try map.nodes.items[self.currentNode].draw(self);
        } else {
            std.debug.assert(false);
        }
    }

    pub fn getConsistentRandomNumber(self: *@This(), row: usize, col: usize, lowerBound: u16, upperBound: u16) u16 {
        const num = self.randomNumbers[row][col];
        const normalized = @as(f32, @floatFromInt(num)) / 65535.0;
        const scaled: f32 = @as(f32, @floatFromInt(lowerBound)) + (normalized * (@as(f32, @floatFromInt(upperBound)) - @as(f32, @floatFromInt(lowerBound))));

        return @as(u16, @intFromFloat(@round(scaled)));
    }
};
