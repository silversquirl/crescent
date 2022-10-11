const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const PipelineLayout = @This();

manager: helper.Manager(PipelineLayout) = .{},
layout: vk.PipelineLayout,
device: *internal.Device,

pub fn init(device: *internal.Device, descriptor: *const gpu.PipelineLayout.Descriptor) !PipelineLayout {
    const groups = try device.allocator().alloc(vk.DescriptorSetLayout, descriptor.bind_group_layout_count);
    defer device.allocator().free(groups);
    for (groups) |*l, i| {
        l.* = helper.castOpaque(*internal.BindGroupLayout, descriptor.bind_group_layouts.?[i]).layout;
    }

    const layout = try device.dispatch.createPipelineLayout(device.device, &.{
        .flags = .{},
        .set_layout_count = @intCast(u32, groups.len),
        .p_set_layouts = groups.ptr,
        .push_constant_range_count = 0,
        .p_push_constant_ranges = undefined,
    }, null);

    return .{
        .layout = layout,
        .device = device,
    };
}

pub fn deinit(self: *PipelineLayout) void {
    self.device.dispatch.destroyPipelineLayout(self.device.device, self.layout, null);
    self.device.allocator().destroy(self);
}
