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
const shop = @import("objects/shopitem.zig");
const textures = @import("textures.zig");
const sm = @import("states/smState.zig");

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

    for (0..state.player.dice.?.items.len) |i| {
        const die = state.player.dice.?.items[i];
        // TODO: make a layout manager for ui elements.
        die.draw(state);
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
}

pub fn generateAdventurer(state: *s.State) void {
    const adventurer: a.Adventurer = .{
        .health = 100,
        .name = "Bob",
        .nameKnown = true,
        .speed = 0.90,
        .pos = .{ .x = 0, .y = 0 },
        .texture = state.textureMap.get(.Adventurer).?,
    };
    state.adventurer = adventurer;
}

pub fn generateNextMap(state: *s.State, name: [:0]const u8, nodeType: m.MapNodeType) !void {
    // Generate a new map using seed from State.
    // Maps should all contain the same number of nodes but
    // what each node consists of should be random.

    const List = std.ArrayList(m.MapNode);
    const MonsterList = std.ArrayList(mob.Monster);
    const ShopItems = std.ArrayList(shop.ShopItem);

    var numWalkingNodes = state.rand.intRangeAtMost(
        u4,
        2,
        4,
    );

    if (nodeType == .SHOP) {
        numWalkingNodes = 1;
    }

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
                .monstersEntered = false,
                .monsters = null,
                .altarEvent = null,
                .shopItems = null,
                .stateMachine = null,
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
                .monstersEntered = false,
                .altarEvent = null,
                .shopItems = null,
                .stateMachine = null,
            };
            try dungeonNode.init(state);
            try newMap.addMapNode(dungeonNode);
        } else if (nodeType == .SHOP) {
            var shopNode: m.MapNode = .{
                .name = buffer,
                .type = nodeType,
                .texture = state.textureMap.get(.DUNGEONGROUND),
                .background = state.textureMap.get(.SHOPBACKGROUND),
                .monstersEntered = false,
                .monsters = null,
                .altarEvent = null,
                .shopItems = ShopItems.init(state.allocator),
                .stateMachine = null,
            };
            try shopNode.init(state);
            try newMap.addMapNode(shopNode);
        }
    }

    if (state.map) |_| {
        // try state.map.?.addMap(state, "", newMap.nodes);

        var currentMap: ?*m.Map = &state.map.?;
        while (currentMap != null) {
            newMap.currentMapCount = currentMap.?.currentMapCount + 1;
            std.debug.print("Current map: {s}\n", .{currentMap.?.name});
            if (currentMap.?.nextMap == null) {
                std.debug.print("next map null\n", .{});
                break;
            } else {
                currentMap = currentMap.?.nextMap;
                std.debug.print("next map: {s}\n", .{currentMap.?.name});
            }
        }
        std.debug.print("Adding next map as child to {s}\n", .{currentMap.?.name});

        currentMap.?.nextMap = newMap;
    } else {
        newMap.currentMapCount = 1;
        state.map = newMap.*;
    }
}

// pub fn goToNextMap(state: *s.State) void {
//     if (state.map.?.nextMap) |nm| {
//         state.map = nm.*;
//         state.currentMap = state.map.?.currentMapCount;
//         state.currentNode = 0;
//         state.grid.clearTextures();
//     }
// }

// pub fn goToNextMapNode(state: *s.State) void {
//     if (state.map) |map| {
//         const numnodes = map.nodes.items.len;
//         if ((state.currentNode + 1) >= numnodes) {
//             state.currentNode = 0;
//             std.debug.print("Resetting map node {d}\n", .{state.currentNode});
//             goToNextMap(state);
//         } else {
//             state.currentNode += 1;
//             std.debug.print("Going to map node {d}\n", .{state.currentNode});
//         }
//     } else {
//         std.debug.print("no map found\n", .{});
//         std.debug.assert(false);
//     }
// }

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
    const MessageList = std.ArrayList([:0]const u8);
    const PlayerMessageList = std.ArrayList([:0]const u8);

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

    // Init state
    var state: s.State = .{
        .phase = .START,
        .mode = .TUTORIAL,
        .turn = .ENVIRONMENT,
        .currentMap = 0,
        .currentNode = 0,
        .newName = &newName,
        .stateMachine = null,
        .player = .{
            .pos = .{ .x = 0, .y = 0 },
            .rotation = 180.0,
            .equiped = false,
            .name = undefined,
            .alignment = .GOOD,
            .altarHistory = null,
            .blessed = false,
            .dice = null,
            .durability = 100,
            .gold = 0,
            .maxSelectedDice = 3,
            .messages = null,
            .stateMachine = null,
        },
        .adventurer = .{
            .name = "Zig",
            .pos = .{ .x = 0, .y = 0 },
            .nameKnown = false,
            .speed = 0.35,
            .health = 100,
            .texture = map.get(.Adventurer).?,
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
        .messages = MessageList.init(allocator),
    };

    for (0..g.Grid.numRows) |r| {
        for (0..g.Grid.numCols) |c| {
            state.randomNumbers[r][c] = state.rand.intRangeAtMost(u16, 0, 65535);
        }
    }

    // Set up initial grid to get correct positioning
    state.grid.draw(&state);

    // Generate first maps
    try generateNextMap(&state, "Start", .WALKING);
    try generateNextMap(&state, "Dungeon", .DUNGEON);
    try generateNextMap(&state, "Shop", .SHOP);
    state.map.?.print();
    state.currentMap = state.map.?.currentMapCount;
    std.debug.print("current map: {d}", .{state.currentMap});
    std.debug.print(" {s}\n", .{state.map.?.name});

    const groundY = state.grid.getGroundY();

    state.adventurer.pos = .{ .x = -100, .y = groundY - 110 };

    // Keep track of new adventurer's dialog progress
    var tutorialStep: u4 = 0;

    // Set up memory for player state
    state.player.altarHistory = AltarHistoryList.init(allocator);
    state.player.dice = DiceList.init(allocator);
    state.player.messages = PlayerMessageList.init(allocator);

    var tutorialState: @import("states/tutorial.zig").TutorialState = .{
        .nextState = null,
        .tutorialStep = &tutorialStep,
        .isComplete = false,
        .startTime = rl.getTime(),
    };
    const tutorialSmState: *sm.SMState = try tutorialState.smState(&allocator);

    var statemachine = try allocator.create(@import("states/stateMachine.zig").StateMachine);
    statemachine.allocator = &allocator;
    statemachine.state = tutorialSmState;
    defer allocator.destroy(statemachine);

    state.stateMachine = statemachine;

    const topUI = state.grid.cells[state.grid.cells.len - 4][0].pos.y + @as(f32, @floatFromInt(state.grid.cellSize));

    // Add initial player dice
    var dcount: u8 = 0;
    const numd6: u8 = 2;
    const numd4: u8 = 4 + numd6;
    var xoffset: f32 = 50.0;
    while (dcount < numd6) : (dcount += 1) {
        xoffset = 50 * @as(f32, @floatFromInt(dcount));
        try state.player.dice.?.append(.{
            .name = "Basic d6",
            .sides = 6,
            .texture = state.textureMap.get(.D6),
            .hovered = false,
            .selected = false,
            .index = dcount,
            .pos = .{
                .x = state.grid.getWidth() - 550 + xoffset,
                .y = topUI + 10,
            },
        });
    }
    xoffset += 50;
    while (dcount < numd4) : (dcount += 1) {
        xoffset = 50 * @as(f32, @floatFromInt(dcount));
        try state.player.dice.?.append(.{
            .name = "Basic d4",
            .sides = 4,
            .texture = state.textureMap.get(.D4),
            .hovered = false,
            .selected = false,
            .index = dcount + numd6,
            .pos = .{
                .x = state.grid.getWidth() - 550 + xoffset,
                .y = topUI + 10,
            },
        });
    }

    // Keep track of message decay
    var decay: u8 = 255;
    // var monsterMsgDecay: u8 = 255;
    var playerMsgDecay: u8 = 255;
    // var waitStart: f64 = 0.0;
    // // const waitSeconds: f64 = 2.0;
    // var turnWaitStart: f64 = 0.0;
    // const turnWaitSeconds: f64 = 1.5;

    rl.setTargetFPS(60);
    //--------------------------------------------------------------------------------------

    // Main game loop, detect window close button or ESC key
    while (!rl.windowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------
        const gameTime = rl.getTime();
        const dt = rl.getFrameTime();
        const mousePos = rl.getMousePosition();

        if (gameTime > 300) {
            std.debug.print("resetting game. current state: {}\n", .{state.phase});
            break;
        }

        // used for positioning elements
        const uiHeight = screenHeight - topUI;
        const uiRect: rl.Rectangle = .{ .height = uiHeight, .width = screenWidth, .x = 0, .y = topUI };

        // Keep track of if the adventurer has entered the map
        // var entered = false;
        // var playerRotation: f32 = 180.0;

        if (state.mode != .SHOP) {
            state.player.pos.x = screenWidth / 2;
            if (state.player.pos.y < groundY + 25) {
                state.player.pos.y += 250 * dt;
            }
            state.mousePos = mousePos;

            // entered = state.adventurer.enter(&state, dt);

            // if (entered and state.phase == .START) {
            //     state.player.equiped = true;
            // }

            // if (state.player.equiped) {
            //     playerRotation = 0.0;
            //     state.player.pos.y = state.adventurer.pos.y;
            // }
        }

        // if (state.adventurer.health <= 0) {
        //     // Reset -- wait for next adventurer
        //     state.player.equiped = false;
        //     state.adventurer.pos.x = -200;
        //     state.mode = .ADVENTURERDEATH;
        // }

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
        try state.drawCurrentMapNode(dt);

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

        if (ui.guiButton(.{ .x = 160, .y = 100, .height = 45, .width = 100 }, "Add gold") > 0) {
            state.player.gold += 100;
        }

        if (state.mode == .ADVENTURERDEATH) {
            // Wait for next adventurer...
            generateAdventurer(&state);
            state.adventurer.nameKnown = true;
            state.adventurer.pos = .{ .x = -100, .y = groundY - 110 };
            state.mode = .TUTORIAL;
            state.phase = .START; // TODO: handle phases differently?
            tutorialStep = 0;
        }

        // if (state.mode == .SHOP) {
        //     if (ui.guiButton(.{ .x = 160, .y = 150, .height = 45, .width = 100 }, "Exit Shop") > 0) {
        //         goToNextMap(&state);
        //         state.mode = .WALKING;
        //     }
        // }

        if (!state.player.equiped and state.phase == .START) {
            rl.drawText(
                "   YOU",
                @as(i32, @intFromFloat(state.player.pos.x + 20)),
                @as(i32, @intFromFloat(state.player.pos.y - 100)),
                20,
                .light_gray,
            );
        }

        // if (entered and state.mode == .TUTORIAL and tutorialStep < 4) {
        //     // try tutorial(
        //     //     &state,
        //     //     screenWidth,
        //     //     screenHeight,
        //     //     groundY,
        //     //     &tutorialStep,
        //     //     &newName,
        //     //     &allocator,
        //     // );
        // }
        // if (state.mode == .TUTORIAL and tutorialStep >= 4) {
        //     state.mode = .WALKING;
        // }

        const currentMapNode = try state.getCurrentMapNode();
        // if (currentMapNode) |cn| {
        //     if (cn.monsters != null and cn.monsters.?.items.len > 0) {
        //         // go to battle state if monsters exists
        //         var battleState: @import("states/battle.zig").BattleState = .{
        //             .nextState = null,
        //             .isComplete = false,
        //             .startTime = rl.getTime(),
        //         };
        //         var battleSmState = battleState.smState();
        //         try state.player.stateMachine.?.setState(&battleSmState, &state);
        //     }
        // }

        // if (currentMapNode) |cn| {
        //     if (cn.type == .SHOP) {
        //         state.adventurer.pos.x = -200;
        //         state.mode = .SHOP;
        //     }
        // }

        // if (entered and state.phase == .PLAY and state.mode != .PAUSE and state.mode != .DONE and (state.mode == .WALKING or state.mode == .BATTLE)) {
        //     if (currentMapNode) |cn| {
        //         if (cn.monsters != null and cn.monsters.?.items.len > 0) {
        //             // battle
        //         } else if (cn.altarEvent != null) {
        //             try cn.altarEvent.?.handle(&state);
        //             if (cn.altarEvent.?.baseEvent.handled) {
        //                 waitStart = rl.getTime();
        //                 state.mode = .WAIT;
        //             }
        //         } else {
        //             const exited = state.adventurer.exit(&state, dt);
        //             if (exited) {
        //                 state.mode = .DONE;
        //             }
        //         }
        //     }
        // }

        // if (currentMapNode) |cn| {
        //     if (cn.monsters) |mobs| {
        //         for (0..mobs.items.len) |i| {
        //             const monsterMessageDisplayed = mobs.items[i].displayMessages(
        //                 monsterMsgDecay,
        //                 dt * @as(f32, @floatFromInt(monsterMsgDecay)),
        //             );
        //             if (monsterMsgDecay == 0) {
        //                 monsterMsgDecay = 255;
        //             }

        //             if (monsterMessageDisplayed) {
        //                 const ddiff = @as(u8, @intFromFloat(rl.math.clamp(230 * dt, 0, 255)));
        //                 const rs = @subWithOverflow(monsterMsgDecay, ddiff);
        //                 if (rs[1] != 0) {
        //                     monsterMsgDecay = 0;
        //                 } else {
        //                     monsterMsgDecay -= ddiff;
        //                 }
        //             }
        //         }
        //     }
        // }

        // if (state.mode == .WAIT and rl.getTime() - waitStart >= waitSeconds) {
        //     const exited = state.adventurer.exit(&state, dt);
        //     if (exited) {
        //         currentMapNode.?.removeDeadMonsters();
        //         state.mode = .DONE;
        //     }
        // }

        // if (state.mode != .WAIT and currentMapNode.?.monstersEntered) {
        //     state.mode = .BATTLE;
        // }

        // // Handle exiting first map
        // if (state.phase == .START and entered and tutorialStep >= 4) {
        //     const exited = state.adventurer.exit(&state, dt);
        //     if (exited) {
        //         state.mode = .DONE;
        //         state.phase = state.NextPhase();
        //     }
        // }

        // if (state.mode == .DONE) {
        //     if (currentMapNode) |cn| {
        //         if (cn.altarEvent != null) {
        //             cn.altarEvent.?.baseEvent.handled = false;
        //         }
        //         cn.print();
        //     }
        //     goToNextMapNode(&state);
        //     state.mode = .WALKING;
        //     state.adventurer.pos = .{ .x = 0, .y = groundY - 110 };
        // }

        state.grid.draw(&state);
        state.player.draw(&state);
        if (state.adventurer.health > 0) {
            state.adventurer.draw(&state);
        }
        // if (state.phase == .PLAY) {
        //     try state.player.update(&state);
        // }
        try state.player.update(&state);

        // if (state.phase == .PLAY and state.mode == .BATTLE) {
        //     try battle(
        //         &state,
        //         &waitStart,
        //         &turnWaitStart,
        //         turnWaitSeconds,
        //     );
        // }

        try currentMapNode.?.update(&state);
        try state.update();

        drawUi(&state, topUI);

        const messageDisplayed = state.displayMessages(decay);
        if (decay == 0) {
            decay = 255;
        }

        if (messageDisplayed) {
            const ddiff = @as(u8, @intFromFloat(rl.math.clamp(170 * dt, 0, 255)));
            if (decay <= 1) {
                decay = 0;
            } else {
                decay -= ddiff;
            }
        }

        const playerMessageDisplayed = state.player.displayMessages(
            playerMsgDecay,
            dt * @as(f32, @floatFromInt(playerMsgDecay)),
        );
        if (playerMsgDecay == 0) {
            playerMsgDecay = 255;
        }

        if (playerMessageDisplayed) {
            const ddiff = @as(u8, @intFromFloat(rl.math.clamp(230 * dt, 0, 255)));
            const rs = @subWithOverflow(playerMsgDecay, ddiff);
            if (rs[1] != 0) {
                playerMsgDecay = 0;
            } else {
                playerMsgDecay -= ddiff;
            }
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
        }
    }

    // Clean up
    const it = state.textureMap.keyIterator();
    for (0..it.len) |i| {
        const textureKey = it.items[i];
        if (state.textureMap.get(textureKey)) |texture| {
            rl.unloadTexture(texture);
        }
    }

    for (0..@as(usize, @intCast(g.Grid.numRows))) |r| {
        for (0..@as(usize, @intCast(g.Grid.numCols))) |c| {
            state.grid.cells[r][c].textures.deinit();
        }
    }
}

// pub fn tutorial(
//     state: *s.State,
//     screenWidth: comptime_int,
//     screenHeight: comptime_int,
//     groundY: f32,
//     tutorialStep: *u4,
//     newName: *[10:0]u8,
//     allocator: *const std.mem.Allocator,
// ) !void {
//     if (state.phase == .START) {
//         const messageRect: rl.Rectangle = .{
//             .height = 200,
//             .width = 500,
//             .x = (screenWidth - 500) / 2,
//             .y = (screenHeight - groundY) / 2,
//         };

//         if (tutorialStep.* == 0) {
//             if (ui.guiMessageBox(
//                 messageRect,
//                 "YOU",
//                 "Greetings Adventurer!",
//                 "next",
//             ) > 0) {
//                 tutorialStep.* = 1;
//                 return;
//             }
//             state.player.drawPortrait(
//                 state,
//                 .{
//                     .height = 60,
//                     .width = 60,
//                     .x = messageRect.x + 10,
//                     .y = messageRect.y + 30,
//                 },
//             );
//         }

//         if (tutorialStep.* == 1) {
//             const messageRect2: rl.Rectangle = .{
//                 .height = 200,
//                 .width = 500,
//                 .x = (screenWidth - 500) / 2,
//                 .y = (screenHeight - groundY) / 2,
//             };
//             if (ui.guiTextInputBox(
//                 messageRect2,
//                 "ADVENTURER",
//                 "Woah, a talking sword! What do they call you?",
//                 "next",
//                 newName,
//                 10,
//                 null,
//             ) > 0) {
//                 state.player.name = newName;
//                 tutorialStep.* = 2;
//                 return;
//             }

//             state.adventurer.drawPortrait(
//                 state,
//                 .{
//                     .height = 60,
//                     .width = 60,
//                     .x = messageRect.x + 10,
//                     .y = messageRect.y + 30,
//                 },
//             );
//         }

//         if (tutorialStep.* == 2) {
//             var buffer: [13 + 10:0]u8 = std.mem.zeroes([13 + 10:0]u8);
//             _ = std.fmt.bufPrint(
//                 &buffer,
//                 "They call me {s}.",
//                 .{state.player.name},
//             ) catch "";

//             if (ui.guiMessageBox(
//                 messageRect,
//                 state.player.name,
//                 &buffer,
//                 "next",
//             ) > 0) {
//                 tutorialStep.* = 3;
//                 return;
//             }
//             state.player.drawPortrait(
//                 state,
//                 .{
//                     .height = 60,
//                     .width = 60,
//                     .x = messageRect.x + 10,
//                     .y = messageRect.y + 30,
//                 },
//             );
//         }

//         if (tutorialStep.* == 3) {
//             const sx = try concatStrings(
//                 allocator.*,
//                 state.player.name,
//                 "? stange name for a sword. Let's go!",
//             );
//             defer allocator.free(sx);
//             if (ui.guiMessageBox(
//                 messageRect,
//                 "ADVENTURER",
//                 sx,
//                 "next",
//             ) > 0) {
//                 tutorialStep.* = 4;
//                 return;
//             }
//             state.adventurer.drawPortrait(
//                 state,
//                 .{
//                     .height = 60,
//                     .width = 60,
//                     .x = messageRect.x + 10,
//                     .y = messageRect.y + 30,
//                 },
//             );
//         }
//     }
// }

// pub fn battle(state: *s.State, waitStart: *f64, turnWaitStart: *f64, turnWaitSeconds: f64) !void {
//     // combat
//     const monster = try state.getMonster();
//     if (monster != null) {
//         if (monster.?.dying) {
//             waitStart.* = rl.getTime();
//             state.mode = .WAIT;
//         } else {
//             if (state.turn == .MONSTER) {
//                 std.debug.print("Monster turn {s}\n", .{monster.?.name});
//                 try monster.?.attack(state);
//                 turnWaitStart.* = rl.getTime();
//                 state.NextTurn();
//             } else if (state.turn == .PLAYER) {
//                 if (ui.guiButton(.{ .x = 160, .y = 150, .height = 45, .width = 100 }, "Attack") > 0) {
//                     try state.player.attack(state, monster.?);
//                     turnWaitStart.* = rl.getTime();
//                     state.NextTurn();
//                 }
//             } else if (@intFromEnum(state.turn) >= 4) {
//                 // Wait for a second before continuing
//                 if (rl.getTime() - turnWaitStart.* > turnWaitSeconds) {
//                     state.NextTurn();
//                 }
//             } else {
//                 state.NextTurn();
//             }
//         }
//     }
// }
