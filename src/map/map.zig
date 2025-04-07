const rl = @import("raylib");
const std = @import("std");
const s = @import("../objects/state.zig");
const g = @import("../objects/grid.zig");
const altar = @import("../events/altar.zig");
const mob = @import("../objects/monster.zig");
const shop = @import("../objects/shopitem.zig");

pub const MapNode = struct {
    name: [:0]u8,
    type: MapNodeType,
    texture: ?rl.Texture,
    background: ?rl.Texture,
    monsters: ?std.ArrayList(mob.Monster),
    altarEvent: ?altar.AlterWalkingEvent,
    shopItems: ?std.ArrayList(shop.ShopItem),

    pub fn print(self: @This()) void {
        std.debug.print(
            "Node: {s}\nType: {}\n\n",
            .{
                self.name,
                self.type,
            },
        );
    }

    pub fn init(self: *@This(), state: *s.State) !void {
        const nodeContents = state.rand.intRangeAtMost(u4, 0, 15);
        const MonsterMessages = std.ArrayList([:0]const u8);

        //TODO: Better randomization for map node contents

        if (self.type == .DUNGEON) {
            if (nodeContents <= 4) {
                std.debug.print("Adding Green Goblin to node {s}\n", .{self.name});
                try self.addMonster(.{
                    .name = "Green Goblin",
                    .pos = .{ .x = state.grid.getWidth(), .y = state.grid.getGroundY() - 110 },
                    .nameKnown = false,
                    .speed = 0.45,
                    .health = 100,
                    .damageRange = 25,
                    .gold = state.rand.intRangeAtMost(u8, 1, 4),
                    .messages = MonsterMessages.init(state.allocator),
                });
            } else if (nodeContents > 4 and nodeContents <= 8) {
                std.debug.print("Adding Red Goblin to node {s}\n", .{self.name});
                try self.addMonster(.{
                    .name = "Red Goblin",
                    .pos = .{ .x = state.grid.getWidth(), .y = state.grid.getGroundY() - 110 },
                    .nameKnown = false,
                    .speed = 0.25,
                    .health = 150,
                    .damageRange = 35,
                    .gold = state.rand.intRangeAtMost(u8, 2, 6),
                    .messages = MonsterMessages.init(state.allocator),
                });
            } else if (nodeContents > 8 and nodeContents <= 15) {
                std.debug.print("Adding Altar to node {s}\n", .{self.name});
                const groundCenter = state.grid.getGroundCenterPos();
                const walkingEvent: altar.AlterWalkingEvent = .{
                    .baseEvent = .{
                        .handled = false,
                        .name = "Altar",
                        .type = .ALTAR,
                        .pos = .{
                            .x = groundCenter.x + 100,
                            .y = groundCenter.y - 110,
                        },
                    },
                    .alignment = .GOOD,
                };
                self.altarEvent = walkingEvent;
            }
        }

        if (self.type == .SHOP) {
            try self.addShopItem(.{
                .name = "d6",
                .die = .{
                    .name = "d6",
                    .sides = 6,
                    .texture = state.textureMap.get(.D6),
                },
                .price = 4,
                .pos = .{ .x = -350, .y = state.grid.getCenterPos().y },
                .texture = state.textureMap.get(.SHOPCARD).?,
                .purchased = false,
            });
            try self.addShopItem(.{
                .name = "Crit d4",
                .die = .{
                    .name = "Crit d4",
                    .sides = 4,
                    .texture = state.textureMap.get(.D4),
                },
                .price = 4,
                .pos = .{ .x = -250, .y = state.grid.getCenterPos().y },
                .texture = state.textureMap.get(.SHOPCARD).?,
                .purchased = false,
            });
        }
    }

    pub fn addTextures(self: *@This(), texture: rl.Texture) void {
        self.texture = texture;
    }

    pub fn addMonster(self: *@This(), monster: mob.Monster) !void {
        try self.monsters.?.append(monster);
    }

    pub fn addShopItem(self: *@This(), shopItem: shop.ShopItem) !void {
        try self.shopItems.?.append(shopItem);
    }

    pub fn update(self: *@This(), state: *s.State) !void {
        if (self.monsters != null) {
            for (0..self.monsters.?.items.len) |i| {
                const monster = self.monsters.?.items[i];
                const gold = monster.gold;
                const hp = monster.health;
                if (hp <= 0) {
                    _ = self.monsters.?.orderedRemove(i);
                    state.player.gold += gold;
                }
            }
        }

        if (self.type == .SHOP and self.shopItems != null) {
            const mousepos = rl.getMousePosition();
            for (0..self.shopItems.?.items.len) |i| {
                const item = &self.shopItems.?.items[i];
                if (item.purchased) {
                    continue;
                }
                const collisionRect = rl.Rectangle.init(
                    item.pos.x - 32,
                    item.pos.y - 38,
                    190,
                    210,
                );

                const hover = collisionRect.checkCollision(.{
                    .x = mousepos.x,
                    .y = mousepos.y,
                    .height = 2,
                    .width = 2,
                });
                if (hover) {
                    var buffer: [64:0]u8 = std.mem.zeroes([64:0]u8);
                    _ = std.fmt.bufPrintZ(
                        &buffer,
                        "{s} - {d}gp",
                        .{ item.name, item.price },
                    ) catch "";

                    rl.drawRectangle(
                        @as(i32, @intFromFloat(mousepos.x)),
                        @as(i32, @intFromFloat(mousepos.y)) - 100,
                        150,
                        70,
                        rl.getColor(0x0000D0),
                    );

                    rl.drawText(
                        &buffer,
                        @as(i32, @intFromFloat(mousepos.x)) + 10,
                        @as(i32, @intFromFloat(mousepos.y)) - 90,
                        20,
                        .gray,
                    );

                    const hoverRect: rl.Rectangle = .{
                        .x = collisionRect.x + 13,
                        .y = collisionRect.y + 2,
                        .width = 165,
                        .height = 205,
                    };

                    rl.drawRectangleGradientEx(
                        hoverRect,
                        rl.Color.init(50, 100, 150, 0),
                        rl.Color.init(50, 100, 150, 150),
                        rl.Color.init(50, 100, 150, 0),
                        rl.Color.init(50, 100, 150, 150),
                    );
                }
                if (rl.isMouseButtonPressed(rl.MouseButton.left) and hover) {
                    const purchased = try state.player.purchaseItem(item.*);
                    if (purchased) {
                        item.purchased = true;
                    } else {
                        try state.messages.?.append("Not enough gold");
                    }
                }
            }
        }
    }

    pub fn draw(self: *@This(), state: *s.State, dt: f32) !void {
        if (self.background) |bg| {
            rl.drawTexturePro(
                bg,
                .{
                    .x = 0,
                    .y = 0,
                    .width = 1024,
                    .height = 768,
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

        if (self.altarEvent) |evt| {
            evt.draw(state);
        }

        if (self.type == .SHOP) {
            if (self.shopItems == null) {
                return;
            }
            for (0..self.shopItems.?.items.len) |i| {
                var item = &self.shopItems.?.items[i];
                if (item.purchased) {
                    continue;
                }
                const die = item.die.?;
                const dest: f32 = state.grid.getCenterPos().x + @as(f32, @floatFromInt(256 * i));
                _ = item.enter(dest, dt);

                rl.drawTexturePro(
                    item.texture,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = 256,
                        .height = 256,
                    },
                    .{
                        .x = item.pos.x - 64,
                        .y = item.pos.y - 64,
                        .width = 256,
                        .height = 256,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .white,
                );

                rl.drawTexturePro(
                    die.texture.?,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = 128,
                        .height = 128,
                    },
                    .{
                        .x = item.pos.x,
                        .y = item.pos.y,
                        .width = 128,
                        .height = 128,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .white,
                );
            }
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

        if (self.type == .DUNGEON) {
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
    nextMap: ?*Map,

    pub fn draw(self: *@This(), state: *s.State) !void {
        _ = self;
        _ = state;
        // TODO: Draw map screen
    }

    pub fn addMap(self: @This(), state: *s.State, name: [:0]const u8, nodes: std.ArrayList(MapNode)) !void {
        var newMap = try state.allocator.create(Map);

        newMap.currentMapCount = self.currentMapCount + 1;
        newMap.name = name;
        newMap.nodes = nodes;

        self.nextMap = newMap;
    }

    pub fn addMapNode(self: *@This(), node: MapNode) !void {
        try self.nodes.append(node);
    }

    pub fn traverse(self: *@This(), callback: fn (?*Map) void) void {
        var currentMap: ?*Map = self;
        //callback(currentMap);

        while (currentMap != null) : (currentMap = currentMap.?.nextMap) {
            callback(currentMap);
        }
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
};
