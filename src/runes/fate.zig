const rl = @import("raylib");
const ui = @import("raygui");
const std = @import("std");
const s = @import("../objects/state.zig");
const Rune = @import("rune.zig").Rune;
const RollResult = @import("../dice/rollresult.zig").RollResult;
const Die = @import("../die.zig").Die;
const BasicDie = @import("../dice/basic.zig").BasicDie;

// A Fate Rune lets you know what the result of a random die will be before you roll it,
pub const FateRune = struct {
    name: [:0]const u8 = "ᛈ Fate",
    pos: rl.Vector2,

    pub fn getName(ptr: *anyopaque) anyerror![:0]const u8 {
        const self: *FateRune = @ptrCast(@alignCast(ptr));
        return self.name;
    }

    pub fn getPos(ptr: *anyopaque) anyerror!rl.Vector2 {
        const self: *FateRune = @ptrCast(@alignCast(ptr));
        return self.pos;
    }

    pub fn draw(ptr: *anyopaque, state: *s.State) void {
        _ = state;
        const self: *FateRune = @ptrCast(@alignCast(ptr));

        rl.drawText(
            "ᛈ Fate",
            @as(i32, @intFromFloat(self.pos.x)),
            @as(i32, @intFromFloat(self.pos.y)),
            32,
            .black,
        );
    }

    pub fn handle(ptr: *anyopaque, state: *s.State, rollResults: ?*std.ArrayList(RollResult)) !void {
        const self: *FateRune = @ptrCast(@alignCast(ptr));
        _ = self;
        _ = rollResults;

        // pick a random die and show the what the next result will be
        if (state.player.dice == null) {
            std.debug.print("No dice\n", .{});
            std.debug.assert(false);
        }

        if (state.player.dice.?.items.len == 0) {
            return;
        }

        for (0..state.player.dice.?.items.len) |i| {
            const d = state.player.dice.?.items[i];
            const tt = try d.getTooltip();
            if (tt.len > 0) {
                // There is already a die with an extra tooltip, skip.
                return;
            }
        }

        const numDice: u16 = @as(u16, @intCast(state.player.dice.?.items.len));

        const dieRand = state.rand.intRangeAtMost(u16, 0, numDice - 1);

        const d = state.player.dice.?.items[dieRand];
        const nextResult: u16 = try d.getNextResult();

        std.debug.print("Next result: {d}\n", .{nextResult});

        var floatLog: f16 = 1.0;
        if (nextResult > 0) {
            floatLog = @floor(@log10(@as(f16, @floatFromInt(nextResult))) + 1.0);

            const digits: u64 = @as(u64, @intFromFloat(floatLog));

            const buffer = try state.allocator.allocSentinel(
                u8,
                10 + digits,
                0,
            );

            _ = std.fmt.bufPrint(
                buffer,
                "Will roll {d}",
                .{nextResult},
            ) catch "";

            try d.setTooltip(&buffer);
        }
    }

    pub fn rune(self: *FateRune, allocator: *const std.mem.Allocator) !*Rune {
        return try Rune.init(
            self,
            self.name,
            allocator,
        );
    }
};
