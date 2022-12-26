const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const CommandEncoder = @This();

manager: helper.Manager(CommandEncoder) = .{},
buffer: *internal.CommandBuffer,

pub fn init(device: *const internal.Device, descriptor: ?*const gpu.CommandEncoder.Descriptor) !CommandEncoder {
    _ = descriptor;
    const buffer = try device.allocator().create(internal.CommandBuffer);
    errdefer device.allocator().destroy(buffer);
    buffer.* = try internal.CommandBuffer.init(device);
    return .{ .buffer = buffer };
}

pub fn deinit(self: *CommandEncoder) void {
    const buffer = self.buffer;
    buffer.device.allocator().destroy(self);
    buffer.manager.release();
}

pub fn beginRenderPass(self: *CommandEncoder, descriptor: ?*const gpu.RenderPassDescriptor) !*internal.RenderPassEncoder {
    const allocator = self.buffer.device.allocator();
    const encoder = try allocator.create(internal.RenderPassEncoder);
    errdefer allocator.destroy(encoder);
    encoder.* = try internal.RenderPassEncoder.init(self, descriptor.?);
    return encoder;
}

pub fn finish(self: *CommandEncoder, descriptor: ?*const gpu.CommandBuffer.Descriptor) !*internal.CommandBuffer {
    _ = descriptor;
    try self.buffer.device.dispatch.endCommandBuffer(self.buffer.buffer);
    self.buffer.manager.reference();
    return self.buffer;
}
