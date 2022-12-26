const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const TextureView = @This();

manager: helper.Manager(TextureView) = .{},
view: vk.ImageView,
format: vk.Format,
texture: *internal.Texture,

pub fn init(texture: *internal.Texture, descriptor: *const gpu.TextureView.Descriptor) !TextureView {
    const aspect: vk.ImageAspectFlags = if (descriptor.aspect != .all) .{
        .stencil_bit = descriptor.aspect == .stencil_only,
        .depth_bit = descriptor.aspect == .depth_only,
        .plane_0_bit = descriptor.aspect == .plane0_only,
        .plane_1_bit = descriptor.aspect == .plane1_only,
    } else switch (descriptor.format) {
        .stencil8 => .{ .stencil_bit = true },
        .depth16_unorm, .depth24_plus, .depth32_float => .{ .depth_bit = true },
        .depth24_plus_stencil8, .depth32_float_stencil8 => .{
            .depth_bit = true,
            .stencil_bit = true,
        },
        .r8_bg8_biplanar420_unorm => .{
            .plane_0_bit = true,
            .plane_1_bit = true,
        },
        else => .{ .color_bit = true },
    };
    const format = helper.vulkanTextureFormat(descriptor.format);

    const view = try texture.device.dispatch.createImageView(texture.device.device, &.{
        .flags = .{},
        .image = texture.image,
        .view_type = switch (descriptor.dimension) {
            .dimension_undef => unreachable,
            .dimension_1d => vk.ImageViewType.@"1d",
            .dimension_2d => .@"2d",
            .dimension_2d_array => .@"2d_array",
            .dimension_cube => .cube,
            .dimension_cube_array => .cube_array,
            .dimension_3d => .@"3d",
        },
        .format = format,
        .components = .{
            .r = .identity,
            .g = .identity,
            .b = .identity,
            .a = .identity,
        },
        .subresource_range = .{
            .aspect_mask = aspect,
            .base_mip_level = descriptor.base_mip_level,
            .level_count = descriptor.mip_level_count,
            .base_array_layer = descriptor.base_array_layer,
            .layer_count = descriptor.array_layer_count,
        },
    }, null);

    texture.manager.reference();
    return .{
        .view = view,
        .format = format,
        .texture = texture,
    };
}

pub fn deinit(self: *TextureView) void {
    self.texture.device.dispatch.destroyImageView(self.texture.device.device, self.view, null);
    self.texture.manager.release();
    self.texture.device.allocator().destroy(self);
}
