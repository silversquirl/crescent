const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const SwapChain = @This();

manager: helper.Manager(SwapChain) = .{},
swapchain: vk.SwapchainKHR,
current_image: u32 = undefined,
images: []vk.Image,
format: gpu.Texture.Format,
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
    errdefer device.dispatch.destroySwapchainKHR(device.device, swapchain, null);

    // Get swapchain images
    var image_count: u32 = undefined;
    _ = try device.dispatch.getSwapchainImagesKHR(device.device, swapchain, &image_count, null);
    const images = try device.allocator().alloc(vk.Image, image_count);
    errdefer device.allocator().free(images);
    _ = try device.dispatch.getSwapchainImagesKHR(device.device, swapchain, &image_count, images.ptr);

    return .{
        .swapchain = swapchain,
        .images = images,
        .format = descriptor.format,
        .device = device,
    };
}

pub fn deinit(self: *SwapChain) void {
    self.device.dispatch.destroySwapchainKHR(self.device.device, self.swapchain, null);
    self.device.allocator().free(self.images);
    self.device.allocator().destroy(self);
}

pub fn getCurrentTextureView(self: *SwapChain) !*internal.TextureView {
    // TODO: reuse semaphore?
    const semaphore = try self.device.dispatch.createSemaphore(self.device.device, &.{ .flags = .{} }, null);
    defer self.device.dispatch.destroySemaphore(self.device.device, semaphore, null);

    const result = try self.device.dispatch.acquireNextImageKHR(
        self.device.device,
        self.swapchain,
        std.math.maxInt(u64),
        semaphore,
        .null_handle,
    );
    switch (result.result) {
        .success => {},
        .timeout => return error.Timeout,
        else => unreachable,
    }
    self.current_image = result.image_index;

    const tex = internal.Texture{
        .image = self.images[self.current_image],
        .device = self.device,
    };
    return tex.createView(&.{
        .format = self.format,
        .dimension = .dimension_2d,
    });
}

pub fn present(self: *SwapChain) !void {
    _ = try self.device.dispatch.queuePresentKHR(self.device.queue.graphics, &.{
        .wait_semaphore_count = 0,
        .p_wait_semaphores = undefined,
        .swapchain_count = 1,
        .p_swapchains = &[_]vk.SwapchainKHR{self.swapchain},
        .p_image_indices = &[_]u32{self.current_image},
        .p_results = null,
    });
    self.current_image = undefined;
}
