const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const m = @import("../map/map.zig");
const g = @import("grid.zig");
const mob = @import("monster.zig");
const sm = @import("../states/smState.zig");
const WalkingState = @import("../states/walking.zig").WalkingState;
const BattleState = @import("../states/battle.zig").BattleState;
const ShopState = @import("../states/shop.zig").ShopState;
const ShopItem = @import("shopitem.zig").ShopItem;

pub var DEBUG_MODE = false;

pub const State = struct {
    player: @import("player.zig").Player,
    adventurer: @import("adventurer.zig").Adventurer,
    newName: *[10:0]u8,
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
    messages: ?std.ArrayList([:0]const u8),
    stateMachine: ?*@import("../states/stateMachine.zig").StateMachine,
    stateMsgDecay: u8 = 255,

    pub fn goToNextMapNode(self: *@This()) !void {
        if (self.map) |map| {
            const numnodes = map.nodes.items.len;
            if ((self.currentNode + 1) >= numnodes) {
                self.currentNode = 0;
                std.debug.print("Resetting map node {d}\n", .{self.currentNode});
                try self.goToNextMap();
            } else {
                self.currentNode += 1;
                std.debug.print("Going to map node {d}\n", .{self.currentNode});
            }
        } else {
            std.debug.print("no map found\n", .{});
            std.debug.assert(false);
        }
    }

    pub fn goToNextMap(self: *@This()) !void {
        if (self.map.?.nextMap) |nm| {
            self.map = nm.*;
            self.currentMap = self.map.?.currentMapCount;
            self.currentNode = 0;
            self.grid.clearTextures();
        } else {
            try self.generateNextMap("MORE DUNGEON", .DUNGEON);
            try self.generateNextMap("MORE BOSS", .BOSS);
            try self.generateNextMap("MORE SHOP", .SHOP);
            try self.goToNextMap();
        }
    }

    pub fn generateNextMap(self: *@This(), name: [:0]const u8, nodeType: m.MapNodeType) !void {
        // Generate a new map using seed from State.
        // Maps should all contain the same number of nodes but
        // what each node consists of should be random.

        const List = std.ArrayList(m.MapNode);
        const MonsterList = std.ArrayList(mob.Monster);
        const ShopItems = std.ArrayList(ShopItem);

        var numWalkingNodes = self.rand.intRangeAtMost(
            u4,
            2,
            4,
        );

        if (nodeType == .SHOP or nodeType == .BOSS) {
            numWalkingNodes = 1;
        }

        var newMap = try self.allocator.create(m.Map);

        newMap.currentMapCount = 1;
        newMap.name = name;
        newMap.nodes = List.init(self.allocator);
        newMap.nextMap = null;

        // TODO: Deallocate maps and nodes

        for (0..numWalkingNodes) |i| {
            // Create new nodes for the map, assigning a name.
            const baseName = "Map Node ";
            var floatLog: f16 = 1.0;
            if (i > 0) {
                floatLog = @floor(@log10(@as(f16, @floatFromInt(i))) + 1.0);
            }
            const digits: u64 = @as(u64, @intFromFloat(floatLog));
            const buffer = try self.allocator.allocSentinel(
                u8,
                baseName.len + digits,
                0,
            );
            _ = std.fmt.bufPrint(
                buffer,
                "{s}{d}",
                .{ baseName, i },
            ) catch "";

            if (nodeType == .WALKING) {
                var outsideNode: m.MapNode = .{
                    .name = buffer,
                    .type = nodeType,
                    .texture = self.textureMap.get(.OUTSIDEGROUND),
                    .background = self.textureMap.get(.OUTSIDEBACKGROUND),
                    .monstersEntered = false,
                    .monsters = null,
                    .event = null,
                    .shopItems = null,
                    .stateMachine = null,
                };
                try outsideNode.init(self);
                try newMap.addMapNode(outsideNode);
            } else if (nodeType == .DUNGEON) {
                var dungeonNode: m.MapNode = .{
                    .name = buffer,
                    .type = nodeType,
                    .texture = self.textureMap.get(.DUNGEONGROUND),
                    .background = self.textureMap.get(.DUNGEONBACKGROUND),
                    .monsters = MonsterList.init(self.allocator),
                    .monstersEntered = false,
                    .event = null,
                    .shopItems = null,
                    .stateMachine = null,
                };
                try dungeonNode.init(self);
                try newMap.addMapNode(dungeonNode);
            } else if (nodeType == .BOSS) {
                var dungeonNode: m.MapNode = .{
                    .name = buffer,
                    .type = nodeType,
                    .texture = self.textureMap.get(.DUNGEONGROUND),
                    .background = self.textureMap.get(.DUNGEONBACKGROUND),
                    .monsters = MonsterList.init(self.allocator),
                    .monstersEntered = false,
                    .event = null,
                    .shopItems = null,
                    .stateMachine = null,
                };
                try dungeonNode.init(self);
                try newMap.addMapNode(dungeonNode);
            } else if (nodeType == .SHOP) {
                var shopNode: m.MapNode = .{
                    .name = buffer,
                    .type = nodeType,
                    .texture = self.textureMap.get(.DUNGEONGROUND),
                    .background = self.textureMap.get(.SHOPBACKGROUND),
                    .monstersEntered = false,
                    .monsters = null,
                    .event = null,
                    .shopItems = ShopItems.init(self.allocator),
                    .stateMachine = null,
                };
                try shopNode.init(self);
                try newMap.addMapNode(shopNode);
            }
        }

        if (self.map) |_| {
            // try state.map.?.addMap(state, "", newMap.nodes);
            var currentMap: ?*m.Map = &self.map.?;
            while (currentMap != null) {
                newMap.currentMapCount = currentMap.?.currentMapCount + 1;
                std.debug.print("Current map: {s}\n", .{currentMap.?.name});
                if (currentMap.?.nextMap == null) {
                    std.debug.print("next map null\n", .{});
                    break;
                } else {
                    currentMap = currentMap.?.nextMap;
                    std.debug.print("next map: {s}\n", .{currentMap.?.name});
                }
            }
            std.debug.print("Adding next map {s} as child to {s}\n", .{ newMap.name, currentMap.?.name });

            currentMap.?.nextMap = newMap;
        } else {
            newMap.currentMapCount = 1;
            self.map = newMap.*;
        }
    }

    pub fn displayMessages(self: *@This(), decay: u8) bool {
        if (self.messages == null or self.messages.?.items.len == 0) {
            return false;
        }
        const last = self.messages.?.items.len - 1;
        const msg = self.messages.?.items[last];
        if (decay > 0) {
            rl.drawText(
                msg,
                @as(i32, @intFromFloat(self.grid.getCenterPos().x - 50)),
                @as(i32, @intFromFloat(self.grid.getCenterPos().y - 350)),
                20,
                rl.Color.init(255, 255, 255, decay),
            );
            return true;
        }
        if (decay == 0) {
            std.debug.print("Done displaying {s}\n", .{msg});
            _ = self.messages.?.pop();
            return false;
        }
        return false;
    }

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
        // TODO: Better way to handle battle turns?
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

    pub fn drawCurrentMapNode(self: *@This(), dt: f32) !void {
        if (self.map) |map| {
            try map.nodes.items[self.currentNode].draw(self, dt);
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

    pub fn isShop(self: *@This()) !bool {
        const currentMapNode = try self.getCurrentMapNode();
        if (currentMapNode) |cn| {
            return cn.type == .SHOP;
        }
        return false;
    }

    pub fn getConsistentRandomNumber(self: *@This(), row: usize, col: usize, lowerBound: u16, upperBound: u16) u16 {
        const num = self.randomNumbers[row][col];
        const normalized = @as(f32, @floatFromInt(num)) / 65535.0;
        const scaled: f32 = @as(f32, @floatFromInt(lowerBound)) + (normalized * (@as(f32, @floatFromInt(upperBound)) - @as(f32, @floatFromInt(lowerBound))));
        return @as(u16, @intFromFloat(@round(scaled)));
    }

    pub fn update(self: *@This()) !void {
        if (self.stateMachine != null and self.stateMachine.?.state != null and try self.stateMachine.?.state.?.getIsComplete()) {
            // do state transition
            std.debug.print("STATE COMPLETE\n\n", .{});
            const curState = self.stateMachine.?.state.?;
            const nextState: ?*@import("../states/smState.zig").SMState = curState.nextState;
            if (nextState != null) {
                try self.stateMachine.?.setState(nextState.?, self);
            } else if (curState.smType != .TUTORIAL) {
                try self.stateMachine.?.clearState();
                std.debug.print("TRANSITION FROM WALKING\n\n", .{});
                // Next state is null and current state is WALKING, go to next map node.
                try self.goToNextMapNode();
                const monster = try self.getMonster();
                var nextSmState: ?*sm.SMState = null;
                if (monster != null) {
                    var battleState = try self.allocator.create(BattleState);
                    battleState.nextState = null;
                    battleState.isComplete = false;
                    battleState.startTime = rl.getTime();

                    const battleSmState = try battleState.smState(&self.allocator);
                    nextSmState = battleSmState;
                } else if (try self.isShop()) {
                    var shopState = try self.allocator.create(ShopState);
                    shopState.nextState = null;
                    shopState.isComplete = false;
                    shopState.startTime = rl.getTime();

                    const shopSmState = try shopState.smState(&self.allocator);
                    nextSmState = shopSmState;
                } else {
                    var walkingState = try self.allocator.create(WalkingState);
                    walkingState.nextState = null;
                    walkingState.isComplete = false;
                    walkingState.startTime = rl.getTime();
                    const walkingSmState = try walkingState.smState(&self.allocator);
                    nextSmState = walkingSmState;
                }

                if (nextSmState) |ns| {
                    try self.stateMachine.?.setState(ns, self);
                } else {
                    // There should always be a next state to transition to.
                    std.debug.print("No next state found!\n", .{});
                    std.debug.assert(false);
                }
            } else if (curState.smType == .TUTORIAL) {
                // Handle initial walking state
                var walkingState = try self.allocator.create(WalkingState);
                walkingState.nextState = null;
                walkingState.isComplete = false;
                walkingState.startTime = rl.getTime();

                const walkingSmState = try walkingState.smState(&self.allocator);
                try self.stateMachine.?.setState(walkingSmState, self);
            }
        }

        if (self.stateMachine != null and self.stateMachine.?.state != null) {
            try self.stateMachine.?.state.?.update(self);
        }

        const messageDisplayed = self.displayMessages(self.stateMsgDecay);
        if (self.stateMsgDecay == 0) {
            self.stateMsgDecay = 255;
        }

        if (messageDisplayed) {
            const ddiff = @as(u8, @intFromFloat(rl.math.clamp(170 * rl.getFrameTime(), 0, 255)));
            const rs = @subWithOverflow(self.stateMsgDecay, ddiff);
            if (rs[1] != 0) {
                self.stateMsgDecay = 0;
            } else {
                self.stateMsgDecay -= ddiff;
            }
        }
    }
};
