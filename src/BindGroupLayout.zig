const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const BindGroupLayout = @This();

manager: helper.Manager(BindGroupLayout) = .{},
layout: vk.DescriptorSetLayout,
device: *internal.Device,
