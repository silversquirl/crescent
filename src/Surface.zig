const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const Surface = @This();

manager: helper.Manager(Surface) = .{},
surface: vk.SurfaceKHR,
instance: *internal.Instance,

pub fn init(instance: *internal.Instance, descriptor: *const gpu.Surface.Descriptor) !Surface {
    const surface = switch (vk.windowing_system) {
        .win32 => try initWin32(instance, descriptor),
        .xlib => try initXlib(instance, descriptor),
    };

    return .{
        .surface = surface,
        .instance = instance,
    };
}

fn initWin32(instance: *internal.Instance, descriptor: *const gpu.Surface.Descriptor) !vk.SurfaceKHR {
    const desc = helper.findChained(
        gpu.Surface.DescriptorFromWindowsHWND,
        descriptor.next_in_chain.generic,
    ) orelse {
        return error.InvalidDescriptor;
    };
    return instance.dispatch.createWin32SurfaceKHR(instance.instance, &.{
        .hinstance = @ptrCast(vk.HINSTANCE, desc.hinstance),
        .hwnd = @ptrCast(vk.HWND, desc.hwnd),
        .flags = .{},
    }, null);
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
    self.instance.allocator().destroy(self);
}
