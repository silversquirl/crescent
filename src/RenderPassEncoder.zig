const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const RenderPassEncoder = @This();

manager: helper.Manager(RenderPassEncoder) = .{},

fb: vk.Framebuffer = .null_handle,
attachments: []const vk.ImageView,
extent: vk.Extent2D,
clear_values: []const vk.ClearValue,

buffer: *internal.CommandBuffer,

pub fn init(encoder: *internal.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) !RenderPassEncoder {
    const allocator = encoder.buffer.device.allocator();
    const attachments = try allocator.alloc(vk.ImageView, descriptor.color_attachment_count + @boolToInt(descriptor.depth_stencil_attachment != null));
    errdefer allocator.free(attachments);

    var extent: ?vk.Extent2D = null;
    var clear_value_count: usize = 0;

    {
        var i: usize = 0;
        while (i < descriptor.color_attachment_count) : (i += 1) {
            const attach = descriptor.color_attachments.?[i];
            const view = helper.castOpaque(*internal.TextureView, attach.view);
            attachments[i] = view.view;

            if (attach.load_op == .clear) {
                clear_value_count += 1;
            }

            if (extent) |e| {
                std.debug.assert(std.meta.eql(e, view.texture.extent));
            } else {
                extent = view.texture.extent;
            }
        }

        if (descriptor.depth_stencil_attachment) |attach| {
            const view = helper.castOpaque(*internal.TextureView, attach.view);
            attachments[i] = view.view;
            i += 1;

            if (attach.depth_load_op == .clear or attach.stencil_load_op == .clear) {
                clear_value_count += 1;
            }

            if (extent) |e| {
                std.debug.assert(std.meta.eql(e, view.texture.extent));
            } else {
                extent = view.texture.extent;
            }
        }

        std.debug.assert(i == attachments.len);
    }

    const clear_values = try allocator.alloc(vk.ClearValue, clear_value_count);
    errdefer allocator.free(clear_values);
    {
        var i: usize = 0;
        var j: usize = 0;
        while (i < descriptor.color_attachment_count) : (i += 1) {
            const attach = descriptor.color_attachments.?[i];
            if (attach.load_op == .clear) {
                const v = attach.clear_value;
                clear_values[j] = .{
                    .color = .{
                        // TODO: adjust for format
                        .float_32 = .{
                            @floatCast(f32, v.r),
                            @floatCast(f32, v.g),
                            @floatCast(f32, v.b),
                            @floatCast(f32, v.a),
                        },
                    },
                };
                j += 1;
            }
        }

        if (descriptor.depth_stencil_attachment) |attach| {
            i += 1;

            if (attach.depth_load_op == .clear or attach.stencil_load_op == .clear) {
                clear_values[j] = .{
                    .depth_stencil = .{
                        .depth = attach.depth_clear_value,
                        .stencil = attach.stencil_clear_value,
                    },
                };
                j += 1;
            }
        }

        std.debug.assert(i == attachments.len);
        std.debug.assert(j == clear_values.len);
    }

    // TODO: occlusion queries
    // TODO: timestamp writes

    // TODO: catch release of encoder before pass is finished (weak ref of some kind?)

    return .{
        .attachments = attachments,
        .extent = extent.?,
        .clear_values = clear_values,
        .buffer = encoder.buffer,
    };
}

pub fn deinit(self: *RenderPassEncoder) void {
    const device = self.buffer.device;
    device.dispatch.destroyFramebuffer(device.device, self.fb, null); // TODO: cache framebuffers

    const allocator = device.allocator();
    allocator.free(self.attachments);
    allocator.free(self.clear_values);
    allocator.destroy(self);
}

pub fn setPipeline(self: *RenderPassEncoder, pipeline: *internal.RenderPipeline) !void {
    const device = self.buffer.device;

    self.fb = try device.dispatch.createFramebuffer(device.device, &.{
        .flags = .{},
        .render_pass = pipeline.pass,
        .attachment_count = @intCast(u32, self.attachments.len),
        .p_attachments = self.attachments.ptr,
        .width = self.extent.width,
        .height = self.extent.height,
        .layers = 1, // TODO
    }, null);
    errdefer device.dispatch.destroyFramebuffer(device.device, self.fb, null);

    const buf = self.buffer.buffer;
    const rect = vk.Rect2D{
        .offset = .{ .x = 0, .y = 0 },
        .extent = self.extent,
    };
    device.dispatch.cmdBeginRenderPass(buf, &.{
        .render_pass = pipeline.pass,
        .framebuffer = self.fb,
        .render_area = rect,
        .clear_value_count = @intCast(u32, self.clear_values.len),
        .p_clear_values = self.clear_values.ptr,
    }, .@"inline");

    try self.buffer.render_passes.append(device.allocator(), self);
    self.manager.reference(); // Command buffer now references this pass

    device.dispatch.cmdBindPipeline(buf, .graphics, pipeline.pipeline);

    // Set default dynamic state
    // TODO: may need to flip viewport (requires vk1.1?)
    device.dispatch.cmdSetViewport(buf, 0, 1, @as(*const [1]vk.Viewport, &vk.Viewport{
        .x = 0,
        .y = 0,
        .width = @intToFloat(f32, self.extent.width),
        .height = @intToFloat(f32, self.extent.height),
        .min_depth = 0,
        .max_depth = 1,
    }));

    device.dispatch.cmdSetScissor(buf, 0, 1, @as(*const [1]vk.Rect2D, &rect));
}

pub fn draw(self: *RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
    const buf = self.buffer;
    buf.device.dispatch.cmdDraw(buf.buffer, vertex_count, instance_count, first_vertex, first_instance);
}

pub fn end(self: *RenderPassEncoder) void {
    const buf = self.buffer;
    buf.device.dispatch.cmdEndRenderPass(buf.buffer);
}
