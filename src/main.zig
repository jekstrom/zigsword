const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("objects/state.zig");
const g = @import("objects/grid.zig");
const p = @import("objects/player.zig");
const a = @import("objects/adventurer.zig");
const w = @import("walkingevent.zig");
const e = @import("events/altar.zig");
const ah = @import("altarHistory.zig");
const m = @import("map/map.zig");
const mob = @import("objects/monster.zig");
const enums = @import("enums.zig");
const d = @import("die.zig");

pub fn loadGroundTextures() !rl.Texture {
    return try loadTexture("resources/ground_small.png");
}

pub fn loadDungeonGroundTextures() !rl.Texture {
    return try loadTexture("resources/dungeon.png");
}

pub fn loadBackgroundTextures() !rl.Texture {
    return try loadTexture("resources/background.png");
}

pub fn loadDungeonBackgroundTextures() !rl.Texture {
    return try loadTexture("resources/dungeon_background.png");
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

    if (state.player.name.len > 0) {
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
    if (state.adventurer.nameKnown and state.adventurer.name.len > 0) {
        rl.drawText(
            state.adventurer.name,
            50,
            @as(i32, @intFromFloat(topUI)) + 15,
            20,
            .black,
        );
    }

    if (state.textureMap.get(.HealthPip)) |texture| {
        const numberOfPips = 5;

        const healthRatio = 100 / numberOfPips;
        const health = state.adventurer.health / healthRatio;
        for (0..health) |i| {
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
                    .y = (topUI + 100) - 10 - (20 * @as(f32, @floatFromInt(i))),
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
        const numberOfPips = 5;

        const durabilityRatio = 100 / numberOfPips;
        const durability = state.player.durability / durabilityRatio;
        for (0..durability) |i| {
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
                    .y = (topUI + 100) - 10 - (20 * @as(f32, @floatFromInt(i))),
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
                    .y = (topUI + 100) - 10 - (20 * @as(f32, @floatFromInt(i))),
                    .width = 16,
                    .height = 16,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }
    }

    if (state.textureMap.get(.D4)) |texture| {
        for (0..state.player.dice.?.items.len) |i| {
            rl.drawTexturePro(
                texture,
                .{
                    .x = 0,
                    .y = 0,
                    .width = 64,
                    .height = 64,
                },
                .{
                    .x = 250 + 150 + 70 + 50 + (50 * @as(f32, @floatFromInt(i))),
                    .y = (topUI + 20) - 10,
                    .width = 64,
                    .height = 64,
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

pub fn generateNextMap(state: *s.State, name: [:0]const u8, nodeType: m.MapNodeType) !void {
    // Generate a new map using seed from State.
    // Maps should all contain the same number of nodes but
    // what each node consists of should be random.

    const List = std.ArrayList(m.MapNode);
    const MonsterList = std.ArrayList(mob.Monster);

    const numWalkingNodes = state.rand.intRangeAtMost(
        u4,
        2,
        4,
    );

    var newMap = try state.allocator.create(m.Map);

    newMap.currentMapCount = 1;
    newMap.name = name;
    newMap.nodes = List.init(state.allocator);
    newMap.nextMap = null;

    // TODO: Deallocate maps and nodes

    for (0..numWalkingNodes) |i| {
        // Create new nodes for the map, assigning a name.
        const baseName = "Map Node ";
        var floatLog: f16 = 1.0;
        if (i > 0) {
            floatLog = @floor(@log10(@as(f16, @floatFromInt(i))) + 1.0);
        }
        const digits: u64 = @as(u64, @intFromFloat(floatLog));
        const buffer = try state.allocator.allocSentinel(
            u8,
            baseName.len + digits,
            0,
        );
        _ = std.fmt.bufPrint(
            buffer,
            "{s}{d}",
            .{ baseName, i },
        ) catch "";

        if (nodeType == .WALKING) {
            var outsideNode: m.MapNode = .{
                .name = buffer,
                .type = nodeType,
                .texture = state.textureMap.get(.OUTSIDEGROUND),
                .background = state.textureMap.get(.OUTSIDEBACKGROUND),
                .monsters = null,
                .altarEvent = null,
            };
            try outsideNode.init(state);
            try newMap.addMapNode(outsideNode);
        } else if (nodeType == .DUNGEON) {
            var dungeonNode: m.MapNode = .{
                .name = buffer,
                .type = nodeType,
                .texture = state.textureMap.get(.DUNGEONGROUND),
                .background = state.textureMap.get(.DUNGEONBACKGROUND),
                .monsters = MonsterList.init(state.allocator),
                .altarEvent = null,
            };
            try dungeonNode.init(state);
            try newMap.addMapNode(dungeonNode);
        }
    }

    if (state.map) |_| {
        // try state.map.?.addMap(state, "", newMap.nodes);
        std.debug.print("Adding next map\n", .{});
        newMap.currentMapCount = state.map.?.currentMapCount + 1;
        state.map.?.nextMap = newMap;
    } else {
        newMap.currentMapCount = 1;
        state.map = newMap.*;
    }
}

pub fn goToNextMap(state: *s.State) void {
    if (state.map.?.nextMap) |nm| {
        state.map = nm.*;
        state.currentMap = state.map.?.currentMapCount;
        state.currentNode = 0;
        state.grid.clearTextures();
    }
}

pub fn goToNextMapNode(state: *s.State) void {
    if (state.map) |map| {
        const numnodes = map.nodes.items.len;
        if ((state.currentNode + 1) >= numnodes) {
            state.currentNode = 0;
            std.debug.print("Resetting map node {d}\n", .{state.currentNode});
            goToNextMap(state);
        } else {
            state.currentNode += 1;
            std.debug.print("Going to map node {d}\n", .{state.currentNode});
        }
    } else {
        std.debug.print("no map found\n", .{});
        std.debug.assert(false);
    }
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1024;
    const screenHeight = 768;
    const gameName = "Slicen Dice";
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
    const AltarHistoryList = std.ArrayList(ah.AltarHistory);
    const DiceList = std.ArrayList(d.Die);

    const texture = try loadGroundTextures();
    defer rl.unloadTexture(texture);

    const dungeonGroundtexture = try loadDungeonGroundTextures();
    defer rl.unloadTexture(dungeonGroundtexture);

    const background = try loadBackgroundTextures();
    defer rl.unloadTexture(background);

    const dungeonBackground = try loadDungeonBackgroundTextures();
    defer rl.unloadTexture(dungeonBackground);

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

    const sword = try loadTexture("resources/sword.png");
    defer rl.unloadTexture(sword);

    const goodAltar = try loadTexture("resources/good_altar.png");
    defer rl.unloadTexture(goodAltar);

    const evilAltar = try loadTexture("resources/evil_altar.png");
    defer rl.unloadTexture(evilAltar);

    const greenGoblin = try loadTexture("resources/green_goblin.png");
    defer rl.unloadTexture(greenGoblin);

    const redGoblin = try loadTexture("resources/red_goblin.png");
    defer rl.unloadTexture(redGoblin);

    const d4 = try loadTexture("resources/d4.png");
    defer rl.unloadTexture(d4);

    var map = std.AutoHashMap(enums.TextureType, rl.Texture).init(allocator);
    defer map.deinit();

    try map.put(.SwordIcon, swordIcon);
    try map.put(.AdventurerIcon, adventurerIcon);
    try map.put(.Adventurer, adventurer);
    try map.put(.HealthPip, pipIcon);
    try map.put(.DurabilityPip, pipDurabilityIcon);
    try map.put(.EnergyPip, pipEnergyIcon);
    try map.put(.Sword, sword);
    try map.put(.OUTSIDEGROUND, texture);
    try map.put(.DUNGEONGROUND, dungeonGroundtexture);
    try map.put(.OUTSIDEBACKGROUND, background);
    try map.put(.DUNGEONBACKGROUND, dungeonBackground);
    try map.put(.GOODALTAR, goodAltar);
    try map.put(.EVILALTAR, evilAltar);
    try map.put(.GREENGOBLIN, greenGoblin);
    try map.put(.REDGOBLIN, redGoblin);
    try map.put(.D4, d4);

    const seed: u64 = 1338;

    // Uncomment to use os rand
    // std.posix.getrandom(std.mem.asBytes(&seed)) catch |err| {
    //     std.debug.print("Failed to get random seed: {}\n", .{err});
    //     return;
    // };

    var prng = std.Random.DefaultPrng.init(seed);
    const rand = prng.random();

    var state: s.State = .{
        .phase = .START,
        .mode = .TUTORIAL,
        .turn = .ENVIRONMENT,
        .currentMap = 0,
        .currentNode = 0,
        .player = .{
            .pos = .{ .x = 0, .y = 0 },
            .equiped = false,
            .name = undefined,
            .alignment = .GOOD,
            .altarHistory = null,
            .blessed = false,
            .dice = null,
            .durability = 100,
        },
        .adventurer = .{
            .name = "Zig",
            .pos = .{ .x = 0, .y = 0 },
            .nameKnown = false,
            .speed = 0.25,
            .health = 100,
        },
        .map = null,
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
        .allocator = allocator,
        .rand = rand,
        .randomNumbers = [_][g.Grid.numCols]u16{[_]u16{0} ** g.Grid.numCols} ** g.Grid.numRows,
    };

    for (0..g.Grid.numRows) |r| {
        for (0..g.Grid.numCols) |c| {
            state.randomNumbers[r][c] = state.rand.intRangeAtMost(u16, 0, 65535);
        }
    }

    state.grid.draw(&state);

    try generateNextMap(&state, "Start", .WALKING);
    try generateNextMap(&state, "Dungeon", .DUNGEON);
    state.map.?.print();
    state.currentMap = state.map.?.currentMapCount;
    std.debug.print("current map: {d}", .{state.currentMap});
    std.debug.print(" {s}\n", .{state.map.?.name});

    const groundY = state.grid.getGroundY();
    var newName: [10:0]u8 = std.mem.zeroes([10:0]u8);

    state.adventurer.pos = .{ .x = 0, .y = groundY - 110 };
    var tutorialStep: u4 = 0;

    state.player.altarHistory = AltarHistoryList.init(allocator);
    state.player.dice = DiceList.init(allocator);
    var dcount: u8 = 0;
    while (dcount < 4) : (dcount += 1) {
        try state.player.dice.?.append(.{
            .name = "Basic d4",
            .sides = 4,
        });
    }

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

        if (gameTime > 300) {
            std.debug.print("resetting game. current state: {}\n", .{state.phase});
            break;
        }

        const topUI = state.grid.cells[state.grid.cells.len - 4][0].pos.y + @as(f32, @floatFromInt(state.grid.cellSize));
        const uiHeight = screenHeight - topUI;
        const uiRect: rl.Rectangle = .{ .height = uiHeight, .width = screenWidth, .x = 0, .y = topUI };

        state.player.pos.x = screenWidth / 2;
        if (state.player.pos.y < groundY + 25) {
            state.player.pos.y += 250 * dt;
        }
        state.mousePos = mousePos;

        var playerRotation: f32 = 180.0;
        const entered = state.adventurer.enter(&state, dt);

        if (entered and state.phase == .START) {
            state.player.equiped = true;
        }

        if (state.player.equiped) {
            playerRotation = 0.0;
            state.player.pos.y = state.adventurer.pos.y;
        }

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        try state.drawCurrentMapNode();

        if (ui.guiButton(.{ .x = 50, .y = 50, .height = 45, .width = 100 }, "DEBUG") > 0) {
            s.DEBUG_MODE = !s.DEBUG_MODE;
        }

        _ = ui.guiDummyRec(
            uiRect,
            "",
        );

        if (ui.guiButton(.{ .x = 160, .y = 50, .height = 45, .width = 100 }, "Exit") > 0) {
            break;
        }

        if (ui.guiButton(.{ .x = 160, .y = 100, .height = 45, .width = 100 }, "Next Map") > 0) {
            goToNextMap(&state);
        }

        if (!entered and state.phase == .START) {
            rl.drawText(
                "   YOU",
                @as(i32, @intFromFloat(state.player.pos.x + 20)),
                @as(i32, @intFromFloat(state.player.pos.y - 100)),
                20,
                .light_gray,
            );
        }

        if (entered and state.mode == .TUTORIAL and tutorialStep < 4) {
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
        if (state.mode == .TUTORIAL and tutorialStep >= 4) {
            state.mode = .WALKING;
        }

        var monstersEntered = false;
        const currentMapNode = try state.getCurrentMapNode();
        if (entered and state.phase == .PLAY and state.mode != .PAUSE and state.mode != .DONE and (state.mode == .WALKING or state.mode == .BATTLE)) {
            if (currentMapNode) |cn| {
                if (cn.monsters != null and cn.monsters.?.items.len > 0) {
                    const mobs = cn.monsters.?;
                    for (0..mobs.items.len) |i| {
                        monstersEntered = mobs.items[i].enter(&state, dt);
                        mobs.items[i].draw(&state);
                    }
                } else if (cn.altarEvent != null) {
                    try cn.altarEvent.?.handle(&state);
                    if (cn.altarEvent.?.baseEvent.handled) {
                        const exited = state.adventurer.exit(&state, dt);
                        if (exited) {
                            state.mode = .DONE;
                        }
                    }
                } else {
                    const exited = state.adventurer.exit(&state, dt);
                    if (exited) {
                        state.mode = .DONE;
                    }
                }
            }
        }

        if (monstersEntered) {
            state.mode = .BATTLE;
        }

        // Handle exiting first map
        if (state.phase == .START and entered and tutorialStep >= 4) {
            const exited = state.adventurer.exit(&state, dt);
            if (exited) {
                state.mode = .DONE;
                state.phase = state.NextPhase();
            }
        }

        if (state.mode == .DONE) {
            if (currentMapNode) |cn| {
                if (cn.altarEvent != null) {
                    cn.altarEvent.?.baseEvent.handled = false;
                }
                cn.print();
            }
            goToNextMapNode(&state);
            state.mode = .WALKING;
            state.adventurer.pos = .{ .x = 0, .y = groundY - 110 };
        }

        if (state.phase == .PLAY) {
            state.player.update(&state);
        }

        state.player.draw(&state, playerRotation);
        state.grid.draw(&state);
        state.adventurer.draw(&state);

        battle(&state, dt);

        try currentMapNode.?.update();

        drawUi(&state, topUI);

        if (s.DEBUG_MODE) {
            rl.drawFPS(
                @as(i32, @intFromFloat(uiRect.x)) + screenWidth - 150,
                @as(i32, @intFromFloat(uiRect.y)) + 20,
            );

            const center = state.grid.getCenterPos();

            rl.drawText(
                state.map.?.name,
                @as(i32, @intFromFloat(center.x - 100)),
                @as(i32, @intFromFloat(center.y)) - 350,
                26,
                .magenta,
            );

            for (0.., state.map.?.nodes.items) |i, item| {
                var buffer: [64:0]u8 = std.mem.zeroes([64:0]u8);
                _ = std.fmt.bufPrintZ(
                    &buffer,
                    "{s}",
                    .{item.name},
                ) catch "";
                if (i < state.map.?.nodes.items.len - 1) {
                    _ = std.fmt.bufPrintZ(
                        &buffer,
                        "{s} ->",
                        .{item.name},
                    ) catch "";
                }

                rl.drawText(
                    &buffer,
                    @as(i32, @intFromFloat(center.x - 100)) + @as(i32, @intCast(i)) * 150,
                    @as(i32, @intFromFloat(center.y)) - 300,
                    20,
                    .magenta,
                );
            }
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
    if (state.phase == .START) {
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
                    .width = 60,
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
                    .width = 60,
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

pub fn battle(state: *s.State, dt: f32) void {
    if (state.phase == .PLAY and state.mode == .BATTLE) {
        // combat
        const monster = try state.getMonster();
        if (monster == null) {
            const exited = state.adventurer.exit(state, dt);
            if (exited) {
                state.mode = .DONE;
            }
        } else {
            if (state.turn == .MONSTER) {
                std.debug.print("Monster turn {s}\n", .{monster.?.name});
                monster.?.attack(state);
                state.NextTurn();
            } else if (state.turn == .PLAYER) {
                if (ui.guiButton(.{ .x = 160, .y = 150, .height = 45, .width = 100 }, "Attack") > 0) {
                    const result = state.player.dice.?.items[0].roll(state);
                    std.debug.print("Roll result: {d}\n", .{result});
                    state.player.durability -= 20;

                    const damage = result * 20;
                    if (damage > monster.?.health) {
                        monster.?.health = 0;
                    } else {
                        monster.?.health -= result * 20;
                    }

                    _ = state.player.dice.?.pop();
                    state.NextTurn();
                }
            } else {
                state.NextTurn();
            }
        }
    }
}
