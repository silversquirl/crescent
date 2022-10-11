const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const Surface = @This();

manager: helper.Manager(Surface) = .{},
surface: vk.SurfaceKHR,
instance: *internal.Instance,

pub fn init(self: *Surface, instance: *internal.Instance, descriptor: *const gpu.Surface.Descriptor) !void {
    const surface = switch (vk.windowing_system) {
        .win32 => @compileError("TODO"),
        .xlib => try initXlib(instance, descriptor),
    };

    self.* = .{
        .surface = surface,
        .instance = instance,
    };
}

fn initXlib(instance: *internal.Instance, descriptor: *const gpu.Surface.Descriptor) !vk.SurfaceKHR {
    const desc = helper.findChained(
        gpu.Surface.DescriptorFromXlibWindow,
        descriptor.next_in_chain.generic,
    ) orelse {
        return error.InvalidDescriptor;
    };
    return instance.dispatch.createXlibSurfaceKHR(instance.instance, &.{
        .dpy = @ptrCast(*vk.Display, desc.display),
        .window = desc.window,
        .flags = .{},
    }, null);
}

pub fn deinit(self: *Surface) void {
    self.instance.dispatch.destroySurfaceKHR(self.instance.instance, self.surface, null);
    self.instance.gpa.allocator().destroy(self);
}
