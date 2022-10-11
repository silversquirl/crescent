const std = @import("std");
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
