const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const SwapChain = @This();

manager: helper.Manager(SwapChain) = .{},
swapchain: vk.SwapchainKHR,
device: *internal.Device,

pub fn init(device: *internal.Device, surface: *internal.Surface, descriptor: *const gpu.SwapChain.Descriptor) !SwapChain {
    const capabilities = try device.adapter.instance.dispatch.getPhysicalDeviceSurfaceCapabilitiesKHR(
        device.adapter.info.phys_dev,
        surface.surface,
    );

    const swapchain = try device.dispatch.createSwapchainKHR(device.device, &.{
        .flags = .{},
        .surface = surface.surface,
        .min_image_count = @maximum(2, capabilities.min_image_count),
        .image_format = helper.vulkanTextureFormat(descriptor.format),
        .image_color_space = .srgb_nonlinear_khr,
        .image_extent = .{
            .width = descriptor.width,
            .height = descriptor.height,
        },
        .image_array_layers = 1,
        .image_usage = .{
            .transfer_src_bit = descriptor.usage.copy_src,
            .transfer_dst_bit = descriptor.usage.copy_dst,
            .sampled_bit = descriptor.usage.texture_binding,
            .storage_bit = descriptor.usage.storage_binding,
            .color_attachment_bit = descriptor.usage.render_attachment,
        },
        .image_sharing_mode = .exclusive, // FIXME: this is probably wrong but I'm lazy
        .queue_family_index_count = 0,
        .p_queue_family_indices = undefined,
        .pre_transform = .{ .identity_bit_khr = true },
        .composite_alpha = .{ .inherit_bit_khr = true }, // TODO: extension to control this
        .present_mode = switch (descriptor.present_mode) {
            .immediate => vk.PresentModeKHR.immediate_khr,
            .mailbox => .mailbox_khr,
            .fifo => .fifo_khr,
        },
        .clipped = vk.FALSE, // TODO: check if WebGPU actually requires this
        .old_swapchain = .null_handle,
    }, null);

    return .{
        .swapchain = swapchain,
        .device = device,
    };
}
