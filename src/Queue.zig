const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const vk = @import("vk.zig");

const Queue = @This();

graphics: vk.Queue,
compute: vk.Queue,
fence: vk.Fence,

pub fn init(dispatch: vk.DeviceDispatch, device: vk.Device, info: internal.Adapter.DeviceInfo) !internal.Queue {
    const fence = try dispatch.createFence(device, &.{
        .flags = .{ .signaled_bit = true }, // So waiting pre-submit doesn't block
    }, null);
    return .{
        .graphics = dispatch.getDeviceQueue(device, info.graphics_family, 0),
        .compute = dispatch.getDeviceQueue(device, info.compute_family, 0),
        .fence = fence,
    };
}

pub fn submit(self: *Queue, commands: []const *const internal.CommandBuffer) !void {
    const device = @fieldParentPtr(internal.Device, "queue", self);

    // TODO: compute
    const submits = try device.allocator().alloc(vk.SubmitInfo, commands.len);
    defer device.allocator().free(submits);
    for (commands) |cmd, i| {
        // TODO: sequencing/synchronization
        submits[i] = .{
            .wait_semaphore_count = 0,
            .p_wait_semaphores = undefined,
            .p_wait_dst_stage_mask = undefined,

            .command_buffer_count = 1,
            .p_command_buffers = @as(*const [1]vk.CommandBuffer, &cmd.buffer),

            .signal_semaphore_count = 0,
            .p_signal_semaphores = undefined,
        };
    }

    try device.dispatch.resetFences(device.device, 1, &[1]vk.Fence{self.fence});
    try device.dispatch.queueSubmit(self.graphics, @intCast(u32, submits.len), submits.ptr, self.fence);
}

pub fn waitTimeout(self: *Queue, timeout: u64) !bool {
    const device = @fieldParentPtr(internal.Device, "queue", self);

    const res = try device.dispatch.waitForFences(
        device.device,
        1,
        &[_]vk.Fence{self.fence},
        vk.TRUE,
        timeout,
    );
    return res == .success;
}
