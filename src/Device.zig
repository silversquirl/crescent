const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const Device = @This();

manager: helper.Manager(Device) = .{},

dispatch: vk.DeviceDispatch,
device: vk.Device,

queue: internal.Queue,
pool: vk.CommandPool,

adapter: *internal.Adapter,

pub fn init(adapter: *internal.Adapter, descriptor: *const gpu.Device.Descriptor) !Device {
    const queue_infos: []const vk.DeviceQueueCreateInfo = if (adapter.info.graphics_family == adapter.info.compute_family)
        &.{.{
            .flags = .{},
            .queue_family_index = adapter.info.graphics_family,
            .queue_count = 1,
            .p_queue_priorities = &[1]f32{1.0},
        }}
    else
        &.{ .{
            .flags = .{},
            .queue_family_index = adapter.info.graphics_family,
            .queue_count = 1,
            .p_queue_priorities = &[1]f32{1.0},
        }, .{
            .flags = .{},
            .queue_family_index = adapter.info.compute_family,
            .queue_count = 1,
            .p_queue_priorities = &[1]f32{1.0},
        } };

    const exts: []const [*:0]const u8 = &.{
        vk.extension_info.khr_swapchain.name,
    };

    // TODO: debug label
    _ = descriptor;
    const device = try adapter.instance.dispatch.createDevice(adapter.info.phys_dev, &.{
        .flags = .{},
        .queue_create_info_count = @intCast(u32, queue_infos.len),
        .p_queue_create_infos = queue_infos.ptr,
        .enabled_layer_count = 0,
        .pp_enabled_layer_names = undefined,
        .enabled_extension_count = @intCast(u32, exts.len),
        .pp_enabled_extension_names = exts.ptr,
        .p_enabled_features = null, // TODO
    }, null);
    const dispatch = vk.DeviceDispatch.load(
        device,
        adapter.instance.dispatch.dispatch.vkGetDeviceProcAddr,
    ) catch |err| {
        // If the DeviceDispatch fails to load, we can't destroy the device
        std.log.warn("leaked vulkan device due to error", .{});
        return err;
    };
    errdefer dispatch.destroyDevice(device, null);

    const pool = try dispatch.createCommandPool(device, &.{
        .flags = .{},
        .queue_family_index = adapter.info.graphics_family,
    }, null);
    errdefer dispatch.destroyCommandPool(device, pool, null);

    return .{
        .dispatch = dispatch,
        .device = device,
        .queue = try internal.Queue.init(dispatch, device, adapter.info),
        .pool = pool,
        .adapter = adapter,
    };
}

pub fn deinit(self: *Device) void {
    self.dispatch.destroyCommandPool(self.device, self.pool, null);
    self.dispatch.destroyDevice(self.device, null);
    self.adapter.instance.allocator().destroy(self);
}

pub inline fn allocator(self: Device) std.mem.Allocator {
    return self.adapter.instance.allocator();
}

pub fn getQueue(self: *Device) *internal.Queue {
    return &self.queue;
}

pub fn setUncapturedErrorCallback(self: *Device, callback: ?gpu.ErrorCallback, userdata: ?*anyopaque) void {
    _ = self;
    _ = callback;
    _ = userdata;
    std.log.warn("setUncapturedErrorCallback is not yet implemented", .{});
}

pub fn createShaderModule(self: *Device, descriptor: *const gpu.ShaderModule.Descriptor) !*internal.ShaderModule {
    const shader = try self.allocator().create(internal.ShaderModule);
    errdefer self.allocator().destroy(shader);
    shader.* = try internal.ShaderModule.init(self, descriptor);
    return shader;
}

pub fn createRenderPipeline(self: *Device, descriptor: *const gpu.RenderPipeline.Descriptor) !*internal.RenderPipeline {
    const pipeline = try self.allocator().create(internal.RenderPipeline);
    errdefer self.allocator().destroy(pipeline);
    pipeline.* = try internal.RenderPipeline.init(self, descriptor);
    return pipeline;
}

pub fn createPipelineLayout(self: *Device, descriptor: *const gpu.PipelineLayout.Descriptor) !*internal.PipelineLayout {
    const layout = try self.allocator().create(internal.PipelineLayout);
    errdefer self.allocator().destroy(layout);
    layout.* = try internal.PipelineLayout.init(self, descriptor);
    return layout;
}

pub fn createSwapChain(self: *Device, surface: ?*internal.Surface, descriptor: *const gpu.SwapChain.Descriptor) !*internal.SwapChain {
    const swapchain = try self.allocator().create(internal.SwapChain);
    errdefer self.allocator().destroy(swapchain);
    swapchain.* = try internal.SwapChain.init(self, surface.?, descriptor);
    return swapchain;
}

pub fn createCommandEncoder(self: *const Device, descriptor: ?*const gpu.CommandEncoder.Descriptor) !*internal.CommandEncoder {
    const encoder = try self.allocator().create(internal.CommandEncoder);
    errdefer self.allocator().destroy(encoder);
    encoder.* = try internal.CommandEncoder.init(self, descriptor);
    return encoder;
}
