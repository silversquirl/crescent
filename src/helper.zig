const std = @import("std");
const gpu = @import("gpu");
const Instance = @import("Instance.zig");

// TODO: thread safety?
pub fn Manager(comptime T: type) type {
    return struct {
        refs: u32 = 0,

        const Self = @This();

        pub fn reference(self: *Self) void {
            self.refs += 1;
        }
        pub fn release(self: *Self) void {
            if (self.refs == 0) {
                const parent = @fieldParentPtr(T, "manager", self);
                parent.deinit();
            } else {
                self.refs -= 1;
            }
        }
    };
}

pub fn findChained(comptime T: type, next_in_chain: ?*const gpu.ChainedStruct) ?*const T {
    const search = @ptrCast(*align(1) const gpu.ChainedStruct, std.meta.fieldInfo(T, .chain).default_value.?);
    var chain = next_in_chain;
    while (chain) |c| {
        if (c.s_type == search.s_type) {
            return @ptrCast(*const T, c);
        }
        chain = c.next;
    }
    return null;
}
