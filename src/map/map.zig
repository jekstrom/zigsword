const rl = @import("raylib");
const std = @import("std");
const s = @import("../objects/state.zig");
const g = @import("../objects/grid.zig");

pub const MapNode = struct {
    name: [:0]u8,
    type: MapNodeType,
    texture: ?rl.Texture,
    background: ?rl.Texture,

    pub fn addTextures(self: *@This(), texture: rl.Texture) void {
        self.texture = texture;
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

        if (self.type == .WALKING) {
            // add ground textures
            if (self.texture) |texture| {
                for (0..g.Grid.numCols) |i| {
                    const row: usize = state.grid.cells.len - 4;
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
                                .y = @as(f32, @floatFromInt(rd)) * -1 - 5.0,
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
            if (self.texture) |texture| {
                for (0..g.Grid.numCols) |i| {
                    const textureWidth = 118;
                    const textureHeight = 118;
                    const widthTextureOffset = 400;
                    const heightTextureOffset = 1923;
                    // const widthTextureOffset = rand.intRangeAtMost(u16, 400, 1) * textureWidth;
                    // const heightTextureOffset = rand.intRangeAtMost(u16, 1923, 1) * textureHeight;
                    const offsetRect = rl.Rectangle.init(
                        @floatFromInt(widthTextureOffset),
                        @floatFromInt(heightTextureOffset),
                        @floatFromInt(textureWidth),
                        @floatFromInt(textureHeight),
                    );

                    // if (rand.boolean()) {
                    //     const rockWidthTextureOffset = rand.intRangeAtMost(u16, 0, 1) * textureWidth;
                    //     const rockHeightTextureOffset = rand.intRangeAtMost(u16, 0, 1) * textureHeight + 500;
                    //     const rockOffsetRect = rl.Rectangle.init(
                    //         @floatFromInt(rockWidthTextureOffset),
                    //         @floatFromInt(rockHeightTextureOffset),
                    //         @floatFromInt(textureWidth),
                    //         @floatFromInt(textureHeight),
                    //     );
                    //     try state.grid.cells[state.grid.cells.len - 4][i].textures.append(.{
                    //         .texture = texture,
                    //         .textureOffset = rockOffsetRect,
                    //         .displayOffset = .{
                    //             .x = 0,
                    //             .y = @as(f32, @floatFromInt(rand.intRangeAtMost(u16, 0, 20))) * -1 - 10.0,
                    //         },
                    //         .zLevel = 1,
                    //     });
                    // }

                    try state.grid.cells[state.grid.cells.len - 4][i].textures.append(.{
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
