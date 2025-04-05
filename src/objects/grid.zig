const rl = @import("raylib");
const std = @import("std");
const s = @import("state.zig");

pub const CellTexture = struct {
    texture: ?rl.Texture,
    textureOffset: ?rl.Rectangle,
    displayOffset: rl.Vector2,
    zLevel: i32,

    pub fn cmpByZ(context: void, a: CellTexture, b: CellTexture) bool {
        _ = context;
        if (a.zLevel < b.zLevel) {
            return true;
        } else {
            return false;
        }
    }
};

pub const Cell = struct {
    id: i32,
    hover: bool,
    pos: rl.Vector2,
    textures: std.ArrayList(CellTexture),

    pub fn draw(self: @This(), cellSize: f32) void {
        const rownum = self.pos.y;
        const colnum = self.pos.x;

        var thickness: f32 = 1;
        var color: rl.Color = .gray;
        if (self.hover) {
            thickness = 4;
            color = .green;
        }

        if (self.textures.items.len > 0) {
            std.mem.sort(
                CellTexture,
                self.textures.items,
                {},
                comptime CellTexture.cmpByZ,
            );
        }

        for (self.textures.items) |item| {
            if (item.texture != null and item.textureOffset != null) {
                rl.drawTexturePro(
                    item.texture.?,
                    item.textureOffset.?,
                    .{
                        .x = colnum + item.displayOffset.x,
                        .y = rownum + item.displayOffset.y,
                        .width = 48,
                        .height = 48,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .white,
                );
            }
        }
        if (s.DEBUG_MODE) {
            var buffer: [8]u8 = std.mem.zeroes([8]u8);
            const sx = std.fmt.bufPrintZ(
                &buffer,
                "{d},{d}",
                .{ rownum, colnum },
            ) catch "";

            rl.drawText(
                sx,
                @as(i32, @intFromFloat(colnum)),
                @as(i32, @intFromFloat(rownum)),
                8,
                color,
            );

            buffer = std.mem.zeroes([8]u8);
            const s2 = std.fmt.bufPrintZ(
                &buffer,
                "{d}",
                .{self.id},
            ) catch "";

            rl.drawText(
                s2,
                @as(i32, @intFromFloat(colnum)) + 2,
                @as(i32, @intFromFloat(rownum)) + 10,
                8,
                color,
            );
        }

        if (s.DEBUG_MODE) {
            rl.drawLineEx(
                .{ .x = colnum, .y = rownum },
                .{ .x = colnum + cellSize, .y = rownum },
                thickness,
                color,
            );
            rl.drawLineEx(
                .{ .x = colnum + cellSize, .y = rownum },
                .{ .x = colnum + cellSize, .y = rownum + cellSize },
                thickness,
                color,
            );
            rl.drawLineEx(
                .{ .x = colnum + cellSize, .y = rownum + cellSize },
                .{ .x = colnum, .y = rownum + cellSize },
                thickness,
                color,
            );
            rl.drawLineEx(
                .{ .x = colnum, .y = rownum + cellSize },
                .{ .x = colnum, .y = rownum },
                thickness,
                color,
            );
        }
    }
};

pub const Grid = struct {
    // TODO: Calculate size of grid based on screen size
    pub const numCols: comptime_int = 22;
    pub const numRows: comptime_int = 16;
    pub const groundRowNum = numRows - 4;
    cellSize: i32,
    cells: [Grid.numRows][Grid.numCols]Cell,

    pub fn getCenterPos(self: @This()) rl.Vector2 {
        return self.cells[numRows / 2][numCols / 2].pos;
    }

    pub fn getGroundCenterPos(self: @This()) rl.Vector2 {
        return self.cells[groundRowNum][numCols / 2].pos;
    }

    pub fn getGroundY(self: @This()) f32 {
        return groundRowNum * @as(f32, @floatFromInt(self.cellSize));
    }

    pub fn getWidth(self: @This()) f32 {
        return numCols * @as(f32, @floatFromInt(self.cellSize));
    }

    pub fn getHeight(self: @This()) f32 {
        return numRows * @as(f32, @floatFromInt(self.cellSize));
    }

    pub fn draw(self: @This(), state: *s.State) void {
        var hovered: ?*Cell = null;
        var cellId: i32 = 0;
        for (0..@as(usize, @intCast(Grid.numRows))) |r| {
            const cellSize: f32 = @as(f32, @floatFromInt(self.cellSize));
            const rownum = @as(f32, @floatFromInt(r)) * cellSize;
            for (0..@as(usize, @intCast(Grid.numCols))) |c| {
                const colnum = @as(f32, @floatFromInt(c)) * cellSize;
                const cellPos: rl.Vector2 = .{ .x = colnum, .y = rownum };
                state.grid.cells[r][c].pos = cellPos;
                cellId += 1;
                state.grid.cells[r][c].id = cellId;

                if (state.mousePos.x <= colnum + cellSize and state.mousePos.y <= rownum + cellSize and state.mousePos.x >= colnum and state.mousePos.y >= rownum) {
                    state.grid.cells[r][c].hover = true;
                } else {
                    state.grid.cells[r][c].hover = false;
                }

                if (!state.grid.cells[r][c].hover) {
                    state.grid.cells[r][c].draw(cellSize);
                } else {
                    hovered = &state.grid.cells[r][c];
                }
            }
        }

        if (hovered != null) {
            hovered.?.draw(@as(f32, @floatFromInt(self.cellSize)));
        }
    }
};
