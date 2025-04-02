const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("objects/state.zig");
const g = @import("objects/grid.zig");
const p = @import("objects/player.zig");
const a = @import("objects/adventurer.zig");
const enums = @import("enums.zig");

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

pub fn drawUi(state: *s.State, topUI: f32) void {
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

pub fn concatStrings(allocator: std.mem.Allocator, str1: [:0]const u8, str2: [:0]const u8) ![:0]u8 {
    const len1 = str1.len;
    const len2 = str2.len;

    var chars1: usize = 0;
    for (0..len1) |i| {
        if (str1[i] > 0) {
            chars1 += 1;
        }
    }

    var chars2: usize = 0;
    for (0..len2) |i| {
        if (str2[i] > 0) {
            chars2 += 1;
        }
    }

    const totalContentLen = chars1 + chars2;

    const result = try allocator.allocSentinel(u8, totalContentLen, 0);
    errdefer allocator.free(result);

    @memcpy(result.ptr[0..chars1], str1.ptr[0..chars1]);
    @memcpy(result.ptr[chars1 .. chars1 + chars2], str2.ptr[0..chars2]);
    return result;
}

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

    const List = std.ArrayList(g.CellTexture);

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

    var map = std.AutoHashMap(enums.TextureType, rl.Texture).init(allocator);
    defer map.deinit();

    try map.put(.SwordIcon, swordIcon);
    try map.put(.AdventurerIcon, adventurerIcon);
    try map.put(.Adventurer, adventurer);
    try map.put(.HealthPip, pipIcon);
    try map.put(.DurabilityPip, pipDurabilityIcon);
    try map.put(.EnergyPip, pipEnergyIcon);
    try map.put(.Sword, sword);

    var state: s.State = .{
        .phase = .START,
        .mode = .PAUSE,
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
            .cells = [_][g.Grid.numCols]g.Cell{
                [_]g.Cell{.{
                    .id = 0,
                    .hover = false,
                    .pos = .{ .x = 0, .y = 0 },
                    .textures = List.init(allocator),
                }} ** g.Grid.numCols,
            } ** g.Grid.numRows,
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
    for (0..g.Grid.numCols) |i| {
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
    var tutorialStep: u4 = 0;

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
            s.DEBUG_MODE = !s.DEBUG_MODE;
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

        if (tutorialStep < 4) {
            try tutorial(
                &state,
                screenWidth,
                screenHeight,
                groundY,
                &tutorialStep,
                &newName,
                &allocator,
            );
        }
        if (tutorialStep >= 4) {
            state.mode = .WALKING;
        }

        state.player.draw(&state, playerRotation);
        state.grid.draw(&state);
        state.adventurer.draw(&state);

        if (s.DEBUG_MODE) {
            rl.drawFPS(25, 25);
        }
        //----------------------------------------------------------------------------------
    }

    for (0..@as(usize, @intCast(g.Grid.numRows))) |r| {
        for (0..@as(usize, @intCast(g.Grid.numCols))) |c| {
            state.grid.cells[r][c].textures.deinit();
        }
    }
}

pub fn tutorial(
    state: *s.State,
    screenWidth: comptime_int,
    screenHeight: comptime_int,
    groundY: f32,
    tutorialStep: *u4,
    newName: *[10:0]u8,
    allocator: *const std.mem.Allocator,
) !void {
    if (state.phase == .PLAY) {
        const messageRect: rl.Rectangle = .{
            .height = 200,
            .width = 500,
            .x = (screenWidth - 500) / 2,
            .y = (screenHeight - groundY) / 2,
        };

        if (tutorialStep.* == 0) {
            if (ui.guiMessageBox(
                messageRect,
                "YOU",
                "Greetings Adventurer!",
                "next",
            ) > 0) {
                tutorialStep.* = 1;
                return;
            }
            state.player.drawPortrait(
                state,
                .{
                    .height = 60,
                    .width = 20,
                    .x = messageRect.x + 10,
                    .y = messageRect.y + 30,
                },
            );
        }

        if (tutorialStep.* == 1 and state.player.name.len == 0) {
            const messageRect2: rl.Rectangle = .{
                .height = 200,
                .width = 500,
                .x = (screenWidth - 500) / 2,
                .y = (screenHeight - groundY) / 2,
            };
            if (ui.guiTextInputBox(
                messageRect2,
                "ADVENTURER",
                "Woah, a talking sword! What do they call you?",
                "next",
                newName,
                10,
                null,
            ) > 0) {
                state.player.name = newName;
                tutorialStep.* = 2;
                return;
            }

            state.adventurer.drawPortrait(
                state,
                .{
                    .height = 60,
                    .width = 60,
                    .x = messageRect.x + 10,
                    .y = messageRect.y + 30,
                },
            );
        }

        if (tutorialStep.* == 2 and state.player.name.len > 0) {
            var buffer: [13 + 10:0]u8 = std.mem.zeroes([13 + 10:0]u8);
            _ = std.fmt.bufPrint(
                &buffer,
                "They call me {s}.",
                .{state.player.name},
            ) catch "";

            if (ui.guiMessageBox(
                messageRect,
                state.player.name,
                &buffer,
                "next",
            ) > 0) {
                tutorialStep.* = 3;
                return;
            }
            state.player.drawPortrait(
                state,
                .{
                    .height = 60,
                    .width = 20,
                    .x = messageRect.x + 10,
                    .y = messageRect.y + 30,
                },
            );
        }

        if (tutorialStep.* == 3 and state.player.name.len > 0) {
            const sx = try concatStrings(
                allocator.*,
                state.player.name,
                "? stange name for a sword. Let's go!",
            );
            defer allocator.free(sx);
            if (ui.guiMessageBox(
                messageRect,
                "ADVENTURER",
                sx,
                "next",
            ) > 0) {
                tutorialStep.* = 4;
                return;
            }
            state.adventurer.drawPortrait(
                state,
                .{
                    .height = 60,
                    .width = 60,
                    .x = messageRect.x + 10,
                    .y = messageRect.y + 30,
                },
            );
        }
    }
}
