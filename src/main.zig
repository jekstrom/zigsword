const rl = @import("raylib");
const ui = @import("raygui");
const LoadFont = @import("raylib").loadFont;
const std = @import("std");
const s = @import("objects/state.zig");
const Grid = @import("objects/grid.zig").Grid;
const Cell = @import("objects/grid.zig").Cell;
const Adventurer = @import("objects/adventurer.zig").Adventurer;
const AltarHistory = @import("altarHistory.zig").AltarHistory;
const enums = @import("enums.zig");
const BasicDie = @import("dice/basic.zig").BasicDie;
const MultDie = @import("dice/mult.zig").MultDie;
const Die = @import("die.zig").Die;
const Rune = @import("runes/rune.zig").Rune;
const DawnRune = @import("runes/dawn.zig").DawnRune;
const FateRune = @import("runes/fate.zig").FateRune;
const KinRune = @import("runes/kin.zig").KinRune;
const textures = @import("textures.zig");
const SMState = @import("states/smState.zig").SMState;

pub fn drawUi(state: *s.State, topUI: f32) anyerror!void {
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

    for (0..state.player.dice.?.items.len) |i| {
        const die = state.player.dice.?.items[i];
        // TODO: make a layout manager for ui elements.
        try die.draw(state);
    }

    var buffer: [64:0]u8 = std.mem.zeroes([64:0]u8);
    _ = std.fmt.bufPrintZ(
        &buffer,
        "Gold: {d}",
        .{state.player.gold},
    ) catch "";

    rl.drawText(
        &buffer,
        250 + 150 + 70 + 50,
        @as(i32, @intFromFloat(topUI)) + 85,
        25,
        .yellow,
    );

    if (state.player.runes != null and state.player.runes.?.items.len > 0) {
        for (0..state.player.runes.?.items.len) |i| {
            const rune = state.player.runes.?.items[i];
            // TODO: make a layout manager for ui elements.
            try rune.draw(state);
        }
    }
}

pub fn generateAdventurer(state: *s.State) void {
    var adventurer: Adventurer = .{
        .health = 100,
        .name = "Bob",
        .nameKnown = true,
        .speed = 0.90,
        .pos = .{ .x = 0, .y = 0 },
        .texture = state.textureMap.get(.Adventurer).?,
        .nextMap = .center,
    };
    adventurer.chooseNextMap(state);
    state.adventurer = adventurer;
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
    const arenaAllocator = arena.allocator();

    var gpa = std.heap.GeneralPurposeAllocator(.{
        .enable_memory_limit = true,
        .safety = true,
    }){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const List = std.ArrayList(@import("objects/grid.zig").CellTexture);
    const AltarHistoryList = std.ArrayList(AltarHistory);
    const DiceList = std.ArrayList(*Die);
    const RuneList = std.ArrayList(*Rune);
    const MessageList = std.ArrayList([:0]const u8);
    const PlayerMessageList = std.ArrayList([:0]const u8);
    const PlayerRescued = std.ArrayList(enums.Rescues);
    const PlayerKilled = std.ArrayList(enums.Rescues);

    var map = std.AutoHashMap(enums.TextureType, rl.Texture).init(allocator);
    defer map.deinit();

    try textures.loadAndMapAllTextures(&map);

    const seed: u64 = 1338;

    // Uncomment to use os rand
    // std.posix.getrandom(std.mem.asBytes(&seed)) catch |err| {
    //     std.debug.print("Failed to get random seed: {}\n", .{err});
    //     return;
    // };

    var prng = std.Random.DefaultPrng.init(seed);
    const rand = prng.random();

    // Set aside memory for player's name
    var newName: [10:0]u8 = std.mem.zeroes([10:0]u8);

    const font = try LoadFont("resources/fonts/alagard.png");
    defer rl.unloadFont(font);

    // Init state
    var state: s.State = .{
        .phase = .START,
        .mode = .NONE,
        .turn = .ENVIRONMENT,
        .currentMap = 0,
        .currentNode = 0,
        .selectedMap = 0,
        .mapMenuInputActive = false,
        .mapCount = 0,
        .newName = &newName,
        .stateMachine = null,
        .font = font,
        .player = .{
            .pos = .{ .x = 0, .y = 0 },
            .rotation = 180.0,
            .equiped = false,
            .name = undefined,
            .alignment = .GOOD,
            .altarHistory = null,
            .blessed = false,
            .dice = null,
            .runes = null,
            .durability = 100,
            .gold = 0,
            .maxSelectedDice = 3,
            .maxDice = 6,
            .messages = null,
            .stateMachine = null,
            .rescued = null,
            .killed = null,
        },
        .adventurer = .{
            .name = "Zig",
            .pos = .{ .x = 0, .y = 0 },
            .nameKnown = false,
            .speed = 0.95,
            .health = 100,
            .texture = map.get(.Adventurer).?,
            .nextMap = .left,
        },
        .map = null,
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
        .allocator = allocator,
        .arenaAllocator = arenaAllocator,
        .rand = rand,
        .randomNumbers = [_][Grid.numCols]u16{[_]u16{0} ** Grid.numCols} ** Grid.numRows,
        .messages = MessageList.init(allocator),
    };

    for (0..Grid.numRows) |r| {
        for (0..Grid.numCols) |c| {
            state.randomNumbers[r][c] = state.rand.intRangeAtMost(u16, 0, 65535);
        }
    }

    // Keep track of new adventurer's dialog progress
    // Set up memory for player state
    state.player.altarHistory = AltarHistoryList.init(allocator);
    state.player.dice = DiceList.init(allocator);
    state.player.runes = RuneList.init(allocator);
    state.player.messages = PlayerMessageList.init(allocator);
    state.player.rescued = PlayerRescued.init(allocator);
    state.player.killed = PlayerKilled.init(allocator);

    var statemachine = try allocator.create(@import("states/stateMachine.zig").StateMachine);
    statemachine.allocator = &allocator;
    statemachine.state = null;
    defer allocator.destroy(statemachine);
    state.stateMachine = statemachine;

    // Set up initial grid to get correct positioning
    state.grid.draw(&state);

    try state.reset();

    state.map.?.print();
    state.currentMap = state.map.?.currentMapCount;
    std.debug.print("current map: {d}", .{state.currentMap});
    std.debug.print(" {s}\n", .{state.map.?.name});

    const groundY = state.grid.getGroundY();

    state.adventurer.pos = .{ .x = -100, .y = groundY - 110 };

    const topUI = state.grid.cells[state.grid.cells.len - 4][0].pos.y + @as(f32, @floatFromInt(state.grid.cellSize));

    // TEST RUNES
    // var dawnRune: *DawnRune = try allocator.create(DawnRune);

    // dawnRune.name = "Dawn";
    // dawnRune.pos = .{
    //     .x = state.grid.getWidth() - 250.0,
    //     .y = state.grid.topUI() + 75.0,
    // };
    // const dr = try dawnRune.rune(&allocator);
    // try state.player.runes.?.append(dr);

    // var kinRune: *KinRune = try allocator.create(KinRune);

    // kinRune.name = "Kin";
    // kinRune.pos = .{
    //     .x = state.grid.getWidth() - 220.0,
    //     .y = state.grid.topUI() + 75.0,
    // };
    // const kr = try kinRune.rune(&allocator);
    // try state.player.runes.?.append(kr);

    // var fateRune: *FateRune = try allocator.create(FateRune);

    // fateRune.name = "Fate";
    // fateRune.pos = .{
    //     .x = state.grid.getWidth() - 190.0,
    //     .y = state.grid.topUI() + 75.0,
    // };
    // const fr = try fateRune.rune(&allocator);
    // try state.player.runes.?.append(fr);

    state.adventurer.reset(&state);

    rl.setTargetFPS(60);
    //--------------------------------------------------------------------------------------

    // Main game loop, detect window close button or ESC key
    while (!rl.windowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------
        const gameTime = rl.getTime();
        const dt = rl.getFrameTime();
        const mousePos = rl.getMousePosition();

        if (gameTime > 3000) {
            std.debug.print("resetting game. current state: {}\n", .{state.phase});
            break;
        }

        // used for positioning elements
        const uiHeight = screenHeight - topUI;
        const uiRect: rl.Rectangle = .{ .height = uiHeight, .width = screenWidth, .x = 0, .y = topUI };

        // Keep track of if the adventurer has entered the map
        // var entered = false;
        // var playerRotation: f32 = 180.0;

        state.player.pos.x = screenWidth / 2;
        if (state.player.pos.y < groundY + 25) {
            state.player.pos.y += 250 * dt;
        }
        state.mousePos = mousePos;

        if (state.player.durability <= 0) {
            // Game over
            std.debug.print("Game Over", .{});
            state.phase = state.NextPhase();
            break;
        }

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        if (!state.isMenu()) {
            try state.drawCurrentMapNode(dt);

            _ = ui.guiDummyRec(
                uiRect,
                "",
            );

            if (ui.guiButton(.{ .x = 160, .y = 50, .height = 45, .width = 100 }, "Exit") > 0) {
                break;
            }

            if (ui.guiButton(.{ .x = 160, .y = 100, .height = 45, .width = 100 }, "Add gold") > 0) {
                state.player.gold += 100;
            }
        }

        if (ui.guiButton(.{ .x = 50, .y = 50, .height = 45, .width = 100 }, "DEBUG") > 0) {
            s.DEBUG_MODE = !s.DEBUG_MODE;
        }

        if (ui.guiButton(.{ .x = 50, .y = 100, .height = 45, .width = 100 }, "Menu") > 0) {
            try state.reset();
        }

        // if (ui.guiButton(.{ .x = 50, .y = 150, .height = 45, .width = 100 }, "Map") > 0) {
        //     state.goToMapMenu();
        // }

        if (state.mode == .ADVENTURERDEATH) {
            // Wait for next adventurer...
            generateAdventurer(&state);
            state.adventurer.nameKnown = true;
            state.adventurer.pos = .{ .x = -100, .y = groundY - 110 };
            state.mode = .NONE;
            state.phase = .START; // TODO: handle phases differently?
            state.tutorialStep = 0;
        }

        if (!state.isMenu() and !state.player.equiped and state.phase == .START) {
            rl.drawText(
                "   YOU",
                @as(i32, @intFromFloat(state.player.pos.x + 20)),
                @as(i32, @intFromFloat(state.player.pos.y - 100)),
                20,
                .light_gray,
            );
        }

        const currentMapNode = try state.getCurrentMapNode();

        if (!state.isMenu()) {
            state.grid.draw(&state);
            state.player.draw(&state);
            if (state.adventurer.health > 0) {
                state.adventurer.draw(&state);
            }

            try state.player.update(&state);

            if (currentMapNode) |cn| {
                if (cn.monsters) |mobs| {
                    for (0..mobs.items.len) |i| {
                        mobs.items[i].update(&state);
                    }
                }
            }
        }
        try currentMapNode.?.update(&state);

        try state.update();

        if (!state.isMenu() and !state.isMapMenu()) {
            try drawUi(&state, topUI);
        }

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
            const st = try std.fmt.allocPrintZ(state.allocator, "({d}, {d})", .{ @round(mousePos.x), @round(mousePos.y) });
            defer state.allocator.free(st);
            rl.drawTextPro(
                try rl.getFontDefault(),
                st,
                mousePos,
                .{ .x = -15, .y = -10 },
                0.0,
                20,
                2,
                .black,
            );
            const hoveredCell = state.grid.getHoveredCell().?;
            const st2 = try std.fmt.allocPrintZ(state.allocator, "({d}, {d})", .{ hoveredCell.r, hoveredCell.c });
            defer state.allocator.free(st2);
            rl.drawTextPro(
                try rl.getFontDefault(),
                st2,
                hoveredCell.pos,
                .{ .x = -15, .y = -5 },
                0.0,
                15,
                2,
                .black,
            );
        }
    }

    // Clean up
    try state.player.deinit(&state);

    if (state.stateMachine) |sm| {
        if (sm.state != null and sm.state.?.nextState != null) {
            // TODO: traverse all next states and destroy them.
            // At the moment I only have one level of next states.
            state.allocator.destroy(sm.state.?.nextState.?);
        }
        try sm.clearState();
    }

    try state.map.?.deinitAll(&state);

    const it = state.textureMap.keyIterator();
    for (0..it.len) |i| {
        const textureKey = it.items[i];
        if (state.textureMap.get(textureKey)) |texture| {
            rl.unloadTexture(texture);
        }
    }

    for (0..@as(usize, @intCast(Grid.numRows))) |r| {
        for (0..@as(usize, @intCast(Grid.numCols))) |c| {
            state.grid.cells[r][c].textures.deinit();
        }
    }

    try state.deinit();
}
