const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const vk = @import("vk.zig");

const Queue = @This();

graphics: vk.Queue,
compute: vk.Queue,

pub fn init(dispatch: vk.DeviceDispatch, device: vk.Device, info: internal.Adapter.DeviceInfo) internal.Queue {
    return .{
        .graphics = dispatch.getDeviceQueue(device, info.graphics_family, 0),
        .compute = dispatch.getDeviceQueue(device, info.compute_family, 0),
    };
}
