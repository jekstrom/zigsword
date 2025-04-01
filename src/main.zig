const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");

pub var DEBUG_MODE = false;

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

        var thickness: f32 = 2;
        var color: rl.Color = .magenta;
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
        if (DEBUG_MODE) {
            var buffer: [8]u8 = std.mem.zeroes([8]u8);
            const s = std.fmt.bufPrintZ(
                &buffer,
                "{d},{d}",
                .{ rownum, colnum },
            ) catch "";

            rl.drawText(
                s,
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

        if (DEBUG_MODE) {
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
    pub const numCols: comptime_int = 21;
    pub const numRows: comptime_int = 16;
    cellSize: i32,
    cells: [Grid.numRows][Grid.numCols]Cell,

    pub fn draw(self: @This(), state: *State) void {
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

pub const Adventurer = struct {
    name: [:0]const u8,
    pos: rl.Vector2,
    nameKnown: bool,

    pub fn draw(self: @This(), state: *State) void {
        const textureWidth = 100;
        const textureHeight = 124;

        if (state.textureMap.get(.Adventurer)) |texture| {
            rl.drawTexturePro(
                texture,
                .{
                    .x = 0,
                    .y = 0,
                    .width = textureWidth,
                    .height = textureHeight,
                },
                .{
                    .height = textureHeight,
                    .width = textureWidth,
                    .x = self.pos.x,
                    .y = self.pos.y,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }
    }
};

pub const Player = struct {
    pos: rl.Vector2,
    equiped: bool,
    name: [:0]u8,

    pub fn draw(self: @This(), state: *State, rotation: f32) void {
        const textureOffset: rl.Rectangle = .{
            .height = 128,
            .width = 50,
            .x = 0,
            .y = 0,
        };
        if (state.textureMap.get(.Sword)) |texture| {
            rl.drawTexturePro(
                texture,
                textureOffset,
                .{
                    .x = self.pos.x,
                    .y = self.pos.y,
                    .width = 40,
                    .height = 100,
                },
                .{ .x = 0, .y = 0 },
                rotation,
                .white,
            );
        }
    }
};

pub const State = struct {
    player: Player,
    adventurer: Adventurer,
    grid: Grid,
    mousePos: rl.Vector2,
    textureMap: std.AutoHashMap(TextureType, rl.Texture),
    phase: GamePhase,

    pub fn NextPhase(self: @This()) GamePhase {
        var nextPhase: GamePhase = .START;
        if (self.phase == .START) {
            nextPhase = .PLAY;
        } else if (self.phase == .PLAY) {
            nextPhase = .DEATH;
        } else if (self.phase == .DEATH) {
            nextPhase = .END;
        }
        std.debug.print("Transitioning from phase {} to {}", .{ self.phase, nextPhase });
        return nextPhase;
    }
};

pub fn loadGroundTextures() !rl.Texture {
    return try loadTexture("resources/ground.png");
}

pub fn loadBackgroundTextures() !rl.Texture {
    return try loadTexture("resources/background.png");
}

pub fn loadTexture(path: [:0]const u8) !rl.Texture {
    const image = try rl.loadImage(path);
    const texture = try rl.loadTextureFromImage(image);
    rl.unloadImage(image);
    return texture;
}

pub fn drawUi(state: *State, topUI: f32) void {
    if (state.textureMap.get(.SwordIcon)) |texture| {
        rl.drawTexturePro(
            texture,
            .{
                .x = 0,
                .y = 0,
                .width = 2048,
                .height = 2048,
            },
            .{
                .x = 250,
                .y = topUI + 38,
                .width = 100,
                .height = 100,
            },
            .{ .x = 0, .y = 0 },
            0.0,
            .white,
        );
    }

    if (state.phase == .PLAY and state.player.name.len > 0) {
        rl.drawText(
            state.player.name,
            250,
            @as(i32, @intFromFloat(topUI)) + 15,
            20,
            .black,
        );
    }

    if (state.textureMap.get(.AdventurerIcon)) |texture| {
        rl.drawTexturePro(
            texture,
            .{
                .x = 0,
                .y = 0,
                .width = 100,
                .height = 124,
            },
            .{
                .x = 50,
                .y = topUI + 10,
                .width = 100,
                .height = 124,
            },
            .{ .x = 0, .y = 0 },
            0.0,
            .white,
        );
    }
    if (state.phase == .PLAY and state.adventurer.nameKnown and state.adventurer.name.len > 0) {
        rl.drawText(
            state.adventurer.name,
            50,
            @as(i32, @intFromFloat(topUI)) + 15,
            20,
            .black,
        );
    }

    if (state.textureMap.get(.HealthPip)) |texture| {
        for (0..5) |i| {
            rl.drawTexturePro(
                texture,
                .{
                    .x = 0,
                    .y = 0,
                    .width = 64,
                    .height = 64,
                },
                .{
                    .x = 170,
                    .y = topUI + 10 + (20 * @as(f32, @floatFromInt(i))),
                    .width = 16,
                    .height = 16,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }
    }

    if (state.textureMap.get(.DurabilityPip)) |texture| {
        for (0..5) |i| {
            rl.drawTexturePro(
                texture,
                .{
                    .x = 0,
                    .y = 0,
                    .width = 64,
                    .height = 64,
                },
                .{
                    .x = 250 + 150,
                    .y = topUI + 10 + (20 * @as(f32, @floatFromInt(i))),
                    .width = 16,
                    .height = 16,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }
    }

    if (state.textureMap.get(.EnergyPip)) |texture| {
        for (0..5) |i| {
            rl.drawTexturePro(
                texture,
                .{
                    .x = 0,
                    .y = 0,
                    .width = 64,
                    .height = 64,
                },
                .{
                    .x = 250 + 150 + 70,
                    .y = topUI + 10 + (20 * @as(f32, @floatFromInt(i))),
                    .width = 16,
                    .height = 16,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }
    }
}

const TextureType = enum(u8) {
    SwordIcon,
    AdventurerIcon,
    Adventurer,
    HealthPip,
    DurabilityPip,
    EnergyPip,
    Sword,
};

const GamePhase = enum(u8) {
    START,
    PLAY,
    DEATH,
    END,
};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1024;
    const screenHeight = 768;
    const gameName = "zigsword";
    rl.initWindow(screenWidth, screenHeight, gameName);
    defer rl.closeWindow(); // Close window and OpenGL context

    std.debug.print("\n\nRAYLIB VERSION {s}\n", .{rl.RAYLIB_VERSION});
    std.debug.print("GAME START {s} {}\n\n", .{ gameName, std.time.timestamp() });

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();

    const List = std.ArrayList(CellTexture);

    const texture = try loadGroundTextures();
    defer rl.unloadTexture(texture);

    const background = try loadBackgroundTextures();
    defer rl.unloadTexture(background);

    const swordIcon = try loadTexture("resources/sword_icon.png");
    defer rl.unloadTexture(swordIcon);

    const adventurerIcon = try loadTexture("resources/adventurer_icon2.png");
    defer rl.unloadTexture(adventurerIcon);

    const adventurer = try loadTexture("resources/adventurer_icon2.png");
    defer rl.unloadTexture(adventurer);

    const pipIcon = try loadTexture("resources/Pip.png");
    defer rl.unloadTexture(pipIcon);

    const pipDurabilityIcon = try loadTexture("resources/Pipdurability.png");
    defer rl.unloadTexture(pipDurabilityIcon);

    const pipEnergyIcon = try loadTexture("resources/Pipenergy.png");
    defer rl.unloadTexture(pipEnergyIcon);

    const sword = try loadTexture("resources/sword1.png");
    defer rl.unloadTexture(sword);

    var map = std.AutoHashMap(TextureType, rl.Texture).init(allocator);
    defer map.deinit();

    try map.put(.SwordIcon, swordIcon);
    try map.put(.AdventurerIcon, adventurerIcon);
    try map.put(.Adventurer, adventurer);
    try map.put(.HealthPip, pipIcon);
    try map.put(.DurabilityPip, pipDurabilityIcon);
    try map.put(.EnergyPip, pipEnergyIcon);
    try map.put(.Sword, sword);

    var state: State = .{
        .phase = .START,
        .player = .{
            .pos = .{ .x = 0, .y = 0 },
            .equiped = false,
            .name = undefined,
        },
        .adventurer = .{
            .name = "Zig",
            .pos = .{ .x = 0, .y = 0 },
            .nameKnown = false,
        },
        .mousePos = .{ .x = 0, .y = 0 },
        .textureMap = map,
        .grid = .{
            .cellSize = 48,
            .cells = [_][Grid.numCols]Cell{
                [_]Cell{.{
                    .id = 0,
                    .hover = false,
                    .pos = .{ .x = 0, .y = 0 },
                    .textures = List.init(allocator),
                }} ** Grid.numCols,
            } ** Grid.numRows,
        },
    };

    const camera = rl.Camera2D{
        .offset = .{ .x = 0, .y = 0 },
        .target = .{ .x = 0, .y = 0 },
        .zoom = 1.0,
        .rotation = 0.0,
    };

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    var newName: [10:0]u8 = std.mem.zeroes([10:0]u8);

    // add ground textures
    for (0..Grid.numCols) |i| {
        const textureWidth = 215;
        const textureHeight = 250;
        const widthTextureOffset = rand.intRangeAtMost(u16, 0, 1) * textureWidth;
        const widthHeightOffset = rand.intRangeAtMost(u16, 0, 1) * textureHeight;
        const offsetRect = rl.Rectangle.init(
            @floatFromInt(widthTextureOffset),
            @floatFromInt(widthHeightOffset),
            @floatFromInt(textureWidth),
            @floatFromInt(textureHeight),
        );

        if (rand.boolean()) {
            const rockWidthTextureOffset = rand.intRangeAtMost(u16, 0, 1) * textureWidth;
            const rockHeightTextureOffset = rand.intRangeAtMost(u16, 0, 1) * textureHeight + 500;
            const rockOffsetRect = rl.Rectangle.init(
                @floatFromInt(rockWidthTextureOffset),
                @floatFromInt(rockHeightTextureOffset),
                @floatFromInt(textureWidth),
                @floatFromInt(textureHeight),
            );
            try state.grid.cells[state.grid.cells.len - 4][i].textures.append(.{
                .texture = texture,
                .textureOffset = rockOffsetRect,
                .displayOffset = .{
                    .x = 0,
                    .y = @as(f32, @floatFromInt(rand.intRangeAtMost(u16, 0, 20))) * -1 - 10.0,
                },
                .zLevel = 1,
            });
        }

        try state.grid.cells[state.grid.cells.len - 4][i].textures.append(.{
            .texture = texture,
            .textureOffset = offsetRect,
            .displayOffset = .{ .x = 0, .y = 0 },
            .zLevel = 0,
        });
    }

    const groundY = (state.grid.cells.len - 4) * @as(f32, @floatFromInt(state.grid.cellSize));

    state.adventurer.pos = .{ .x = 0, .y = groundY - 110 };

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------1------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------
        const gameTime = rl.getTime();
        const dt = rl.getFrameTime();
        const mousePos = rl.getMousePosition();

        if (gameTime > 30) {
            std.debug.print("resetting game. current state: {}\n", .{state.phase});
            break;
        }

        const bottom = state.grid.cells[state.grid.cells.len - 4][0].pos.y - screenHeight + @as(f32, @floatFromInt(state.grid.cellSize));
        const topUI = state.grid.cells[state.grid.cells.len - 4][0].pos.y + @as(f32, @floatFromInt(state.grid.cellSize));
        const uiHeight = screenHeight - topUI;
        const uiRect: rl.Rectangle = .{ .height = uiHeight, .width = screenWidth, .x = 0, .y = topUI };

        state.player.pos.x = screenWidth / 2;
        if (state.player.pos.y < groundY + 25) {
            state.player.pos.y += 250 * dt;
        }
        state.mousePos = mousePos;

        var playerRotation: f32 = 180.0;
        if (state.adventurer.pos.x < state.player.pos.x - 95) {
            state.adventurer.pos.x += 90 * dt;
        } else if (state.phase == .START) {
            state.player.equiped = true;
            state.phase = state.NextPhase();
        }

        if (state.player.equiped) {
            playerRotation = 0.0;
            state.player.pos.y = state.adventurer.pos.y;
            state.adventurer.nameKnown = true;
        }

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.beginMode2D(camera);
        defer rl.endMode2D();

        rl.clearBackground(.white);

        rl.drawTexturePro(
            background,
            .{
                .x = 0,
                .y = 0,
                .width = 2046,
                .height = 1591,
            },
            .{
                .x = 0,
                .y = bottom,
                .width = screenWidth,
                .height = screenHeight,
            },
            .{ .x = 0, .y = 0 },
            0.0,
            .white,
        );

        if (ui.guiButton(.{ .x = 50, .y = 50, .height = 45, .width = 100 }, "DEBUG") > 0) {
            DEBUG_MODE = !DEBUG_MODE;
        }

        _ = ui.guiDummyRec(
            uiRect,
            "",
        );

        drawUi(&state, topUI);

        if (ui.guiButton(.{ .x = 160, .y = 50, .height = 45, .width = 100 }, "Exit") > 0) {
            break;
        }

        rl.clearBackground(.white);

        if (state.phase == .START) {
            rl.drawText(
                "   YOU",
                @as(i32, @intFromFloat(state.player.pos.x - 30)),
                @as(i32, @intFromFloat(state.player.pos.y - 100)),
                20,
                .light_gray,
            );
        }

        if (state.phase == .PLAY) {
            const messageRect: rl.Rectangle = .{
                .height = 200,
                .width = 500,
                .x = (screenWidth - 500) / 2,
                .y = (screenHeight - groundY) / 2,
            };

            if (state.player.name.len == 0) {
                if (ui.guiTextInputBox(
                    messageRect,
                    "PLAYER NAME",
                    "What do they call you?",
                    "accept",
                    &newName,
                    10,
                    null,
                ) > 0) {
                    state.player.name = &newName;
                }
            }
        }

        state.player.draw(&state, playerRotation);
        state.grid.draw(&state);
        state.adventurer.draw(&state);

        if (DEBUG_MODE) {
            rl.drawFPS(25, 25);
        }
        //----------------------------------------------------------------------------------
    }

    for (0..@as(usize, @intCast(Grid.numRows))) |r| {
        for (0..@as(usize, @intCast(Grid.numCols))) |c| {
            state.grid.cells[r][c].textures.deinit();
        }
    }
}
