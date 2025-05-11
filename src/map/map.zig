const rl = @import("raylib");
const std = @import("std");
const s = @import("../objects/state.zig");
const g = @import("../objects/grid.zig");
const altar = @import("../events/altar.zig");
const AscendWalkingEvent = @import("../events/ascend.zig").AscendWalkingEvent;
const RescueWalkingEvent = @import("../events/rescue.zig").RescueWalkingEvent;
const Event = @import("../events/event.zig").Event;
const treasure = @import("../events/treasure.zig");
const mob = @import("../objects/monster.zig");
const shop = @import("../objects/shopitem.zig");
const BasicDie = @import("../dice/basic.zig").BasicDie;
const KinRune = @import("../runes/kin.zig").KinRune;
const FateRune = @import("../runes/fate.zig").FateRune;
const DawnRune = @import("../runes/dawn.zig").DawnRune;
const Rune = @import("../runes/rune.zig").Rune;
const GameEndState = @import("../states/gameEnd.zig").GameEndState;
const ShopMap = @import("shop.zig").ShopMap;

pub const MapNode = struct {
    name: [:0]u8,
    type: MapNodeType,
    texture: ?rl.Texture,
    background: ?rl.Texture,
    monsters: ?std.ArrayList(mob.Monster),
    monstersEntered: bool,
    event: ?*Event,
    shopMap: ?ShopMap,
    stateMachine: ?@import("../states/stateMachine.zig").StateMachine,

    pub fn print(self: @This()) void {
        std.debug.print(
            "Node: {s}\nType: {}\n\n",
            .{
                self.name,
                self.type,
            },
        );
    }

    pub fn deinit(self: *@This(), state: *s.State) !void {
        std.debug.print("DEINIT NODE {} {s}\n", .{ self.type, self.name });
        if (self.monsters) |monsters| {
            for (0..monsters.items.len) |i| {
                try monsters.items[i].deinit(state);
            }
            monsters.deinit();
        }
        // if (self.shopMap != null) {
        //     self.shopMap.?.deinit(state);
        //
        //     state.allocator.destroy(self.shopMap.?);
        // }
        if (self.event) |evt| {
            try evt.deinit(state);
            state.allocator.destroy(self.event.?);
        }

        state.allocator.free(self.name);
    }

    pub fn init(self: *@This(), state: *s.State) !void {
        const nodeContents = state.rand.intRangeAtMost(u4, 0, 15);
        const MonsterMessages = std.ArrayList([:0]const u8);
        const MonsterRunes = std.ArrayList(*Rune);

        //TODO: Better randomization for map node contents

        if (self.type == .WALKING and state.tutorialStep > 0) {
            if (nodeContents > 8 and nodeContents < 13) {
                std.debug.print("Adding Altar to node {s}\n", .{self.name});
                const groundCenter = state.grid.getGroundCenterPos();
                var walkingEvent = try state.allocator.create(altar.AltarWalkingEvent);

                if (nodeContents > 8 and nodeContents < 11) {
                    walkingEvent.alignment = .GOOD;
                    walkingEvent.name = "Good Altar";
                } else {
                    walkingEvent.alignment = .EVIL;
                    walkingEvent.name = "Evil Altar";
                }
                walkingEvent.handled = false;
                walkingEvent.eventType = .ALTAR;
                walkingEvent.pos = .{
                    .x = groundCenter.x + 100,
                    .y = groundCenter.y - 110,
                };
                const event = try walkingEvent.event(&state.allocator);
                self.event = event;
            }
            if (nodeContents > 13) {
                std.debug.print("Adding rescue event to node {s}\n", .{self.name});

                const groundCenter = state.grid.getGroundCenterPos();
                var rescueEvent = try state.allocator.create(RescueWalkingEvent);

                rescueEvent.handled = false;
                rescueEvent.name = "Peasant Rescue";
                rescueEvent.eventType = .RESCUE;
                rescueEvent.pos = .{
                    .x = groundCenter.x + 100,
                    .y = groundCenter.y - 110,
                };
                const event = try rescueEvent.event(&state.allocator);
                self.event = event;
            }
        }

        if (self.type == .ASCEND) {
            // If the player has three runes, they can ascend
            // if they choose to ascend, they fight a final boss
            // once the boss is defeated, the game ends and they unlock another sword to play as
            std.debug.print("Adding Ascend event to node {s}\n", .{self.name});
            const groundCenter = state.grid.getGroundCenterPos();
            var walkingEvent = try state.allocator.create(AscendWalkingEvent);

            walkingEvent.handled = false;
            walkingEvent.name = "Ascend";
            walkingEvent.eventType = .ASCEND;
            walkingEvent.pos = .{
                .x = groundCenter.x + 100,
                .y = groundCenter.y - 110,
            };
            const event = try walkingEvent.event(&state.allocator);
            self.event = event;
        }

        if (self.type == .BOSS) {
            var kinRune: *KinRune = try state.allocator.create(KinRune);

            kinRune.name = "Kin";
            kinRune.pos = .{
                .x = state.grid.getWidth() - 305.0,
                .y = state.grid.topUI() + 75.0,
            };
            const kr = try kinRune.rune(&state.allocator);

            var fateRune: *FateRune = try state.allocator.create(FateRune);

            fateRune.name = "Fate";
            fateRune.pos = .{
                .x = state.grid.getWidth() - 225.0,
                .y = state.grid.topUI() + 75.0,
            };
            const fr = try fateRune.rune(&state.allocator);

            var dawnRune: *DawnRune = try state.allocator.create(DawnRune);

            dawnRune.name = "Dawn";
            dawnRune.pos = .{
                .x = state.grid.getWidth() - 225.0,
                .y = state.grid.topUI() + 75.0,
            };
            const dr = try dawnRune.rune(&state.allocator);

            var runes = MonsterRunes.init(state.allocator);
            // TOOD: Determine runes randomly
            try runes.append(kr);
            try runes.append(fr);
            try runes.append(dr);

            std.debug.print("Adding Boss to node {s}\n", .{self.name});
            try self.addMonster(.{
                .name = "Boss",
                .pos = .{ .x = state.grid.getWidth(), .y = state.grid.getGroundY() - 110 },
                .nameKnown = false,
                .speed = 0.15,
                .health = 40,
                .maxHealth = 40,
                .damageRange = 35,
                .dying = false,
                .gold = state.rand.intRangeAtMost(u8, 10, 25),
                .runes = runes,
                .messages = MonsterMessages.init(state.allocator),
            });
        }

        if (self.type == .ASCENDBOSS) {
            var kinRune: *KinRune = try state.allocator.create(KinRune);
            kinRune.name = "Kin";
            kinRune.pos = .{
                .x = state.grid.getWidth() - 305.0,
                .y = state.grid.topUI() + 75.0,
            };
            const kr = try kinRune.rune(&state.allocator);

            var fateRune: *FateRune = try state.allocator.create(FateRune);
            fateRune.name = "Fate";
            fateRune.pos = .{
                .x = state.grid.getWidth() - 225.0,
                .y = state.grid.topUI() + 75.0,
            };
            const fr = try fateRune.rune(&state.allocator);

            var dawnRune: *DawnRune = try state.allocator.create(DawnRune);
            dawnRune.name = "Dawn";
            dawnRune.pos = .{
                .x = state.grid.getWidth() - 225.0,
                .y = state.grid.topUI() + 75.0,
            };
            const dr = try dawnRune.rune(&state.allocator);

            var runes = MonsterRunes.init(state.allocator);
            // TOOD: Determine runes randomly
            try runes.append(kr);
            try runes.append(fr);
            try runes.append(dr);

            std.debug.print("Adding Ascend Boss to node {s}\n", .{self.name});
            try self.addMonster(.{
                .name = "Ascend Boss",
                .pos = .{ .x = state.grid.getWidth(), .y = state.grid.getGroundY() - 110 },
                .nameKnown = false,
                .speed = 0.15,
                .health = 100,
                .maxHealth = 100,
                .damageRange = 35,
                .dying = false,
                .gold = state.rand.intRangeAtMost(u8, 10, 55),
                .runes = runes,
                .messages = MonsterMessages.init(state.allocator),
            });
        }

        if (self.type == .DUNGEON) {
            if (nodeContents <= 4) {
                std.debug.print("Adding Green Goblin to node {s}\n", .{self.name});
                try self.addMonster(.{
                    .name = "Green Goblin",
                    .pos = .{ .x = state.grid.getWidth(), .y = state.grid.getGroundY() - 110 },
                    .nameKnown = false,
                    .speed = 0.45,
                    .health = 2,
                    .maxHealth = 2,
                    .damageRange = 5,
                    .dying = false,
                    .gold = state.rand.intRangeAtMost(u8, 1, 4),
                    .runes = null,
                    .messages = MonsterMessages.init(state.allocator),
                });
            } else if (nodeContents > 4 and nodeContents <= 8) {
                std.debug.print("Adding Red Goblin to node {s}\n", .{self.name});
                try self.addMonster(.{
                    .name = "Red Goblin",
                    .pos = .{ .x = state.grid.getWidth(), .y = state.grid.getGroundY() - 110 },
                    .nameKnown = false,
                    .speed = 0.25,
                    .health = 4,
                    .maxHealth = 4,
                    .damageRange = 10,
                    .dying = false,
                    .gold = state.rand.intRangeAtMost(u8, 2, 6),
                    .runes = null,
                    .messages = MonsterMessages.init(state.allocator),
                });
            } else if (nodeContents > 8 and nodeContents <= 15) {
                std.debug.print("Adding Treasure Chest to node {s}\n", .{self.name});
                const groundCenter = state.grid.getGroundCenterPos();
                var walkingEvent = try state.allocator.create(treasure.TreasureWalkingEvent);

                walkingEvent.gold = state.rand.intRangeAtMost(i32, 1, 10);
                walkingEvent.handled = false;
                walkingEvent.name = "Treasure Chest";
                walkingEvent.eventType = .CHEST;
                walkingEvent.pos = .{
                    .x = groundCenter.x + 100,
                    .y = groundCenter.y - 110,
                };
                const event = try walkingEvent.event(&state.allocator);
                self.event = event;
            }
        }

        if (self.type == .SHOP) {
            var shopMap = ShopMap.init(state.allocator);
            try shopMap.generateRandomShopItems(state);
            self.shopMap = shopMap;
        }
    }

    pub fn addTextures(self: *@This(), texture: rl.Texture) void {
        self.texture = texture;
    }

    pub fn addMonster(self: *@This(), monster: mob.Monster) !void {
        try self.monsters.?.append(monster);
    }

    pub fn addShopItem(self: *@This(), shopItem: shop.ShopItem) !void {
        if (self.shopMap == null) {
            std.debug.print("Cannot insert shop item into map with no shop");
            std.debug.assert(false);
        }
        try self.shopMap.?.shopItems.?.append(shopItem);
    }

    pub fn removeDeadMonsters(self: *@This()) void {
        if (self.monsters != null) {
            var removedCount: i32 = 0;
            const prevLen = self.monsters.?.items.len;
            for (0..self.monsters.?.items.len) |i| {
                const monster = &self.monsters.?.items[i];
                const hp = monster.health;
                if (hp <= 0 and monster.dying) {
                    removedCount += 1;
                    _ = self.monsters.?.orderedRemove(i);
                }
            }

            if (removedCount == @as(i32, @intCast(prevLen))) {
                // All monsters removed.
                self.monstersEntered = false;
            }
        }
    }

    pub fn update(self: *@This(), state: *s.State) !void {
        if (self.monsters != null) {
            for (0..self.monsters.?.items.len) |i| {
                var monster = &self.monsters.?.items[i];
                const hp = monster.health;
                if (hp <= 0 and !monster.dying) {
                    monster.dying = true;
                    state.player.monstersKilled += 1;
                    if (std.mem.eql(u8, monster.name, "Ascend Boss")) {
                        // TODO: Make ascend boss a special type of monster.
                        // Go to end game state
                        var gameEndState = try state.allocator.create(GameEndState);
                        defer state.allocator.destroy(gameEndState);

                        gameEndState.nextState = null;
                        gameEndState.isComplete = false;
                        gameEndState.startTime = rl.getTime();
                        const gameEndSmState = try gameEndState.smState(&state.allocator);

                        try state.stateMachine.?.setState(gameEndSmState, state);
                    }
                }
            }
        }

        if (self.type == .ASCEND) {}

        if (self.type == .SHOP and self.shopMap != null) {
            try self.shopMap.?.update(state);
        }
    }

    pub fn draw(self: *@This(), state: *s.State, dt: f32) !void {
        if (self.background) |bg| {
            rl.drawTexturePro(
                bg,
                .{
                    .x = 0,
                    .y = 0,
                    .width = 2048,
                    .height = 1400,
                },
                .{
                    .x = 0,
                    .y = 0,
                    .width = state.grid.getWidth(),
                    .height = state.grid.getHeight(),
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }

        if (self.event) |evt| {
            try evt.draw(state);
        }

        if (self.monsters != null and self.monsters.?.items.len > 0) {
            const mobs = self.monsters.?;
            for (0..mobs.items.len) |i| {
                self.monstersEntered = mobs.items[i].enter(state, dt);
                mobs.items[i].draw(state);
            }
        }

        if (self.type == .SHOP) {
            self.shopMap.?.draw(state);
        }

        if (self.type == .WALKING) {
            // add ground textures
            if (self.texture) |texture| {
                for (0..g.Grid.numCols) |i| {
                    const row: usize = state.grid.cells.len - 4;
                    state.grid.cells[row][i].textures.clearAndFree();

                    const textureWidth = 215;
                    const textureHeight = 250;
                    const widthTextureOffset = state.getConsistentRandomNumber(row, i, 0, 1) * textureWidth;
                    const widthHeightOffset = state.getConsistentRandomNumber(row, i, 0, 1) * textureHeight;
                    const offsetRect = rl.Rectangle.init(
                        @floatFromInt(widthTextureOffset),
                        @floatFromInt(widthHeightOffset),
                        @floatFromInt(textureWidth),
                        @floatFromInt(textureHeight),
                    );

                    if (state.getConsistentRandomNumber(row - 1, i, 0, 1) == 1) {
                        const rockWidthTextureOffset = state.getConsistentRandomNumber(row, i, 0, 1) * textureWidth;
                        const rockHeightTextureOffset = state.getConsistentRandomNumber(row, i, 0, 1) * textureHeight + 500;
                        const rockOffsetRect = rl.Rectangle.init(
                            @floatFromInt(rockWidthTextureOffset),
                            @floatFromInt(rockHeightTextureOffset),
                            @floatFromInt(textureWidth),
                            @floatFromInt(textureHeight),
                        );
                        const rd = state.getConsistentRandomNumber(row, i, 0, 20);

                        try state.grid.cells[row][i].textures.append(.{
                            .texture = texture,
                            .textureOffset = rockOffsetRect,
                            .displayOffset = .{
                                .x = 0,
                                .y = @as(f32, @floatFromInt(rd)) * -1 - 10.0,
                            },
                            .zLevel = 1,
                        });
                    }

                    try state.grid.cells[row][i].textures.append(.{
                        .texture = texture,
                        .textureOffset = offsetRect,
                        .displayOffset = .{ .x = 0, .y = 0 },
                        .zLevel = 0,
                    });
                }
            }
        }

        if (self.type == .DUNGEON or self.type == .BOSS) {
            // add ground textures
            const blackRect: rl.Rectangle = .{
                .height = 100,
                .width = state.grid.getWidth(),
                .x = 0,
                .y = state.grid.getGroundY(),
            };
            rl.drawRectanglePro(
                blackRect,
                .{ .x = 0, .y = 0 },
                0.0,
                .black,
            );
            if (self.texture) |texture| {
                for (0..g.Grid.numCols) |i| {
                    const row = state.grid.cells.len - 4;
                    state.grid.cells[row][i].textures.clearAndFree();

                    const textureWidth = 118;
                    const textureHeight = 118;
                    const widthTextureOffset = 400 + state.getConsistentRandomNumber(row, i, 0, 2) * textureWidth;
                    const heightTextureOffset = 1806;
                    const offsetRect = rl.Rectangle.init(
                        @floatFromInt(widthTextureOffset),
                        @floatFromInt(heightTextureOffset),
                        @floatFromInt(textureWidth),
                        @floatFromInt(textureHeight),
                    );

                    try state.grid.cells[row][i].textures.append(.{
                        .texture = texture,
                        .textureOffset = offsetRect,
                        .displayOffset = .{ .x = 0, .y = 0 },
                        .zLevel = 0,
                    });
                }
            }
        }
    }
};

pub const Map = struct {
    name: [:0]const u8,
    currentMapCount: u8,
    nodes: std.ArrayList(MapNode),
    right: ?*Map,
    left: ?*Map,

    pub fn addMap(self: @This(), state: *s.State, name: [:0]const u8, nodes: std.ArrayList(MapNode)) !void {
        var newMap = try state.allocator.create(Map);

        newMap.currentMapCount = self.currentMapCount + 1;
        newMap.name = name;
        newMap.nodes = nodes;

        if (self.right != null) {
            self.left = newMap;
        } else {
            self.right = newMap;
        }
    }

    pub fn addMapNode(self: *@This(), node: MapNode) !void {
        try self.nodes.append(node);
    }

    pub fn traverse(self: *@This(), callback: fn (?*Map) void) void {
        var currentMap: ?*Map = self;

        if (currentMap == null) {
            return;
        }

        callback(currentMap);

        if (currentMap.?.right != null) {
            currentMap.?.right.?.traverse(callback);
        }

        if (currentMap.?.left != null) {
            currentMap.?.left.?.traverse(callback);
        }
    }

    pub fn deinitAll(self: *@This(), state: *s.State) !void {
        var currentMap: ?*Map = self;

        if (currentMap == null) {
            return;
        }
        try currentMap.?.deinit(state);

        if (currentMap.?.right != null) {
            try currentMap.?.right.?.deinitAll(state);
        }

        if (currentMap.?.left != null) {
            try currentMap.?.left.?.deinitAll(state);
        }
    }

    pub fn deinit(self: *@This(), state: *s.State) !void {
        for (0..self.nodes.items.len) |i| {
            try self.nodes.items[i].deinit(state);
        }
        self.nodes.deinit();
        // state.allocator.free(self.name);
    }

    pub fn debug(map: ?*Map) void {
        if (map) |m| {
            std.debug.print(" -> map {d} {s}\n", .{ m.currentMapCount, m.name });

            std.debug.print("    {d} nodes: \n", .{m.nodes.items.len});
            for (0..m.nodes.items.len) |i| {
                std.debug.print("      {s}\n", .{m.nodes.items[i].name});
            }
        }
    }

    pub fn print(self: *@This()) void {
        self.traverse(debug);
    }
};

pub const MapNodeType = enum(u8) {
    WALKING,
    DUNGEON,
    SHOP,
    BOSS,
    ASCEND,
    ASCENDBOSS,
};

const DungeonSuffixes = [_][]const u8{
    "Dugeon",
    "Lair",
    "Basement",
    "Donjon",
    "Prison",
    "Jail",
    "Hole",
};

const DungeonPrefixes = [_][]const u8{
    "Dank",
    "Goblin",
    "Moldy",
    "Sunless",
    "Fetid",
    "Murky",
};

const ShopSuffixes = [_][]const u8{
    "Shop",
    "Store",
    "Shoppe",
    "Office",
    "Study",
    "Space",
    "Parlor",
};

const ShopPrefixes = [_][]const u8{
    "Discount",
    "Fancy",
    "Baroque",
    "Artistic",
    "Classy",
    "High",
};

const WalkingSuffixes = [_][]const u8{
    "Field",
    "Meadow",
    "Grass",
    "Grounds",
    "Land",
    "Lawn",
    "Gardens",
};

const WalkingPrefixes = [_][]const u8{
    "Lush",
    "Fertile",
    "Teeming",
    "Fruitful",
    "Ample",
    "Fecund",
};

const BossSuffixes = [_][]const u8{
    "Boss",
    "Leader",
    "Lord",
    "Overseer",
    "Lieutenant",
    "Kingpin",
    "Tough",
};

const BossPrefixes = [_][]const u8{
    "Big",
    "Mean",
    "Burly",
    "Fierce",
    "Thug",
    "Evil",
};

pub fn generateMapName(mapNodeType: MapNodeType, state: *s.State) ![:0]u8 {
    if (mapNodeType == .DUNGEON) {
        const prefixIndex: usize = state.rand.intRangeAtMost(
            usize,
            0,
            DungeonPrefixes.len - 1,
        );
        const suffixIndex: usize = state.rand.intRangeAtMost(
            usize,
            0,
            DungeonSuffixes.len - 1,
        );
        const prefix = DungeonPrefixes[prefixIndex];
        const suffix = DungeonSuffixes[suffixIndex];
        const st = try std.fmt.allocPrintZ(state.allocator, "{s} {s}", .{ prefix, suffix });
        return st;
    }
    if (mapNodeType == .SHOP) {
        const prefixIndex: usize = state.rand.intRangeAtMost(
            usize,
            0,
            ShopPrefixes.len - 1,
        );
        const suffixIndex: usize = state.rand.intRangeAtMost(
            usize,
            0,
            ShopSuffixes.len - 1,
        );
        const prefix = ShopPrefixes[prefixIndex];
        const suffix = ShopSuffixes[suffixIndex];
        const st = try std.fmt.allocPrintZ(state.allocator, "{s} {s}", .{ prefix, suffix });
        return st;
    }
    if (mapNodeType == .WALKING) {
        const prefixIndex: usize = state.rand.intRangeAtMost(
            usize,
            0,
            WalkingPrefixes.len - 1,
        );
        const suffixIndex: usize = state.rand.intRangeAtMost(
            usize,
            0,
            WalkingSuffixes.len - 1,
        );
        const prefix = WalkingPrefixes[prefixIndex];
        const suffix = WalkingSuffixes[suffixIndex];
        const st = try std.fmt.allocPrintZ(state.allocator, "{s} {s}", .{ prefix, suffix });
        return st;
    }
    if (mapNodeType == .BOSS) {
        const prefixIndex: usize = state.rand.intRangeAtMost(
            usize,
            0,
            BossPrefixes.len - 1,
        );
        const suffixIndex: usize = state.rand.intRangeAtMost(
            usize,
            0,
            BossSuffixes.len - 1,
        );
        const prefix = BossPrefixes[prefixIndex];
        const suffix = BossSuffixes[suffixIndex];
        const st = try std.fmt.allocPrintZ(state.allocator, "{s} {s}", .{ prefix, suffix });
        return st;
    }
    const st = try std.fmt.allocPrintZ(state.allocator, "No map name", .{});
    return st;
}
