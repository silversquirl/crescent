const std = @import("std");
const builtin = @import("builtin");
const vk = @import("gen/vk.zig");

pub usingnamespace vk;

pub const BaseDispatch = vk.BaseWrapper(.{
    .createInstance = true,
    .getInstanceProcAddr = true,
    .enumerateInstanceLayerProperties = true,
});
pub const InstanceDispatch = vk.InstanceWrapper(.{
    .destroyInstance = true,

    .createDevice = true,
    .getDeviceProcAddr = true,

    .createXlibSurfaceKHR = windowing_system == .xlib,
    .createWin32SurfaceKHR = windowing_system == .win32,
    .destroySurfaceKHR = true,

    .enumeratePhysicalDevices = true,
    .getPhysicalDeviceProperties = true,
    .getPhysicalDeviceQueueFamilyProperties = true,
});
pub const DeviceDispatch = vk.DeviceWrapper(.{
    .destroyDevice = true,

    .createShaderModule = true,
    .destroyShaderModule = true,
});

pub var bd: BaseDispatch = undefined;
var lib: ?std.DynLib = null;

pub fn init() !void {
    if (lib == null) {
        const lib_name = switch (@import("builtin").target.os.tag) {
            .windows => "vulkan-1.dll",
            .macos => "libvulkan.1.dylib",
            .openbsd, .netbsd => "libvulkan.so",
            else => "libvulkan.so.1",
        };

        lib = try std.DynLib.open(lib_name);
        errdefer {
            lib.?.close();
            lib = null;
        }

        bd = try BaseDispatch.load(getBootstrapProcAddress);
    }
}

fn getBootstrapProcAddress(_: vk.Instance, name_ptr: [*:0]const u8) vk.PfnVoidFunction {
    var name = std.mem.span(name_ptr);
    return lib.?.lookup(vk.PfnVoidFunction, name) orelse null;
}

pub fn hasLayer(name: []const u8) bool {
    var layers: [128]vk.LayerProperties = undefined;
    var layer_count: u32 = layers.len;
    _ = bd.enumerateInstanceLayerProperties(&layer_count, &layers) catch return false;

    for (layers[0..layer_count]) |supported| {
        if (std.mem.eql(u8, name, std.mem.sliceTo(&supported.layer_name, 0))) {
            return true;
        }
    }
    return false;
}

pub const WindowingSystem = enum {
    win32,
    xlib,
    // TODO: wayland
    // TODO: macos
};
// TODO: support multiple windowing systems simultaneously (eg. xlib and wayland)
pub const windowing_system: WindowingSystem = switch (builtin.target.os.tag) {
    .windows => .win32,
    .macos => @compileError("TODO: macos"),
    else => .xlib,
};

pub const enable_validation = builtin.mode == .Debug;
