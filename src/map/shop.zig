const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const shop = @import("../objects/shopitem.zig");
const Die = @import("../die.zig").Die;
const BasicDie = @import("../dice/basic.zig").BasicDie;
const MultDie = @import("../dice/mult.zig").MultDie;
const HealthPotion = @import("../objects/healthpotion.zig").HealthPotion;

pub const ShopMap = struct {
    shopItems: std.ArrayList(shop.ShopItem),

    pub fn init(allocator: std.mem.Allocator) ShopMap {
        return .{
            .shopItems = std.ArrayList(shop.ShopItem).init(allocator),
        };
    }

    pub fn deinit(self: *@This(), state: *s.State) void {
        for (0..self.shopItems.items.len) |i| {
            if (!self.shopItems.items[i].purchased) {
                self.shopItems.items[i].deinit(state);
            }
        }
        self.shopItems.deinit();
    }

    pub fn generateAlchemyItem(self: *@This(), ingredients: *anyopaque) void {
        _ = self;
        _ = ingredients;
        // TODO: Create the ingredients and recipes for crafting
        // Runes and Dice can be crafted.
    }

    pub fn repairPlayer(self: @This(), state: *s.State) void {
        _ = self;
        if (state.player.gold >= 15) {
            state.player.gold -= 15;
            state.player.durability += 10;
        } else {
            if (state.player.messages != null) {
                try state.player.messages.?.append("Not enough gold.");
            }
        }
    }

    pub fn addShopItem(self: *@This(), item: shop.ShopItem) !void {
        try self.shopItems.append(item);
    }

    pub fn generateRandomShopItems(self: *@This(), state: *s.State) !void {
        // TODO: Generate shop items
        const numItems = 3;
        var i: usize = 0;
        while (i < numItems) : (i += 1) {
            const randInt = state.rand.intRangeAtMost(u8, 0, 100);
            const pos: rl.Vector2 = .{ .x = -256, .y = state.grid.getCenterPos().y };
            if (randInt >= 0 and randInt < 33) {
                std.debug.print("Adding health potion\n", .{});
                var healthPotion: *HealthPotion = try state.allocator.create(HealthPotion);
                healthPotion.healAmount = 25;
                healthPotion.texture = state.textureMap.get(.HEALTHPOTION);
                healthPotion.hovered = false;
                healthPotion.selected = false;
                healthPotion.index = 0;
                healthPotion.pos = pos;
                try self.addShopItem(.{
                    .name = "Health Potion",
                    .price = 4,
                    .die = null,
                    .healthPotion = healthPotion,
                    .pos = pos,
                    .texture = state.textureMap.get(.SHOPCARD).?,
                    .purchased = false,
                });
            }
            if (randInt >= 33) {
                const randDie = state.rand.intRangeAtMost(u8, 0, 100);
                var dieToAdd: ?*Die = null;
                if (randDie >= 0 and randDie < 50) {
                    var d6 = try state.allocator.create(BasicDie);
                    defer state.allocator.destroy(d6);
                    d6.name = "Basic d6";
                    d6.sides = 6;
                    d6.sellPrice = 2;
                    d6.texture = state.textureMap.get(.D6);
                    d6.hovered = false;
                    d6.selected = false;
                    d6.broken = false;
                    d6.breakChance = 0;
                    d6.nextResult = 0;
                    d6.tooltip = "";
                    d6.index = 0;
                    d6.pos = pos;
                    dieToAdd = try d6.die(&state.allocator);
                } else if (randDie >= 50) {
                    var d4 = try state.allocator.create(BasicDie);
                    defer state.allocator.destroy(d4);
                    d4.name = "Basic d4";
                    d4.sides = 4;
                    d4.sellPrice = 1;
                    d4.texture = state.textureMap.get(.D4);
                    d4.hovered = false;
                    d4.selected = false;
                    d4.broken = false;
                    d4.breakChance = 0;
                    d4.nextResult = 0;
                    d4.tooltip = "";
                    d4.index = 0;
                    d4.pos = pos;
                    dieToAdd = try d4.die(&state.allocator);
                }
                if (dieToAdd != null) {
                    try self.addShopItem(.{
                        .name = try dieToAdd.?.getName(),
                        .die = dieToAdd.?,
                        .healthPotion = null,
                        .price = 4,
                        .pos = pos,
                        .texture = state.textureMap.get(.SHOPCARD).?,
                        .purchased = false,
                    });
                }
            }
        }
    }

    pub fn update(self: *@This(), state: *s.State) !void {
        const mousepos = rl.getMousePosition();
        for (0..self.shopItems.items.len) |i| {
            var item: *shop.ShopItem = &self.shopItems.items[i];
            if (item.purchased) {
                continue;
            }
            if (item.healthPotion != null) {
                try item.healthPotion.?.update(state);
            }
            const collisionRect = rl.Rectangle.init(
                item.pos.x - 32,
                item.pos.y - 38,
                190,
                210,
            );

            const hover = collisionRect.checkCollision(.{
                .x = mousepos.x,
                .y = mousepos.y,
                .height = 2,
                .width = 2,
            });
            if (hover) {
                var buffer: [64:0]u8 = std.mem.zeroes([64:0]u8);
                _ = std.fmt.bufPrintZ(
                    &buffer,
                    "{s} - {d}gp",
                    .{ item.name, item.price },
                ) catch "";

                rl.drawRectangle(
                    @as(i32, @intFromFloat(mousepos.x)),
                    @as(i32, @intFromFloat(mousepos.y)) - 100,
                    150,
                    70,
                    rl.getColor(0x0000D0),
                );

                rl.drawText(
                    &buffer,
                    @as(i32, @intFromFloat(mousepos.x)) + 10,
                    @as(i32, @intFromFloat(mousepos.y)) - 90,
                    20,
                    .gray,
                );

                const hoverRect: rl.Rectangle = .{
                    .x = collisionRect.x + 13,
                    .y = collisionRect.y + 2,
                    .width = 165,
                    .height = 205,
                };

                rl.drawRectangleGradientEx(
                    hoverRect,
                    rl.Color.init(50, 100, 150, 0),
                    rl.Color.init(50, 100, 150, 150),
                    rl.Color.init(50, 100, 150, 0),
                    rl.Color.init(50, 100, 150, 150),
                );
            }
            if (rl.isMouseButtonPressed(rl.MouseButton.left) and hover) {
                if (item.die != null) {
                    const lastDieIndex = state.player.dice.?.items.len;
                    item.die.?.index = lastDieIndex;
                }

                const purchased = try state.player.purchaseItem(item.*, state);
                if (purchased) {
                    item.purchased = true;
                }
            }
        }
    }
    pub fn draw(self: @This(), state: *s.State) !void {
        const dt = rl.getFrameTime();
        if (ui.guiButton(.{ .x = 160, .y = 200, .height = 45, .width = 100 }, "Sell Die") > 0) {
            if (state.player.dice != null) {
                _ = try state.player.sellSelectedDice(state);
            }
        }
        for (0..self.shopItems.items.len) |i| {
            var item = &self.shopItems.items[i];
            if (item.purchased) {
                continue;
            }

            const dest: f32 = state.grid.getWidth() - @as(f32, @floatFromInt(256 * (i + 1)));
            _ = item.enter(dest, dt);
            if (item.die != null) {
                const die = item.die.?;

                rl.drawTexturePro(
                    item.texture,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = 256,
                        .height = 256,
                    },
                    .{
                        .x = item.pos.x - 64,
                        .y = item.pos.y - 64,
                        .width = 256,
                        .height = 256,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .white,
                );

                rl.drawTexturePro(
                    die.texture.?,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = 128,
                        .height = 128,
                    },
                    .{
                        .x = item.pos.x,
                        .y = item.pos.y,
                        .width = 128,
                        .height = 128,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .white,
                );
            }
            if (item.healthPotion != null) {
                const potion = item.healthPotion.?;

                rl.drawTexturePro(
                    item.texture,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = 256,
                        .height = 256,
                    },
                    .{
                        .x = item.pos.x - 64,
                        .y = item.pos.y - 64,
                        .width = 256,
                        .height = 256,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .white,
                );

                rl.drawTexturePro(
                    potion.texture.?,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = 512,
                        .height = 512,
                    },
                    .{
                        .x = item.pos.x,
                        .y = item.pos.y,
                        .width = 128,
                        .height = 128,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .white,
                );
            }
        }
    }
};
