const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const ShaderModule = @This();

manager: helper.Manager(ShaderModule) = .{},
shader: vk.ShaderModule,
device: *internal.Device,

pub fn init(device: *internal.Device, descriptor: *const gpu.ShaderModule.Descriptor) !ShaderModule {
    const spirv = helper.findChained(gpu.ShaderModule.SPIRVDescriptor, descriptor.next_in_chain.generic) orelse return error.InvalidDescriptor;
    const shader = try device.dispatch.createShaderModule(device.device, &.{
        .flags = .{},
        .code_size = spirv.code_size,
        .p_code = spirv.code,
    }, null);
    return .{
        .shader = shader,
        .device = device,
    };
}

pub fn deinit(self: *ShaderModule) void {
    self.device.dispatch.destroyShaderModule(self.device.device, self.shader, null);
    self.device.allocator().destroy(self);
}
