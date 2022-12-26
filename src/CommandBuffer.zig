const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const CommandBuffer = @This();

manager: helper.Manager(CommandBuffer) = .{},
buffer: vk.CommandBuffer,
render_passes: std.ArrayListUnmanaged(*internal.RenderPassEncoder) = .{}, // TODO: compute passes
device: *const internal.Device,

pub fn init(device: *const internal.Device) !CommandBuffer {
    var buffer: vk.CommandBuffer = undefined;
    try device.dispatch.allocateCommandBuffers(device.device, &.{
        .command_pool = device.pool,
        .level = .primary,
        .command_buffer_count = 1,
    }, @as(*[1]vk.CommandBuffer, &buffer));
    try device.dispatch.beginCommandBuffer(buffer, &.{
        .flags = .{},
        .p_inheritance_info = undefined,
    });

    return .{
        .buffer = buffer,
        .device = device,
    };
}

pub fn deinit(self: *CommandBuffer) void {
    self.device.dispatch.freeCommandBuffers(
        self.device.device,
        self.device.pool,
        1,
        @as(*[1]vk.CommandBuffer, &self.buffer),
    );

    for (self.render_passes.items) |pass| {
        pass.manager.release();
    }

    const allocator = self.device.allocator();
    self.render_passes.deinit(allocator);
    allocator.destroy(self);
}
