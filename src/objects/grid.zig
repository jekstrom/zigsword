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

    pub fn clearTextures(self: *@This()) void {
        self.textures.clearAndFree();
    }

    pub fn draw(self: @This(), cellSize: f32) void {
        _ = cellSize;
        const rownum = self.pos.y;
        const colnum = self.pos.x;

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
    }
};

pub const Grid = struct {
    // TODO: Calculate size of grid based on screen size
    pub const numCols: comptime_int = 22;
    pub const numRows: comptime_int = 16;
    pub const groundRowNum = numRows - 4;
    cellSize: i32,
    cells: [Grid.numRows][Grid.numCols]Cell,

    pub fn clearTextures(self: *@This()) void {
        for (0..@as(usize, @intCast(Grid.numRows))) |r| {
            for (0..@as(usize, @intCast(Grid.numCols))) |c| {
                self.cells[r][c].clearTextures();
            }
        }
    }

    pub fn getCenterPos(self: @This()) rl.Vector2 {
        return self.cells[numRows / 2][numCols / 2].pos;
    }

    pub fn getGroundCenterPos(self: @This()) rl.Vector2 {
        return self.cells[groundRowNum][numCols / 2].pos;
    }

    pub fn getGroundY(self: @This()) f32 {
        return groundRowNum * @as(f32, @floatFromInt(self.cellSize));
    }

    pub fn topUI(self: @This()) f32 {
        return self.cells[groundRowNum][0].pos.y + @as(f32, @floatFromInt(self.cellSize));
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
