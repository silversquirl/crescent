const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const vk = @import("vk.zig");

const Queue = @This();

graphics: vk.Queue,
compute: vk.Queue,
fence: vk.Fence,
buffers: std.ArrayListUnmanaged(*internal.CommandBuffer) = .{},

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
pub fn deinit(self: *Queue) void {
    const device = @fieldParentPtr(internal.Device, "queue", self);
    for (self.buffers.items) |buf| {
        buf.manager.release();
    }
    self.buffers.deinit(device.allocator());
    device.dispatch.destroyFence(device.device, self.fence, null);
}

pub fn submit(self: *Queue, commands: []const *internal.CommandBuffer) !void {
    const device = @fieldParentPtr(internal.Device, "queue", self);

    // Release previous buffers
    // TODO: free earlier if we run out of memory
    // TODO: finer-grained freeing based on a few fences instead of just one?
    try self.waitUncapped();
    for (self.buffers.items) |buf| {
        buf.manager.release();
    }
    errdefer self.buffers.clearRetainingCapacity();

    // Collect new buffers
    try self.buffers.resize(device.allocator(), commands.len);
    std.mem.copy(*internal.CommandBuffer, self.buffers.items, commands);

    // TODO: compute
    const submits = try device.allocator().alloc(vk.SubmitInfo, commands.len);
    defer device.allocator().free(submits);
    for (commands) |buf, i| {
        buf.manager.reference();
        // TODO: sequencing/synchronization
        submits[i] = .{
            .wait_semaphore_count = 0,
            .p_wait_semaphores = undefined,
            .p_wait_dst_stage_mask = undefined,

            .command_buffer_count = 1,
            .p_command_buffers = @as(*const [1]vk.CommandBuffer, &buf.buffer),

            .signal_semaphore_count = 0,
            .p_signal_semaphores = undefined,
        };
    }

    try device.dispatch.resetFences(device.device, 1, &[1]vk.Fence{self.fence});
    try device.dispatch.queueSubmit(self.graphics, @intCast(u32, submits.len), submits.ptr, self.fence);
}

pub fn waitUncapped(self: *Queue) !void {
    while (!try self.waitTimeout(std.math.maxInt(u64))) {}
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
