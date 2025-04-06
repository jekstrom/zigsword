const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const m = @import("../map/map.zig");
const g = @import("grid.zig");
const mob = @import("monster.zig");

pub var DEBUG_MODE = false;

pub const State = struct {
    player: @import("player.zig").Player,
    adventurer: @import("adventurer.zig").Adventurer,
    grid: g.Grid,
    mousePos: rl.Vector2,
    textureMap: std.AutoHashMap(enums.TextureType, rl.Texture),
    phase: enums.GamePhase,
    mode: enums.GameMode,
    turn: enums.Turn,
    allocator: std.mem.Allocator,
    currentMap: u8,
    currentNode: u8,
    map: ?m.Map,
    rand: std.Random,
    // a static collection of numbers, one per cell, to use as consistent values between maps for each game
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

    pub fn NextTurn(self: *@This()) void {
        if (self.turn == .ENVIRONMENT) {
            self.turn = .MONSTER;
        } else if (self.turn == .MONSTER) {
            self.turn = .PLAYER;
        } else if (self.turn == .PLAYER) {
            self.turn = .ADVENTURER;
        } else if (self.turn == .ADVENTURER) {
            self.turn = .ENVIRONMENT;
        }
    }

    pub fn drawCurrentMapNode(self: *@This()) !void {
        if (self.map) |map| {
            try map.nodes.items[self.currentNode].draw(self);
        } else {
            std.debug.assert(false);
        }
    }

    pub fn getCurrentMapNode(self: *@This()) !?*m.MapNode {
        if (self.map) |map| {
            return &map.nodes.items[self.currentNode];
        } else {
            std.debug.assert(false);
        }
        return null;
    }

    pub fn getMonster(self: *@This()) !?*mob.Monster {
        const currentMapNode = try self.getCurrentMapNode();
        if (currentMapNode) |cn| {
            if (cn.monsters) |mobs| {
                if (mobs.items.len > 0) {
                    return &mobs.items[0];
                }
            }
        }
        return null;
    }

    pub fn getConsistentRandomNumber(self: *@This(), row: usize, col: usize, lowerBound: u16, upperBound: u16) u16 {
        const num = self.randomNumbers[row][col];
        const normalized = @as(f32, @floatFromInt(num)) / 65535.0;
        const scaled: f32 = @as(f32, @floatFromInt(lowerBound)) + (normalized * (@as(f32, @floatFromInt(upperBound)) - @as(f32, @floatFromInt(lowerBound))));
        return @as(u16, @intFromFloat(@round(scaled)));
    }
};
