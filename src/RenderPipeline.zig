const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const RenderPipeline = @This();

manager: helper.Manager(RenderPipeline) = .{},
pass: vk.RenderPass,
pipeline: vk.Pipeline,
device: *internal.Device,

pub fn init(device: *internal.Device, descriptor: *const gpu.RenderPipeline.Descriptor) !RenderPipeline {
    const allocator = device.allocator();

    const multisample_count_vk = helper.vulkanSampleCountFlags(descriptor.multisample.count);

    // Create render pass
    // TODO: may be best to defer vulkan render pass (and hence pipeline) creation until it's
    //       used with a render pass? Would require recreating the pipeline if it's used again
    //       with an incompatible render pass.
    var attachments: []vk.AttachmentDescription = &.{};
    defer allocator.free(attachments);
    var color_attachments: []vk.AttachmentReference = &.{};
    defer allocator.free(color_attachments);

    if (descriptor.depth_stencil != null) {
        @panic("TODO: depth_stencil");
    }
    if (descriptor.fragment) |frag| {
        attachments = try allocator.alloc(vk.AttachmentDescription, frag.target_count);
        for (attachments) |*a, i| {
            a.* = .{
                .flags = .{ .may_alias_bit = true }, // TODO: do we actually need this? Check spec
                .format = helper.vulkanTextureFormat(frag.targets.?[i].format),
                .samples = multisample_count_vk,
                .load_op = .clear, // TODO
                .store_op = .store, // TODO
                .stencil_load_op = .dont_care,
                .stencil_store_op = .dont_care,
                .initial_layout = .undefined, // TODO
                .final_layout = .present_src_khr, // TODO
            };
        }

        color_attachments = try allocator.alloc(vk.AttachmentReference, frag.target_count);
        for (color_attachments) |*a, i| {
            a.* = .{
                .attachment = @intCast(u32, i),
                .layout = .general,
            };
        }
    }

    const pass = try device.dispatch.createRenderPass(device.device, &.{
        .flags = .{},
        .attachment_count = @intCast(u32, attachments.len),
        .p_attachments = attachments.ptr,
        .subpass_count = 1,
        .p_subpasses = &[1]vk.SubpassDescription{.{
            .flags = .{},
            .pipeline_bind_point = .graphics,
            .input_attachment_count = 0,
            .p_input_attachments = undefined,
            .color_attachment_count = @intCast(u32, color_attachments.len),
            .p_color_attachments = color_attachments.ptr,
            .p_resolve_attachments = null, // TODO
            .p_depth_stencil_attachment = null, // TODO
            .preserve_attachment_count = 0, // TODO
            .p_preserve_attachments = undefined,
        }},
        .dependency_count = 0,
        .p_dependencies = undefined,
    }, null);

    // Configure blend attachments
    var blend_attachments = try allocator.alloc(vk.PipelineColorBlendAttachmentState, attachments.len);
    defer allocator.free(blend_attachments);
    for (blend_attachments) |*vk_blend, i| {
        const target = descriptor.fragment.?.targets.?[i];
        if (target.blend) |blend| {
            vk_blend.* = .{
                .blend_enable = vk.TRUE,
                .src_color_blend_factor = helper.vulkanBlendFactor(blend.color.src_factor),
                .dst_color_blend_factor = helper.vulkanBlendFactor(blend.color.dst_factor),
                .color_blend_op = helper.vulkanBlendOp(blend.color.operation),
                .src_alpha_blend_factor = helper.vulkanBlendFactor(blend.alpha.src_factor),
                .dst_alpha_blend_factor = helper.vulkanBlendFactor(blend.alpha.dst_factor),
                .alpha_blend_op = helper.vulkanBlendOp(blend.alpha.operation),
                .color_write_mask = .{
                    .r_bit = target.write_mask.red,
                    .g_bit = target.write_mask.green,
                    .b_bit = target.write_mask.blue,
                    .a_bit = target.write_mask.alpha,
                },
            };
        } else {
            vk_blend.blend_enable = vk.FALSE;
        }
    }

    // Create shader stages
    var stages: [2]vk.PipelineShaderStageCreateInfo = undefined;
    var stage_count: u32 = 1;

    // TODO: specialization constants
    const vertex_shader = helper.castOpaque(*internal.ShaderModule, descriptor.vertex.module);
    stages[0] = .{
        .flags = .{},
        .stage = .{ .vertex_bit = true },
        .module = vertex_shader.shader,
        .p_name = descriptor.vertex.entry_point,
        .p_specialization_info = null,
    };

    if (descriptor.fragment) |frag| {
        stage_count += 1;
        const frag_shader = helper.castOpaque(*internal.ShaderModule, frag.module);
        stages[1] = .{
            .flags = .{},
            .stage = .{ .fragment_bit = true },
            .module = frag_shader.shader,
            .p_name = frag.entry_point,
            .p_specialization_info = null,
        };
    }

    // Configure vertex stage
    const vbinds = try allocator.alloc(vk.VertexInputBindingDescription, descriptor.vertex.buffer_count);
    defer allocator.free(vbinds);
    var vattrs = std.ArrayList(vk.VertexInputAttributeDescription).init(allocator);
    defer vattrs.deinit();
    for (vbinds) |*bind, i| {
        const bind_idx = @intCast(u32, i);
        const buf = descriptor.vertex.buffers.?[i];
        bind.* = .{
            .binding = bind_idx,
            .stride = @intCast(u32, buf.array_stride),
            .input_rate = switch (buf.step_mode) {
                .vertex => .vertex,
                .instance => .instance,
                .vertex_buffer_not_used => undefined,
            },
        };

        var j: usize = 0;
        while (j < buf.attribute_count) : (j += 1) {
            const attr = buf.attributes.?[j];
            try vattrs.append(.{
                .location = attr.shader_location,
                .binding = bind_idx,
                .format = helper.vulkanVertexFormat(attr.format),
                .offset = @intCast(u32, attr.offset),
            });
        }
    }

    var pipelines: [1]vk.Pipeline = undefined;
    _ = try device.dispatch.createGraphicsPipelines(device.device, .null_handle, 1, &[_]vk.GraphicsPipelineCreateInfo{.{
        .flags = .{},
        .stage_count = stage_count,
        .p_stages = &stages,

        .p_vertex_input_state = &.{
            .flags = .{},
            .vertex_binding_description_count = @intCast(u32, vbinds.len),
            .p_vertex_binding_descriptions = vbinds.ptr,
            .vertex_attribute_description_count = @intCast(u32, vattrs.items.len),
            .p_vertex_attribute_descriptions = vattrs.items.ptr,
        },

        .p_input_assembly_state = &.{
            .flags = .{},
            .topology = switch (descriptor.primitive.topology) {
                .point_list => vk.PrimitiveTopology.point_list,
                .line_list => .line_list,
                .line_strip => .line_strip,
                .triangle_list => .triangle_list,
                .triangle_strip => .triangle_strip,
            },
            .primitive_restart_enable = vk.FALSE, // TODO
        },

        .p_tessellation_state = null,

        .p_viewport_state = &.{
            .flags = .{},
            .viewport_count = 1,
            .p_viewports = undefined, // Dynamic
            .scissor_count = 1,
            .p_scissors = undefined, // Dynamic
        },

        .p_rasterization_state = &.{
            .flags = .{},
            .depth_clamp_enable = vk.FALSE,
            .rasterizer_discard_enable = vk.FALSE,
            .polygon_mode = .fill, // TODO: Having a "wireframe" extension might be nice for debugging
            .cull_mode = .{
                .front_bit = descriptor.primitive.cull_mode == .front,
                .back_bit = descriptor.primitive.cull_mode == .back,
            },
            .front_face = switch (descriptor.primitive.front_face) {
                .ccw => vk.FrontFace.counter_clockwise,
                .cw => .clockwise,
            },

            // TODO: I'm mostly guessing on how this works. The WebGPU spec doesn't really cover it
            // TODO: this code is ugly as fuck, think about how to clean it up
            .depth_bias_enable = if (descriptor.depth_stencil) |ds|
                @boolToInt(ds.depth_bias != 0 or ds.depth_bias_slope_scale != 0)
            else
                vk.FALSE,
            .depth_bias_constant_factor = if (descriptor.depth_stencil) |ds|
                @intToFloat(f32, ds.depth_bias)
            else
                undefined,
            .depth_bias_clamp = if (descriptor.depth_stencil) |ds|
                ds.depth_bias_clamp
            else
                0.0,
            .depth_bias_slope_factor = if (descriptor.depth_stencil) |ds|
                ds.depth_bias_slope_scale
            else
                undefined,

            .line_width = 1,
        },

        .p_multisample_state = &.{
            .flags = .{},
            .rasterization_samples = multisample_count_vk,
            .sample_shading_enable = vk.FALSE,
            .min_sample_shading = undefined,
            .p_sample_mask = &[1]u32{descriptor.multisample.mask},
            .alpha_to_coverage_enable = @boolToInt(descriptor.multisample.alpha_to_coverage_enabled),
            .alpha_to_one_enable = vk.FALSE,
        },

        .p_depth_stencil_state = if (descriptor.depth_stencil) |ds| &.{
            .flags = .{},
            .depth_test_enable = vk.TRUE,
            .depth_write_enable = @boolToInt(ds.depth_write_enabled),
            .depth_compare_op = helper.vulkanCompareOp(ds.depth_compare),
            .depth_bounds_test_enable = vk.FALSE,
            .stencil_test_enable = @boolToInt(ds.stencil_read_mask != 0 or ds.stencil_write_mask != 0),
            .front = .{
                .fail_op = helper.vulkanStencilOp(ds.stencil_front.fail_op),
                .depth_fail_op = helper.vulkanStencilOp(ds.stencil_front.depth_fail_op),
                .pass_op = helper.vulkanStencilOp(ds.stencil_front.pass_op),
                .compare_op = helper.vulkanCompareOp(ds.stencil_front.compare),
                .compare_mask = ds.stencil_read_mask,
                .write_mask = ds.stencil_write_mask,
                .reference = 0,
            },
            .back = .{
                .fail_op = helper.vulkanStencilOp(ds.stencil_back.fail_op),
                .depth_fail_op = helper.vulkanStencilOp(ds.stencil_back.depth_fail_op),
                .pass_op = helper.vulkanStencilOp(ds.stencil_back.pass_op),
                .compare_op = helper.vulkanCompareOp(ds.stencil_back.compare),
                .compare_mask = ds.stencil_read_mask,
                .write_mask = ds.stencil_write_mask,
                .reference = 0,
            },
            .min_depth_bounds = undefined,
            .max_depth_bounds = undefined,
        } else &.{
            .flags = .{},
            .depth_test_enable = vk.FALSE,
            .depth_write_enable = undefined,
            .depth_compare_op = undefined,
            .depth_bounds_test_enable = vk.FALSE,
            .stencil_test_enable = vk.FALSE,
            .front = undefined,
            .back = undefined,
            .min_depth_bounds = undefined,
            .max_depth_bounds = undefined,
        },

        .p_color_blend_state = &.{
            .flags = .{},
            .logic_op_enable = vk.FALSE,
            .logic_op = undefined,
            .attachment_count = @intCast(u32, blend_attachments.len),
            .p_attachments = blend_attachments.ptr,
            .blend_constants = .{ 0, 0, 0, 0 },
        },

        .p_dynamic_state = &.{
            .flags = .{},
            .dynamic_state_count = vk_dynamic_states.len,
            .p_dynamic_states = &vk_dynamic_states,
        },

        // TODO: auto pipeline layout
        .layout = helper.castOpaque(*internal.PipelineLayout, descriptor.layout.?).layout,
        .render_pass = pass,
        .subpass = 0,

        .base_pipeline_handle = .null_handle,
        .base_pipeline_index = -1,
    }}, null, &pipelines);

    return .{
        .pass = pass,
        .pipeline = pipelines[0],
        .device = device,
    };
}
const vk_dynamic_states = [_]vk.DynamicState{
    .viewport, .scissor, .stencil_reference, .blend_constants,
    // TODO: lots more
};

pub fn deinit(self: *RenderPipeline) void {
    self.device.dispatch.destroyRenderPass(self.device.device, self.pass, null);
    self.device.dispatch.destroyPipeline(self.device.device, self.pipeline, null);
    self.device.allocator().destroy(self);
}
