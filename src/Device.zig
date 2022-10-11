const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const Device = @This();

manager: helper.Manager(Device) = .{},
dispatch: vk.DeviceDispatch,
device: vk.Device,
adapter: *internal.Adapter,

pub fn init(adapter: *internal.Adapter, descriptor: *const gpu.Device.Descriptor) !Device {
    const queue_infos: []vk.DeviceQueueCreateInfo = if (adapter.info.graphics_family == adapter.info.compute_family)
        &.{.{
            .flags = .{},
            .queue_family_index = adapter.info.graphics_family,
            .queue_count = 1,
            .p_queue_priorities = &[1]f32{1.0},
        }}
    else
        &.{ .{
            .flags = .{},
            .queue_family_index = adapter.info.graphics_family,
            .queue_count = 1,
            .p_queue_priorities = &[1]f32{1.0},
        }, .{
            .flags = .{},
            .queue_family_index = adapter.info.compute_family,
            .queue_count = 1,
            .p_queue_priorities = &[1]f32{1.0},
        } };

    const exts: []const [*:0]const u8 = &.{
        vk.extension_info.khr_swapchain.name,
    };

    // TODO: debug label
    _ = descriptor;
    const device = try adapter.instance.dispatch.createDevice(adapter.info.phys_dev, &.{
        .flags = .{},
        .queue_create_info_count = @intCast(u32, queue_infos.len),
        .p_queue_create_infos = queue_infos.ptr,
        .enabled_layer_count = 0,
        .pp_enabled_layer_names = undefined,
        .enabled_extension_count = @intCast(u32, exts.len),
        .pp_enabled_extension_names = exts.ptr,
        .p_enabled_features = null, // TODO
    }, null);
    // If the DeviceDispatch fails to load, we can't destroy the device
    errdefer std.log.warn("leaked vulkan device due to error", .{});

    return .{
        .dispatch = try vk.DeviceDispatch.load(
            device,
            adapter.instance.dispatch.dispatch.vkGetDeviceProcAddr,
        ),
        .device = device,
        .adapter = adapter,
    };
}

pub fn deinit(self: *Device) void {
    self.dispatch.destroyDevice(self.device, null);
    self.adapter.instance.allocator().destroy(self);
}
