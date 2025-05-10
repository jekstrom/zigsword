const rl = @import("raylib");
const std = @import("std");
const s = @import("../objects/state.zig");
const shop = @import("../objects/shopitem.zig");
const BasicDie = @import("../dice/basic.zig").BasicDie;
const MultDie = @import("../dice/mult.zig").MultDie;

pub const ShopMap = struct {
    shopItems: std.ArrayList(shop.ShopItem),
    background: ?rl.Texture,

    pub fn init(allocator: std.mem.Allocator) !*ShopMap {
        const sm = try allocator.create(ShopMap);
        sm.shopItems = std.ArrayList(shop.ShopItem).init(allocator);
        return sm;
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
        var d6 = try state.allocator.create(BasicDie);
        defer state.allocator.destroy(d6);
        d6.name = "Basic d6";
        d6.sides = 6;
        d6.texture = state.textureMap.get(.D6);
        d6.hovered = false;
        d6.selected = false;
        d6.broken = false;
        d6.breakChance = 0;
        d6.nextResult = 0;
        d6.tooltip = "";
        d6.index = 0;
        d6.pos = .{ .x = -350, .y = state.grid.getCenterPos().y };
        const d6die = try d6.die(&state.allocator);

        var d4 = try state.allocator.create(BasicDie);
        defer state.allocator.destroy(d4);
        d4.name = "Basic d4";
        d4.sides = 4;
        d4.texture = state.textureMap.get(.D4);
        d4.hovered = false;
        d4.selected = false;
        d4.broken = false;
        d4.breakChance = 0;
        d4.nextResult = 0;
        d4.tooltip = "";
        d4.index = 0;
        d4.pos = .{ .x = -250, .y = state.grid.getCenterPos().y };
        const d4die = try d4.die(&state.allocator);

        try self.addShopItem(.{
            .name = "Basic d6",
            .die = d6die,
            .price = 4,
            .pos = .{ .x = -350, .y = state.grid.getCenterPos().y },
            .texture = state.textureMap.get(.SHOPCARD).?,
            .purchased = false,
        });
        try self.addShopItem(.{
            .name = "Crit d4",
            .die = d4die,
            .price = 4,
            .pos = .{ .x = -250, .y = state.grid.getCenterPos().y },
            .texture = state.textureMap.get(.SHOPCARD).?,
            .purchased = false,
        });
    }

    pub fn update(self: *@This(), state: *s.State) !void {
        const mousepos = rl.getMousePosition();
        for (0..self.shopItems.items.len) |i| {
            var item: *shop.ShopItem = &self.shopItems.items[i];
            if (item.purchased) {
                continue;
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
                const lastDieIndex = state.player.dice.?.items.len;
                item.die.?.index = lastDieIndex;

                const purchased = try state.player.purchaseItem(item.*, state);
                if (purchased) {
                    item.purchased = true;
                }
            }
        }
    }
    pub fn draw(self: @This(), state: *s.State) void {
        const dt = rl.getFrameTime();
        for (0..self.shopItems.items.len) |i| {
            var item = &self.shopItems.items[i];
            if (item.purchased) {
                continue;
            }
            const die = item.die.?;
            const dest: f32 = state.grid.getCenterPos().x + @as(f32, @floatFromInt(256 * i));
            _ = item.enter(dest, dt);

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
    }
};
