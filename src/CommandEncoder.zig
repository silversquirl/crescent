const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const CommandEncoder = @This();

manager: helper.Manager(CommandEncoder) = .{},
buffer: vk.CommandBuffer,
device: *const internal.Device,

pub fn init(device: *const internal.Device, descriptor: ?*const gpu.CommandEncoder.Descriptor) !CommandEncoder {
    _ = descriptor;

    var buffer: vk.CommandBuffer = undefined;
    try device.dispatch.allocateCommandBuffers(device.device, &.{
        .command_pool = device.pool,
        .level = .primary,
        .command_buffer_count = 1,
    }, @as(*[1]vk.CommandBuffer, &buffer));

    return .{
        .buffer = buffer,
        .device = device,
    };
}

pub fn deinit(self: *CommandEncoder) void {
    self.device.dispatch.freeCommandBuffers(
        self.device.device,
        self.device.pool,
        1,
        @as(*[1]vk.CommandBuffer, &self.buffer),
    );
    self.device.allocator().destroy(self);
}
