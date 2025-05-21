const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("objects/state.zig");
const RollResult = @import("dice/rollresult.zig").RollResult;

// Interface for dice
pub const Die = struct {
    ptr: *anyopaque,
    name: [:0]const u8,
    sides: u16,
    pos: rl.Vector2,
    hovered: bool,
    selected: bool,
    texture: ?rl.Texture,
    index: usize,
    breakChance: u7,
    broken: bool,
    nextResult: u16,
    sellPrice: u8,
    tooltip: [:0]const u8,
    getSidesFn: *const fn (ptr: *anyopaque) anyerror!u16,
    getNextResultFn: *const fn (ptr: *anyopaque) anyerror!u16,
    getSellPriceFn: *const fn (ptr: *anyopaque) anyerror!u8,
    getBrokenFn: *const fn (ptr: *anyopaque) anyerror!bool,
    getPosFn: *const fn (ptr: *anyopaque) anyerror!rl.Vector2,
    getHoveredFn: *const fn (ptr: *anyopaque) anyerror!bool,
    getSelectedFn: *const fn (ptr: *anyopaque) anyerror!bool,
    setSelectedFn: *const fn (ptr: *anyopaque, val: bool) anyerror!void,
    getTextureFn: *const fn (ptr: *anyopaque) anyerror!?rl.Texture,
    getIndexFn: *const fn (ptr: *anyopaque) anyerror!usize,
    setIndexFn: *const fn (ptr: *anyopaque, newIndex: usize) anyerror!void,
    getTooltipFn: *const fn (ptr: *anyopaque) anyerror![:0]const u8,
    setTooltipFn: *const fn (ptr: *anyopaque, [:0]const u8) anyerror!void,
    rollFn: *const fn (ptr: *anyopaque, state: *s.State, prevRollResults: *const std.ArrayList(RollResult)) anyerror!RollResult,
    updateFn: *const fn (ptr: *anyopaque, state: *s.State) anyerror!void,
    deinitFn: *const fn (ptr: *anyopaque, state: *s.State) anyerror!void,
    drawFn: *const fn (ptr: *anyopaque, state: *s.State) anyerror!void,
    getNameFn: *const fn (ptr: *anyopaque) anyerror![:0]const u8,

    pub fn getName(self: *@This()) anyerror![:0]const u8 {
        return self.getNameFn(self.ptr);
    }

    pub fn getSides(self: *@This()) anyerror!u16 {
        return self.getSidesFn(self.ptr);
    }

    pub fn getNextResult(self: *@This()) anyerror!u16 {
        return self.getNextResultFn(self.ptr);
    }

    pub fn getSellPrice(self: *@This()) anyerror!u8 {
        return self.getSellPriceFn(self.ptr);
    }

    pub fn getPos(self: *@This()) anyerror!rl.Vector2 {
        return self.getPosFn(self.ptr);
    }

    pub fn getHovered(self: *@This()) anyerror!bool {
        return self.getHoveredFn(self.ptr);
    }

    pub fn getSelected(self: *@This()) anyerror!bool {
        return self.getSelectedFn(self.ptr);
    }

    pub fn setSelected(self: *@This(), val: bool) anyerror!void {
        return self.setSelectedFn(self.ptr, val);
    }

    pub fn getTexture(self: *@This()) anyerror!?rl.Texture {
        return self.getTextureFn(self.ptr);
    }

    pub fn getIndex(self: *@This()) anyerror!usize {
        return self.getIndexFn(self.ptr);
    }

    pub fn getTooltip(self: *@This()) anyerror![:0]const u8 {
        return self.getTooltipFn(self.ptr);
    }

    pub fn setTooltip(self: *@This(), newTooltip: [:0]const u8) anyerror!void {
        return self.setTooltipFn(self.ptr, newTooltip);
    }

    pub fn setIndex(self: *@This(), newIndex: usize) anyerror!void {
        return self.setIndexFn(self.ptr, newIndex);
    }

    pub fn getBroken(self: *@This()) anyerror!bool {
        return self.getBrokenFn(self.ptr);
    }

    pub fn update(self: *@This(), state: *s.State) anyerror!void {
        return self.updateFn(self.ptr, state);
    }

    pub fn roll(self: *@This(), state: *s.State, prevRollResults: *const std.ArrayList(RollResult)) anyerror!RollResult {
        return self.rollFn(self.ptr, state, prevRollResults);
    }

    pub fn draw(self: *@This(), state: *s.State) anyerror!void {
        return self.drawFn(self.ptr, state);
    }

    pub fn deinit(self: *@This(), state: *s.State) anyerror!void {
        return self.deinitFn(self.ptr, state);
    }

    pub fn init(
        ptr: anytype,
        name: [:0]const u8,
        sides: u16,
        pos: rl.Vector2,
        hovered: bool,
        selected: bool,
        texture: ?rl.Texture,
        index: usize,
        breakChance: u7,
        sellPrice: u8,
        tooltip: [:0]const u8,
        allocator: *const std.mem.Allocator,
    ) !*Die {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn update(pointer: *anyopaque, state: *s.State) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.update(self, state);
            }

            pub fn deinit(pointer: *anyopaque, state: *s.State) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.deinit(self, state);
            }

            pub fn draw(pointer: *anyopaque, state: *s.State) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.draw(self, state);
            }

            pub fn roll(pointer: *anyopaque, state: *s.State, prevRollResult: *const std.ArrayList(RollResult)) anyerror!RollResult {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.roll(self, state, prevRollResult);
            }

            pub fn getSides(pointer: *anyopaque) anyerror!u16 {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.getSides, .{self});
            }

            pub fn getNextResult(pointer: *anyopaque) anyerror!u16 {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.getNextResult, .{self});
            }

            pub fn getSellPrice(pointer: *anyopaque) anyerror!u8 {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.getSellPrice, .{self});
            }

            pub fn getPos(pointer: *anyopaque) anyerror!rl.Vector2 {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.getPos, .{self});
            }

            pub fn getHovered(pointer: *anyopaque) anyerror!bool {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.getHovered, .{self});
            }

            pub fn getSelected(pointer: *anyopaque) anyerror!bool {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.getSelected, .{self});
            }

            pub fn setSelected(pointer: *anyopaque, val: bool) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.setSelected, .{ self, val });
            }

            pub fn getTexture(pointer: *anyopaque) anyerror!?rl.Texture {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.getTexture, .{self});
            }

            pub fn getIndex(pointer: *anyopaque) anyerror!usize {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.getIndex, .{self});
            }

            pub fn getTooltip(pointer: *anyopaque) anyerror![:0]const u8 {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.getTooltip, .{self});
            }

            pub fn getName(pointer: *anyopaque) anyerror![:0]const u8 {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.getName, .{self});
            }

            pub fn setTooltip(pointer: *anyopaque, newTooltip: [:0]const u8) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.setTooltip, .{ self, newTooltip });
            }

            pub fn getBroken(pointer: *anyopaque) anyerror!bool {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.getBroken, .{self});
            }

            pub fn setIndex(pointer: *anyopaque, newIndex: usize) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return @call(.always_inline, ptr_info.pointer.child.setIndex, .{ self, newIndex });
            }
        };

        var sobj = try allocator.create(Die);
        sobj.ptr = ptr;
        sobj.name = name;
        sobj.sides = sides;
        sobj.pos = pos;
        sobj.hovered = hovered;
        sobj.selected = selected;
        sobj.texture = texture;
        sobj.index = index;
        sobj.breakChance = breakChance;
        sobj.tooltip = tooltip;
        sobj.sellPrice = sellPrice;
        sobj.getSidesFn = gen.getSides;
        sobj.getNextResultFn = gen.getNextResult;
        sobj.getSellPriceFn = gen.getSellPrice;
        sobj.getPosFn = gen.getPos;
        sobj.getHoveredFn = gen.getHovered;
        sobj.getSelectedFn = gen.getSelected;
        sobj.setSelectedFn = gen.setSelected;
        sobj.getTextureFn = gen.getTexture;
        sobj.getIndexFn = gen.getIndex;
        sobj.getTooltipFn = gen.getTooltip;
        sobj.setTooltipFn = gen.setTooltip;
        sobj.getNameFn = gen.getName;
        sobj.getBrokenFn = gen.getBroken;
        sobj.setIndexFn = gen.setIndex;
        sobj.updateFn = gen.update;
        sobj.deinitFn = gen.deinit;
        sobj.drawFn = gen.draw;
        sobj.rollFn = gen.roll;
        return sobj;
    }
};
