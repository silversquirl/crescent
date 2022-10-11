const std = @import("std");
const builtin = @import("builtin");
const gpu = @import("gpu");

const vk = @import("vk.zig");
const mem = @import("mem.zig");

const Instance = @This();

manager: mem.Manager(Instance) = .{},
gpa: std.heap.GeneralPurposeAllocator(.{}),

id: vk.InstanceDispatch,
ii: vk.Instance,

pub fn create(descriptor: ?*const gpu.Instance.Descriptor) !*Instance {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    errdefer std.debug.assert(!gpa.deinit());

    const instance = try gpa.allocator().create(Instance);
    errdefer gpa.allocator().destroy(instance);

    const enable_validation = builtin.mode == .Debug;
    const khr_validation = "VK_LAYER_KHRONOS_validation";
    const layers: []const [*:0]const u8 = if (enable_validation and vk.hasLayer(khr_validation))
        &.{khr_validation}
    else
        &.{};

    const exts: []const [*:0]const u8 = switch (builtin.target.os.tag) {
        .windows => &.{
            vk.extension_info.khr_surface.name,
            vk.extension_info.khr_win32_surface.name,
        },
        .macos => @compileError("TODO: macos"),
        else => &.{
            vk.extension_info.khr_surface.name,
            vk.extension_info.khr_xlib_surface.name, // TODO: wayland
        },
    };

    const desc: vk.InstanceCreateInfo = .{
        .flags = .{},
        .p_application_info = null,
        .enabled_layer_count = @intCast(u32, layers.len),
        .pp_enabled_layer_names = layers.ptr,
        .enabled_extension_count = @intCast(u32, exts.len),
        .pp_enabled_extension_names = exts.ptr,
    };

    const vk_instance = try vk.bd.createInstance(&desc, null);
    instance.* = .{
        .gpa = gpa,
        .id = try vk.InstanceDispatch.load(vk_instance, vk.bd.dispatch.vkGetInstanceProcAddr),
        .ii = vk_instance,
    };

    _ = descriptor;

    return instance;
}

pub fn deinit(self: *Instance) void {
    var gpa = self.gpa;
    gpa.allocator().destroy(self);
    _ = gpa.deinit();
}
