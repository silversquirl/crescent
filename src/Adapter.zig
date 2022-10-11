const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const Adapter = @This();

manager: helper.Manager(Adapter) = .{},
info: DeviceInfo,
instance: *internal.Instance,

pub const DeviceInfo = struct {
    phys_dev: vk.PhysicalDevice,
    props: vk.PhysicalDeviceProperties,
    graphics_family: u32,
    compute_family: u32,
};

pub fn init(instance: *internal.Instance, options: *const gpu.RequestAdapterOptions) !Adapter {
    var devices: [128]vk.PhysicalDevice = undefined;
    var n_devices: u32 = devices.len;
    _ = try instance.dispatch.enumeratePhysicalDevices(
        instance.instance,
        &n_devices,
        &devices,
    );

    var result: ?struct {
        rating: DeviceRating,
        info: DeviceInfo,
    } = null;
    for (devices[0..n_devices]) |dev| {
        // Check device type ranking
        const props = instance.dispatch.getPhysicalDeviceProperties(dev);
        const rating = rateDevice(options.power_preference, props);
        if (result != null and !rating.betterThan(result.?.rating)) {
            // Already found a better device
            continue;
        }

        // Check force fallback
        if (options.force_fallback_adapter and rating != .fallback) {
            continue;
        }

        // TODO: check compatible surface

        // Check queue family support
        var families: [128]vk.QueueFamilyProperties = undefined;
        var n_families: u32 = families.len;
        instance.dispatch.getPhysicalDeviceQueueFamilyProperties(dev, &n_families, &families);

        var graphics_family: ?u32 = null;
        var compute_family: ?u32 = null;
        for (families[0..n_families]) |family, i| {
            const idx = @intCast(u32, i);
            // Prefer the same family for both
            if (family.queue_flags.graphics_bit and family.queue_flags.compute_bit) {
                graphics_family = idx;
                compute_family = idx;
                break;
            }
            // Otherwise, look for individual families
            if (family.queue_flags.graphics_bit and graphics_family == null) {
                graphics_family = idx;
            }
            if (family.queue_flags.compute_bit and compute_family == null) {
                compute_family = idx;
            }
            // Check if we've found all the families we need
            if (graphics_family != null and compute_family != null) {
                break;
            }
        } else {
            continue;
        }

        // Set current best device
        result = .{
            .rating = rating,
            .info = .{
                .phys_dev = dev,
                .props = props,
                .graphics_family = graphics_family.?,
                .compute_family = compute_family.?,
            },
        };
    }
    if (result == null) {
        return error.NoAdapterFound;
    }

    return .{
        .info = result.?.info,
        .instance = instance,
    };
}

/// Classify devices, with reference to power preference
fn rateDevice(power: gpu.PowerPreference, props: vk.PhysicalDeviceProperties) DeviceRating {
    return switch (props.device_type) {
        .integrated_gpu => switch (power) {
            .undef => .good,
            .low_power => .good,
            .high_performance => .bad,
        },
        .discrete_gpu => switch (power) {
            .undef => .good,
            .low_power => .bad,
            .high_performance => .good,
        },
        else => .fallback,
    };
}

const DeviceRating = enum {
    good,
    bad,
    fallback,

    pub fn betterThan(a: DeviceRating, b: DeviceRating) bool {
        return @enumToInt(a) < @enumToInt(b);
    }
};

pub fn deinit(self: *Adapter) void {
    self.instance.allocator().destroy(self);
}

pub fn getProperties(self: *Adapter, properties: *gpu.Adapter.Properties) void {
    properties.* = .{
        .vendor_id = self.info.props.vendor_id,
        .vendor_name = "",
        .architecture = "",
        .device_id = self.info.props.device_id,
        .name = @ptrCast([*:0]const u8, &self.info.props.device_name),
        .driver_description = "",
        .adapter_type = switch (self.info.props.device_type) {
            .discrete_gpu => .discrete_gpu,
            .integrated_gpu => .integrated_gpu,
            .cpu => .cpu,
            else => .unknown,
        },
        .backend_type = .vulkan,
    };
}

pub fn createDevice(self: *Adapter, descriptor: ?*const gpu.Device.Descriptor) !*internal.Device {
    const device = try self.instance.allocator().create(internal.Device);
    errdefer self.instance.allocator().destroy(device);
    device.* = try internal.Device.init(self, descriptor orelse &gpu.Device.Descriptor{});
    return device;
}
