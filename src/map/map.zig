const rl = @import("raylib");
const std = @import("std");
const s = @import("../objects/state.zig");
const g = @import("../objects/grid.zig");
const altar = @import("../events/altar.zig");
const mob = @import("../objects/monster.zig");

pub const MapNode = struct {
    name: [:0]u8,
    type: MapNodeType,
    texture: ?rl.Texture,
    background: ?rl.Texture,
    monsters: ?std.ArrayList(mob.Monster),
    altarEvent: ?altar.AlterWalkingEvent,

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

        if (self.type == .DUNGEON and nodeContents <= 4) {
            std.debug.print("Adding Green Goblin to node {s}\n", .{self.name});
            try self.addMonster(.{
                .name = "Green Goblin",
                .pos = .{ .x = state.grid.getWidth(), .y = state.grid.getGroundY() - 110 },
                .nameKnown = false,
                .speed = 0.45,
                .health = 100,
                .damageRange = 25,
            });
        } else if (self.type == .DUNGEON and nodeContents > 4 and nodeContents <= 8) {
            std.debug.print("Adding Red Goblin to node {s}\n", .{self.name});
            try self.addMonster(.{
                .name = "Red Goblin",
                .pos = .{ .x = state.grid.getWidth(), .y = state.grid.getGroundY() - 110 },
                .nameKnown = false,
                .speed = 0.25,
                .health = 150,
                .damageRange = 35,
            });
        } else if (self.type == .DUNGEON and nodeContents > 8 and nodeContents <= 15) {
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

    pub fn addTextures(self: *@This(), texture: rl.Texture) void {
        self.texture = texture;
    }

    pub fn addMonster(self: *@This(), monster: mob.Monster) !void {
        try self.monsters.?.append(monster);
    }

    pub fn update(self: *@This()) !void {
        if (self.monsters != null) {
            for (0..self.monsters.?.items.len) |i| {
                const hp = self.monsters.?.items[i].health;
                if (hp <= 0) {
                    _ = self.monsters.?.orderedRemove(i);
                }
            }
        }
    }

    pub fn draw(self: *@This(), state: *s.State) !void {
        if (self.background) |bg| {
            rl.drawTexturePro(
                bg,
                .{
                    .x = 0,
                    .y = 0,
                    .width = 2046,
                    .height = 1591,
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
