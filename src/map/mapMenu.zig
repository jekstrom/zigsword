const rl = @import("raylib");
const ui = @import("raygui");
const s = @import("../objects/state.zig");
const MapNode = @import("map.zig").MapNode;
const Map = @import("map.zig").Map;
const std = @import("std");

pub const MapMenu = struct {
    const TreeSide = enum(u8) {
        left,
        right,
        center,
    };

    fn drawTree(map: ?*Map, it: *i32, state: *s.State, center: rl.Vector2, side: TreeSide) !void {
        if (map == null) {
            return;
        }
        const yoffset = 130;
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        var List = std.ArrayList(?*Map).init(allocator);

        try List.append(map);
        var currentMap = map;

        while (currentMap != null) : (currentMap = List.orderedRemove(0)) {
            try List.append(currentMap.?.left);
            try List.append(currentMap.?.right);

            const txtSize = rl.measureTextEx(state.font, currentMap.?.name, 50, 2);

            var txtPos: rl.Vector2 = .{
                .x = center.x - txtSize.x / 2,
                .y = center.y - (txtSize.y / 2) - 200.0 + @as(f32, @floatFromInt(yoffset * it.*)),
            };

            if (side == .right) {
                txtPos = txtPos.add(.{
                    .x = -150,
                    .y = 0,
                });
            } else if (side == .left) {
                txtPos = txtPos.add(.{
                    .x = 150,
                    .y = 0,
                });
            }

            rl.drawTextPro(
                state.font,
                currentMap.?.name,
                txtPos,
                .{ .x = 0, .y = 0 },
                0.0,
                50,
                2,
                .white,
            );

            const mid: f32 = -@as(f32, @floatFromInt(currentMap.?.nodes.items.len - 1)) / 2;
            for (0.., currentMap.?.nodes.items) |i, node| {
                const mapCirclePos: rl.Vector2 = .{
                    .x = txtPos.x + (txtSize.x / 2) + (mid + @as(f32, @floatFromInt(i))) * 100.0,
                    .y = txtPos.y + 70,
                };

                if (i < currentMap.?.nodes.items.len - 1) {
                    rl.drawLineEx(
                        mapCirclePos,
                        mapCirclePos.add(.{
                            .x = 100,
                            .y = 0,
                        }),
                        5.0,
                        .white,
                    );
                }

                drawNode(node, mapCirclePos, state.currentNode == i and state.currentMap == currentMap.?.currentMapCount, state);
            }

            it.* += 1;
        }

        // drawTree(map.?.right, it, state, center, .right);
        // drawTree(map.?.left, it, state, center, .left);
    }

    pub fn draw(self: *@This(), state: *s.State) !void {
        _ = self;
        const center = state.grid.getCenterPos();

        rl.drawTexturePro(
            state.textureMap.get(.MAPBACKGROUND).?,
            .{
                .x = 0,
                .y = 0,
                .width = 2048,
                .height = 2048,
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

        // show current map nodes in a tree

        // traverse the tree and display each map and each map's nodes (up to fog of war)
        // default fog of war should be one map away
        // - possibility i add in ability to see further out as a powerup
        if (state.map == null) {
            return;
        }

        const currentMap: ?*Map = &state.map.?;
        var it: i32 = 0;
        try drawTree(currentMap, &it, state, center, .center);

        // adventurer automatically will chose which node to go to next

        // let player choose which map to go to next
        // costs 1 energy

        if (ui.guiButton(.{ .x = state.grid.getWidth() - 150, .y = state.grid.getHeight() - 80, .height = 40, .width = 100 }, "Exit") > 0) {
            state.mode = .NONE;
        }
    }

    fn drawNode(node: MapNode, mapCirclePos: rl.Vector2, isCurrentNode: bool, state: *s.State) void {
        for (0..3) |i| {
            // Draw node outline
            rl.drawCircleLinesV(
                mapCirclePos,
                10.0 + @as(f32, @floatFromInt(i)),
                .black,
            );
        }

        var nodeColor: rl.Color = .white;
        if (isCurrentNode) {
            nodeColor = .gray;
        }

        rl.drawCircleV(
            mapCirclePos,
            9.0,
            nodeColor,
        );

        const fontSize = 25;
        const spacing = 2;
        const txtSize = rl.measureTextEx(state.font, node.name, fontSize, spacing);

        const txtPos: rl.Vector2 = .{
            .x = mapCirclePos.x - txtSize.x / 2,
            .y = mapCirclePos.y - (txtSize.y / 2) + 30.0,
        };

        rl.drawTextPro(
            state.font,
            node.name,
            txtPos,
            .{ .x = 0, .y = 0 },
            0.0,
            fontSize,
            spacing,
            .white,
        );

        if (node.event) |evt| {
            _ = evt;
            rl.drawTextPro(
                state.font,
                "e",
                mapCirclePos.add(.{ .x = -5, .y = -10 }),
                .{ .x = 0, .y = 0 },
                0.0,
                20,
                spacing,
                .black,
            );
        } else if (node.monsters) |monsters| {
            if (monsters.items.len > 0) {
                rl.drawTextPro(
                    state.font,
                    "m",
                    mapCirclePos.add(.{ .x = -7, .y = -10 }),
                    .{ .x = 0, .y = 0 },
                    0.0,
                    20,
                    spacing,
                    .black,
                );
            }
        }
    }
};
