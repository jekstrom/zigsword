const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("../objects/state.zig");

// State machine state types
pub const SMStateType = enum(u8) {
    TUTORIAL,
    WALKING,
    BATTLE,
    SHOP,
    ADVENTURERDEATH,
    GAMEEND,
};

// Interface for state machine states
pub const SMState = struct {
    ptr: *anyopaque,
    smType: SMStateType,
    isComplete: bool,
    startTime: f64,
    nextState: ?*SMState,
    getIsCompleteFn: *const fn (ptr: *anyopaque) anyerror!bool,
    updateFn: *const fn (ptr: *anyopaque, state: *s.State) anyerror!void,
    enterFn: *const fn (ptr: *anyopaque, state: *s.State) anyerror!void,
    exitFn: *const fn (ptr: *anyopaque, state: *s.State) anyerror!void,

    pub fn getIsComplete(self: *@This()) anyerror!bool {
        return self.getIsCompleteFn(self.ptr);
    }

    pub fn update(self: *@This(), state: *s.State) anyerror!void {
        return self.updateFn(self.ptr, state);
    }

    pub fn enter(self: *@This(), state: *s.State) anyerror!void {
        return self.enterFn(self.ptr, state);
    }

    pub fn exit(self: *@This(), state: *s.State) anyerror!void {
        return self.exitFn(self.ptr, state);
    }

    pub fn init(
        ptr: anytype,
        smType: SMStateType,
        nextState: ?*SMState,
        allocator: *const std.mem.Allocator,
    ) !*SMState {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn update(pointer: *anyopaque, state: *s.State) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.update(self, state);
            }

            pub fn enter(pointer: *anyopaque, state: *s.State) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.enter(self, state);
            }

            pub fn exit(pointer: *anyopaque, state: *s.State) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.exit(self, state);
            }

            pub fn getIsComplete(pointer: *anyopaque) anyerror!bool {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");

                return @call(.always_inline, ptr_info.pointer.child.getIsComplete, .{self});
            }
        };

        // Allocate memory using provided allocator
        var sobj = try allocator.create(SMState);
        sobj.isComplete = false;
        sobj.smType = smType;
        sobj.startTime = rl.getTime();
        sobj.nextState = nextState;
        sobj.ptr = ptr;
        sobj.getIsCompleteFn = gen.getIsComplete;
        sobj.updateFn = gen.update;
        sobj.enterFn = gen.enter;
        sobj.exitFn = gen.exit;
        return sobj;
    }
};
