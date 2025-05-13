const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const sm = @import("smState.zig");
const MapSide = @import("../enums.zig").MapSide;
const MapNode = @import("../map/map.zig").MapNode;
const Map = @import("../map/map.zig").Map;

// Tracks behavior in the main menu
pub const MapMenuState = struct {
    nextState: ?*sm.SMState,
    startTime: f64,
    isComplete: bool,
    selectedMap: u8,

    pub fn getIsComplete(ptr: *anyopaque) anyerror!bool {
        const self: *MapMenuState = @ptrCast(@alignCast(ptr));
        return self.isComplete;
    }

    pub fn enter(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *MapMenuState = @ptrCast(@alignCast(ptr));

        self.selectedMap = 0;
        _ = state;
    }

    pub fn exit(ptr: *anyopaque, state: *s.State) anyerror!void {
        _ = ptr;
        _ = state;
    }

    pub fn update(ptr: *anyopaque, state: *s.State) anyerror!void {
        const self: *MapMenuState = @ptrCast(@alignCast(ptr));

        const headerText = "Select path or accept adventurer's path";
        const txtSize = rl.measureTextEx(state.font, headerText, 20, 2);

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

        if (state.mapMenuInputActive) {
            rl.drawTextPro(
                state.font,
                headerText,
                state.grid.getCenterPos(),
                .{ .x = txtSize.x / 2, .y = -200 },
                0.0,
                20,
                2,
                .white,
            );
        }

        if (state.map == null) {
            return;
        }

        const currentMap: ?*Map = state.map.?;

        self.drawTree(currentMap.?, null, state, 0.0, .center);

        if (ui.guiButton(.{ .x = state.grid.getWidth() - 250, .y = state.grid.getHeight() - 80, .height = 40, .width = 100 }, "Go") > 0) {
            if (self.selectedMap > 0) {
                state.selectedMap = self.selectedMap;
            }
            std.debug.print("Setting map to selected map {d}\n", .{state.selectedMap});
            state.mapMenuInputActive = false;
            self.isComplete = true;
            self.selectedMap = 0;
        }
    }

    // Recursively draw nodes centered on the previous node
    fn drawTree(self: *@This(), map: *Map, parent: ?rl.Vector2, state: *s.State, depth: f32, side: MapSide) void {
        const parentPos = self.drawMap(map, parent, state, depth, side);

        if (map.left != null) {
            self.drawTree(map.left.?, parentPos, state, depth + 1, .left);
        }
        if (map.right != null) {
            self.drawTree(map.right.?, parentPos, state, depth + 1, .right);
        }
    }

    fn drawMap(self: *@This(), map: *Map, parentPos: ?rl.Vector2, state: *s.State, depth: f32, side: MapSide) rl.Vector2 {
        const yoffset = 130.0;
        const center = state.grid.getCenterPos();
        const txtSize = rl.measureTextEx(state.font, map.name, 30, 2);

        var txtPos: rl.Vector2 = .{
            .x = 0,
            .y = center.y - (txtSize.y / 2) - 200 + yoffset * depth,
        };

        if (side == .center) {
            txtPos = txtPos.add(.{
                .x = center.x,
                .y = 0,
            });
        }
        if (parentPos != null) {
            if (side == .left) {
                txtPos = txtPos.add(.{
                    .x = parentPos.?.x - txtSize.x,
                    .y = 0,
                });
            } else if (side == .right) {
                txtPos = txtPos.add(.{
                    .x = parentPos.?.x + txtSize.x,
                    .y = 0,
                });
            }
        }

        const mousepos = rl.getMousePosition();

        const collisionRect = rl.Rectangle.init(
            txtPos.x - (txtSize.x / 2),
            txtPos.y + (txtSize.y / 4),
            txtSize.x,
            txtSize.y,
        );

        const hover = collisionRect.checkCollision(.{
            .x = mousepos.x,
            .y = mousepos.y,
            .height = 2,
            .width = 2,
        });
        var color: rl.Color = .white;

        if (state.mapMenuInputActive and hover) {
            color = .gray;
            if (parentPos != null) {
                const endPos: rl.Vector2 = .{
                    .x = parentPos.?.x,
                    .y = parentPos.?.y + txtSize.y + 35,
                };
                rl.drawLineEx(
                    .{
                        .x = collisionRect.x + (collisionRect.width / 2),
                        .y = collisionRect.y,
                    },
                    endPos,
                    5.0,
                    .green,
                );
            }
            if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
                self.selectedMap = map.currentMapCount;
            }
        }

        if (map.currentMapCount == self.selectedMap) {
            if (parentPos != null) {
                const endPos: rl.Vector2 = .{
                    .x = parentPos.?.x,
                    .y = parentPos.?.y + txtSize.y + 35,
                };
                rl.drawLineEx(
                    .{
                        .x = collisionRect.x + (collisionRect.width / 2),
                        .y = collisionRect.y,
                    },
                    endPos,
                    5.0,
                    .red,
                );
            }
        }

        if (s.DEBUG_MODE) {
            rl.drawCircleV(txtPos, 3.0, .magenta);
            rl.drawRectangleRec(collisionRect, .magenta);
        }

        rl.drawTextPro(
            state.font,
            map.name,
            txtPos,
            .{ .x = txtSize.x / 2, .y = 0 },
            0.0,
            30,
            2,
            color,
        );

        if (depth == 1 and side == state.adventurer.nextMap) {
            rl.drawLineEx(
                .{
                    .x = collisionRect.x + (collisionRect.width / 2),
                    .y = collisionRect.y,
                },
                .{
                    .x = parentPos.?.x,
                    .y = parentPos.?.y + txtSize.y + 35,
                },
                5.0,
                .white,
            );
        }

        const mid: f32 = -@as(f32, @floatFromInt(map.nodes.items.len - 1)) / 2;
        for (0.., map.nodes.items) |i, node| {
            const mapCirclePos: rl.Vector2 = .{
                .x = txtPos.x + (mid + @as(f32, @floatFromInt(i))) * 75.0,
                .y = txtPos.y + 70,
            };

            if (i < map.nodes.items.len - 1) {
                rl.drawLineEx(
                    mapCirclePos,
                    mapCirclePos.add(.{
                        .x = 75,
                        .y = 0,
                    }),
                    5.0,
                    .white,
                );
            }

            self.drawNode(node, mapCirclePos, state.currentNode == i and state.currentMap == map.currentMapCount, state);
        }

        return txtPos;
    }

    fn drawNode(self: *@This(), node: MapNode, mapCirclePos: rl.Vector2, isCurrentNode: bool, state: *s.State) void {
        _ = self;
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

        const spacing = 2;

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

    pub fn smState(self: *MapMenuState, allocator: *const std.mem.Allocator) !*sm.SMState {
        return try sm.SMState.init(self, .MAPMENU, self.nextState, allocator);
    }
};
