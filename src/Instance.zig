const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const Instance = @This();

manager: helper.Manager(Instance) = .{},
gpa: std.heap.GeneralPurposeAllocator(.{}),

dispatch: vk.InstanceDispatch,
instance: vk.Instance,

pub fn create(descriptor: ?*const gpu.Instance.Descriptor) !*Instance {
    _ = descriptor;

    const khr_validation = "VK_LAYER_KHRONOS_validation";
    const layers: []const [*:0]const u8 = if (vk.enable_validation and vk.hasLayer(khr_validation))
        &.{khr_validation}
    else
        &.{};

    const system_ext = switch (vk.windowing_system) {
        .win32 => vk.extension_info.khr_win32_surface.name,
        .xlib => vk.extension_info.khr_xlib_surface.name,
    };
    var exts: []const [*:0]const u8 = &.{
        vk.extension_info.khr_surface.name,
        system_ext,
    };

    const desc: vk.InstanceCreateInfo = .{
        .flags = .{},
        .p_application_info = null,
        .enabled_layer_count = @intCast(u32, layers.len),
        .pp_enabled_layer_names = layers.ptr,
        .enabled_extension_count = @intCast(u32, exts.len),
        .pp_enabled_extension_names = exts.ptr,
    };

    const instance = try vk.bd.createInstance(&desc, null);

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    errdefer std.debug.assert(!gpa.deinit());

    const self = try gpa.allocator().create(Instance);
    errdefer gpa.allocator().destroy(self);

    self.* = .{
        .gpa = gpa,
        .dispatch = try vk.InstanceDispatch.load(instance, vk.bd.dispatch.vkGetInstanceProcAddr),
        .instance = instance,
    };

    return self;
}

pub fn deinit(self: *Instance) void {
    self.dispatch.destroyInstance(self.instance, null);
    var gpa = self.gpa;
    gpa.allocator().destroy(self);
    _ = gpa.deinit();
}

pub inline fn allocator(self: *Instance) std.mem.Allocator {
    return self.gpa.allocator();
}

pub fn createSurface(self: *Instance, descriptor: *const gpu.Surface.Descriptor) !*internal.Surface {
    const surface = try self.allocator().create(internal.Surface);
    errdefer self.allocator().destroy(surface);
    surface.* = try internal.Surface.init(self, descriptor);
    return surface;
}

pub fn requestAdapter(self: *Instance, options: ?*const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: ?*anyopaque) void {
    if (self.createAdapter(options)) |adapter| {
        callback(.success, @ptrCast(*gpu.Adapter, adapter), null, userdata);
    } else |err| switch (err) {
        error.NoAdapterFound => callback(.unavailable, undefined, null, userdata),
        else => |e| callback(.err, undefined, @errorName(e), userdata),
    }
}
fn createAdapter(self: *Instance, options: ?*const gpu.RequestAdapterOptions) !*internal.Adapter {
    const adapter = try self.allocator().create(internal.Adapter);
    errdefer self.allocator().destroy(adapter);
    adapter.* = try internal.Adapter.init(self, options orelse &gpu.RequestAdapterOptions{});
    return adapter;
}
