const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const m = @import("../map/map.zig");
const g = @import("grid.zig");
const mob = @import("monster.zig");
const sm = @import("../states/smState.zig");
const WalkingState = @import("../states/walking.zig").WalkingState;
const GameEndState = @import("../states/gameEnd.zig").GameEndState;
const BattleState = @import("../states/battle.zig").BattleState;
const ShopState = @import("../states/shop.zig").ShopState;
const MapMenuState = @import("../states/mapMenu.zig").MapMenuState;
const TutorialState = @import("../states/tutorial.zig").TutorialState;
const MenuState = @import("../states/menu.zig").MenuState;
const ShopItem = @import("shopitem.zig").ShopItem;
const ShopMap = @import("../map/shop.zig").ShopMap;

pub var DEBUG_MODE = false;

pub const State = struct {
    player: @import("player.zig").Player,
    adventurer: @import("adventurer.zig").Adventurer,
    newName: *[10:0]u8,
    grid: g.Grid,
    mousePos: rl.Vector2,
    textureMap: std.AutoHashMap(enums.TextureType, rl.Texture),
    font: rl.Font,
    phase: enums.GamePhase,
    mode: enums.GameMode,
    turn: enums.Turn,
    allocator: std.mem.Allocator,
    currentMap: u8,
    mapCount: u8,
    currentNode: u8,
    maxSelectedRunes: u8 = 1,
    currentSelectedRuneCount: u8 = 0,
    map: ?m.Map,
    rand: std.Random,
    // a static collection of numbers, one per cell, to use as consistent values between maps for each game
    randomNumbers: [g.Grid.numRows][g.Grid.numCols]u16,
    messages: ?std.ArrayList([:0]const u8),
    stateMachine: ?*@import("../states/stateMachine.zig").StateMachine,
    battleState: ?*BattleState = null,
    gameEndState: ?*GameEndState = null,
    mapMenuState: ?*MapMenuState = null,
    shopState: ?*ShopState = null,
    walkingState: ?*WalkingState = null,
    tutorialState: ?*TutorialState = null,
    menuState: ?*MenuState = null,
    stateMsgDecay: u8 = 255,
    tutorialStep: u4 = 0,
    selectedMap: u8,
    mapMenuInputActive: bool,

    pub fn reset(self: *@This()) !void {
        // Reset after game end.
        std.debug.print("Reset game\n", .{});
        self.phase = .START;
        self.mode = .NONE;
        self.turn = .ENVIRONMENT;
        self.currentMap = 0;
        self.currentNode = 0;
        self.mapCount = 0;

        self.tutorialStep = 0;

        for (0..self.newName.len) |i| {
            self.newName[i] = 0;
        }

        if (self.map != null) {
            try self.map.?.deinitAll(self);
        }
        self.map = null;

        if (self.battleState != null) {
            self.allocator.destroy(self.battleState.?);
        }
        if (self.gameEndState != null) {
            self.allocator.destroy(self.gameEndState.?);
        }
        if (self.mapMenuState != null) {
            self.allocator.destroy(self.mapMenuState.?);
        }
        if (self.shopState != null) {
            self.allocator.destroy(self.shopState.?);
        }
        if (self.walkingState != null) {
            self.allocator.destroy(self.walkingState.?);
        }
        if (self.tutorialState != null) {
            self.allocator.destroy(self.tutorialState.?);
        }
        if (self.menuState != null) {
            self.allocator.destroy(self.menuState.?);
        }
        self.battleState = try self.allocator.create(BattleState);
        self.gameEndState = try self.allocator.create(GameEndState);
        self.mapMenuState = try self.allocator.create(MapMenuState);
        self.shopState = try self.allocator.create(ShopState);
        self.walkingState = try self.allocator.create(WalkingState);
        self.tutorialState = try self.allocator.create(TutorialState);
        self.menuState = try self.allocator.create(MenuState);

        try self.resetStates();

        try self.stateMachine.?.clearState();

        // TODO: Player selection screen
        try self.player.reset(self);

        const st = try std.fmt.allocPrintZ(self.allocator, "Start", .{});
        try self.generateNextMap(st, .WALKING);
        try self.generateRandomMaps();

        // TODO: Generate a new random adventurer.
        self.adventurer.reset(self);

        // Start with Tutorial state after reset
        const tutorialSmState: *sm.SMState = try self.tutorialState.?.smState(&self.allocator);

        var menuSmState: *sm.SMState = try self.menuState.?.smState(&self.allocator);
        std.debug.print("*******Setting next state to {*}\n\n", .{tutorialSmState});
        menuSmState.nextState = tutorialSmState;
        try self.stateMachine.?.setState(menuSmState, self);
    }

    fn resetStates(self: *@This()) !void {
        self.battleState.?.isComplete = false;
        self.battleState.?.lootHandled = false;
        self.battleState.?.nextState = null;

        self.gameEndState.?.isComplete = false;
        self.gameEndState.?.messageHandled = false;
        self.gameEndState.?.nextState = null;

        self.mapMenuState.?.isComplete = false;
        self.mapMenuState.?.nextState = null;

        self.shopState.?.isComplete = false;
        self.shopState.?.nextState = null;

        self.walkingState.?.isComplete = false;
        self.walkingState.?.doExit = false;
        self.walkingState.?.nextState = null;

        self.tutorialState.?.isComplete = false;
        self.tutorialState.?.tutorialStep = &self.tutorialStep;
        self.tutorialState.?.nextState = null;

        self.menuState.?.isComplete = false;
        self.menuState.?.nextState = null;
    }

    pub fn deinit(self: *@This()) void {
        std.debug.print("State DEINIT\n", .{});
        self.allocator.destroy(self.battleState.?);
        self.allocator.destroy(self.gameEndState.?);
        self.allocator.destroy(self.mapMenuState.?);
        self.allocator.destroy(self.shopState.?);
        self.allocator.destroy(self.walkingState.?);
        self.allocator.destroy(self.tutorialState.?);
        self.allocator.destroy(self.menuState.?);
        std.debug.print("State DEINIT done\n", .{});
    }

    pub fn isMenu(self: @This()) bool {
        return (self.stateMachine != null and self.stateMachine.?.state != null and self.stateMachine.?.state.?.smType == .MENU) or self.mode == .MENU;
    }

    pub fn isMapMenu(self: @This()) bool {
        return (self.stateMachine != null and self.stateMachine.?.state != null and self.stateMachine.?.state.?.smType == .MAPMENU);
    }

    pub fn goToNextMapNode(self: *@This()) !void {
        if (self.map) |map| {
            const numnodes = map.nodes.items.len;
            if ((self.currentNode + 1) >= numnodes) {
                self.currentNode = 0;
                std.debug.print("Resetting map. Going to node {d}\n", .{self.currentNode});
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

    pub fn goToMapMenu(self: *@This()) void {
        self.mode = .MENU;
    }

    pub fn goToNextMap(self: *@This()) !void {
        if (self.map == null) {
            return;
        }

        const selected = self.selectedMap;
        std.debug.print("Going to selected map {d}\n", .{selected});

        if (self.map.?.right != null) {
            const right = self.map.?.right.?;
            std.debug.print("Checking right map {d}\n", .{right.currentMapCount});
            if (right.currentMapCount == selected) {
                std.debug.print("Going to right map {s}\n", .{right.name});
                if (self.map.?.left != null) {
                    try self.map.?.left.?.deinitAll(self);
                }
                try self.map.?.deinit(self);
                self.map = right.*;
                self.currentMap = self.map.?.currentMapCount;
                self.currentNode = 0;
                self.selectedMap = 0;
                if (self.map.?.right == null or self.map.?.left == null) {
                    try self.generateRandomMaps();
                }
                self.adventurer.chooseNextMap(self);
                self.grid.clearTextures();
                return;
            }
        }

        if (self.map.?.left != null) {
            const left = self.map.?.left.?;
            std.debug.print("Checking left map {d}\n", .{left.currentMapCount});
            if (left.currentMapCount == selected) {
                std.debug.print("Going to left map {s}\n", .{left.name});
                if (self.map.?.right != null) {
                    try self.map.?.right.?.deinitAll(self);
                }
                try self.map.?.deinit(self);
                self.map = left.*;
                self.currentMap = self.map.?.currentMapCount;
                self.currentNode = 0;
                self.selectedMap = 0;
                if (self.map.?.right == null or self.map.?.left == null) {
                    try self.generateRandomMaps();
                }
                self.adventurer.chooseNextMap(self);
                self.grid.clearTextures();
                return;
            }
        }

        if (self.map.?.right == null and self.map.?.left == null) {
            std.debug.print("Generating more maps...\n", .{});
            try self.generateRandomMaps();
            try self.goToNextMap();
        }
    }

    pub fn generateRandomMaps(self: *@This()) !void {
        var atMost: u8 = 3;
        if (self.player.runes != null and self.player.runes.?.items.len >= 3) {
            atMost = 4;
        }

        const nodeTypeLeft: u8 = self.rand.intRangeAtMost(
            u8,
            0,
            atMost,
        );

        const nodeTypeRight: u8 = self.rand.intRangeAtMost(
            u8,
            0,
            atMost,
        );

        const nameLeft = try m.generateMapName(@as(m.MapNodeType, @enumFromInt(nodeTypeLeft)), self);
        const nameRight = try m.generateMapName(@as(m.MapNodeType, @enumFromInt(nodeTypeRight)), self);
        try self.generateNextMap(nameLeft, @as(m.MapNodeType, @enumFromInt(nodeTypeLeft)));
        try self.generateNextMap(nameRight, @as(m.MapNodeType, @enumFromInt(nodeTypeRight)));
    }

    pub fn generateNextMap(self: *@This(), name: [:0]const u8, nodeType: m.MapNodeType) !void {
        // Generate a new map using seed from State.
        // Maps should all contain the same number of nodes but
        // what each node consists of should be random.

        const List = std.ArrayList(m.MapNode);
        const MonsterList = std.ArrayList(mob.Monster);

        self.mapCount += 1;

        var numWalkingNodes = self.rand.intRangeAtMost(
            u4,
            2,
            4,
        );

        if (nodeType == .SHOP or nodeType == .BOSS or nodeType == .ASCEND or nodeType == .ASCENDBOSS) {
            numWalkingNodes = 1;
        }

        var newMap = try self.allocator.create(m.Map);

        newMap.currentMapCount = self.mapCount;
        newMap.name = name;
        newMap.nodes = List.init(self.allocator);
        newMap.left = null;
        newMap.right = null;

        for (0..numWalkingNodes) |i| {
            // Create new nodes for the map, assigning a name.
            const st = try std.fmt.allocPrintZ(self.allocator, "{d}", .{i});

            if (nodeType == .WALKING) {
                var outsideNode: m.MapNode = .{
                    .name = st,
                    .type = nodeType,
                    .texture = self.textureMap.get(.OUTSIDEGROUND),
                    .background = self.textureMap.get(.OUTSIDEBACKGROUND),
                    .monstersEntered = false,
                    .monsters = null,
                    .event = null,
                    .shopMap = null,
                    .stateMachine = null,
                };
                try outsideNode.init(self);
                try newMap.addMapNode(outsideNode);
            } else if (nodeType == .DUNGEON) {
                var dungeonNode: m.MapNode = .{
                    .name = st,
                    .type = nodeType,
                    .texture = self.textureMap.get(.DUNGEONGROUND),
                    .background = self.textureMap.get(.DUNGEONBACKGROUND),
                    .monsters = MonsterList.init(self.allocator),
                    .monstersEntered = false,
                    .event = null,
                    .shopMap = null,
                    .stateMachine = null,
                };
                try dungeonNode.init(self);
                try newMap.addMapNode(dungeonNode);
            } else if (nodeType == .BOSS) {
                var dungeonNode: m.MapNode = .{
                    .name = st,
                    .type = nodeType,
                    .texture = self.textureMap.get(.DUNGEONGROUND),
                    .background = self.textureMap.get(.DUNGEONBACKGROUND),
                    .monsters = MonsterList.init(self.allocator),
                    .monstersEntered = false,
                    .event = null,
                    .shopMap = null,
                    .stateMachine = null,
                };
                try dungeonNode.init(self);
                try newMap.addMapNode(dungeonNode);
            } else if (nodeType == .ASCENDBOSS) {
                var ascendBossNode: m.MapNode = .{
                    .name = st,
                    .type = nodeType,
                    .texture = self.textureMap.get(.DUNGEONGROUND),
                    .background = self.textureMap.get(.ASCENDBOSSBACKGROUND),
                    .monsters = MonsterList.init(self.allocator),
                    .monstersEntered = false,
                    .event = null,
                    .shopMap = null,
                    .stateMachine = null,
                };
                try ascendBossNode.init(self);
                try newMap.addMapNode(ascendBossNode);
            } else if (nodeType == .SHOP) {
                var shopNode: m.MapNode = .{
                    .name = st,
                    .type = nodeType,
                    .texture = self.textureMap.get(.DUNGEONGROUND),
                    .background = self.textureMap.get(.SHOPBACKGROUND),
                    .monstersEntered = false,
                    .monsters = null,
                    .event = null,
                    .shopMap = ShopMap.init(self.allocator),
                    .stateMachine = null,
                };
                try shopNode.init(self);
                try newMap.addMapNode(shopNode);
            } else if (nodeType == .ASCEND) {
                var ascendNode: m.MapNode = .{
                    .name = st,
                    .type = nodeType,
                    .texture = self.textureMap.get(.DUNGEONGROUND),
                    .background = self.textureMap.get(.ASCEND1BACKGROUND),
                    .monstersEntered = false,
                    .monsters = null,
                    .event = null,
                    .shopMap = null,
                    .stateMachine = null,
                };
                try ascendNode.init(self);
                try newMap.addMapNode(ascendNode);
            }
        }

        if (self.map) |_| {
            var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer arena.deinit();
            const allocator = arena.allocator();
            var mapqueue = std.ArrayList(?*m.Map).init(allocator);

            var currentMap: ?*m.Map = &self.map.?;

            while (currentMap != null) : (currentMap = mapqueue.orderedRemove(0)) {
                std.debug.print("current: {s}\n", .{currentMap.?.name});

                if (currentMap.?.left == null or currentMap.?.right == null) {
                    break;
                }

                if (currentMap.?.left) |l| {
                    std.debug.print("left: {s}\n", .{l.name});
                }
                if (currentMap.?.right) |r| {
                    std.debug.print("right: {s}\n", .{r.name});
                }
                try mapqueue.append(currentMap.?.left);
                try mapqueue.append(currentMap.?.right);
            }

            if (currentMap.?.right == null) {
                std.debug.print("Adding next map {s} as right child to {s}\n", .{ newMap.name, currentMap.?.name });
                currentMap.?.right = newMap;
            } else if (currentMap.?.left == null) {
                std.debug.print("Adding next map {s} as left child to {s}\n", .{ newMap.name, currentMap.?.name });
                currentMap.?.left = newMap;
            } else {
                std.debug.print("cannot add next map to {s}\n", .{currentMap.?.name});
                std.debug.assert(false);
            }
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

    pub fn isBoss(self: *@This()) !bool {
        const currentMapNode = try self.getCurrentMapNode();
        if (currentMapNode) |cn| {
            return cn.type == .BOSS or cn.type == .ASCENDBOSS;
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
        if (self.mode != .MENU and self.stateMachine != null and self.stateMachine.?.state != null and try self.stateMachine.?.state.?.getIsComplete()) {
            // do state transition
            std.debug.print("STATE COMPLETE\n\n", .{});
            try self.resetStates();

            const curState = self.stateMachine.?.state.?;
            const nextState: ?*@import("../states/smState.zig").SMState = curState.nextState;

            if (curState.smType == .GAMEEND) {
                std.debug.print("GAME END\n", .{});
                try self.reset();
                return;
            }

            if (nextState != null) {
                std.debug.print("Current state: {*}{}\n", .{ curState, curState.smType });
                std.debug.print("GOING TO NEXT STATE {*}{}\n", .{ nextState.?, nextState.?.smType });
                try self.stateMachine.?.setState(nextState.?, self);
            } else if (curState.smType != .TUTORIAL) {
                // Next state is null and current state is WALKING, go to next map node.
                try self.goToNextMapNode();
                const map = self.map.?;
                const numnodes = map.nodes.items.len;

                const monster = try self.getMonster();
                std.debug.print("current node: {d}\ncurrent map: {d}\n", .{ self.currentNode, self.currentMap });
                var nextSmState: ?*sm.SMState = null;
                std.debug.print("Going to state...\n", .{});

                if (monster != null) {
                    std.debug.print("FOUND MONSTER\n", .{});
                    const battleSmState = try self.battleState.?.smState(&self.allocator);
                    nextSmState = battleSmState;
                } else if (try self.isShop()) {
                    std.debug.print("SHOP STATE\n", .{});
                    const shopSmState = try self.shopState.?.smState(&self.allocator);
                    nextSmState = shopSmState;
                } else {
                    std.debug.print("WALKING STATE\n", .{});
                    const walkingSmState = try self.walkingState.?.smState(&self.allocator);
                    nextSmState = walkingSmState;
                }

                if ((self.currentNode + 1) >= numnodes) {
                    std.debug.print("Adding MAPMENU STATE as next state\n", .{});
                    self.mapMenuInputActive = true;
                    const mapMenuSmState = try self.mapMenuState.?.smState(&self.allocator);
                    nextSmState.?.nextState = mapMenuSmState;
                }

                if (nextSmState) |ns| {
                    std.debug.print("STATE TRANSITION {} -> {}\n\n", .{ curState.smType, ns.smType });
                    try self.stateMachine.?.setState(ns, self);
                } else {
                    // There should always be a next state to transition to.
                    std.debug.print("\nNo next state found!\n", .{});
                    std.debug.assert(false);
                }
            } else if (curState.smType == .TUTORIAL) {
                std.debug.print("TUTORIAL STATE\n", .{});
                // Handle initial walking state
                const walkingSmState = try self.walkingState.?.smState(&self.allocator);
                try self.stateMachine.?.setState(walkingSmState, self);
            }
        }

        if (self.mode != .MENU) {
            if (self.stateMachine != null and self.stateMachine.?.state != null) {
                try self.stateMachine.?.state.?.update(self);
            }
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
