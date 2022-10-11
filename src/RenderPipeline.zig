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

    // TODO: Snektron/vulkan-zig#27
    const multisample_count_vk: vk.SampleCountFlags = switch (descriptor.multisample.count) {
        1 => .{ .@"1_bit" = true },
        2 => .{ .@"2_bit" = true },
        4 => .{ .@"4_bit" = true },
        8 => .{ .@"8_bit" = true },
        16 => .{ .@"16_bit" = true },
        32 => .{ .@"32_bit" = true },
        else => unreachable,
    };

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
                .format = vulkanTextureFormat(frag.targets.?[i].format),
                .samples = multisample_count_vk,
                .load_op = .load,
                .store_op = .store,
                .stencil_load_op = .dont_care,
                .stencil_store_op = .dont_care,
                .initial_layout = .general,
                .final_layout = .general,
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
                .src_color_blend_factor = vulkanBlendFactor(blend.color.src_factor),
                .dst_color_blend_factor = vulkanBlendFactor(blend.color.dst_factor),
                .color_blend_op = vulkanBlendOp(blend.color.operation),
                .src_alpha_blend_factor = vulkanBlendFactor(blend.alpha.src_factor),
                .dst_alpha_blend_factor = vulkanBlendFactor(blend.alpha.dst_factor),
                .alpha_blend_op = vulkanBlendOp(blend.alpha.operation),
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
                .format = vulkanVertexFormat(attr.format),
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
            .depth_compare_op = vulkanCompareOp(ds.depth_compare),
            .depth_bounds_test_enable = vk.FALSE,
            .stencil_test_enable = @boolToInt(ds.stencil_read_mask != 0 or ds.stencil_write_mask != 0),
            .front = .{
                .fail_op = vulkanStencilOp(ds.stencil_front.fail_op),
                .depth_fail_op = vulkanStencilOp(ds.stencil_front.depth_fail_op),
                .pass_op = vulkanStencilOp(ds.stencil_front.pass_op),
                .compare_op = vulkanCompareOp(ds.stencil_front.compare),
                .compare_mask = ds.stencil_read_mask,
                .write_mask = ds.stencil_write_mask,
                .reference = 0,
            },
            .back = .{
                .fail_op = vulkanStencilOp(ds.stencil_back.fail_op),
                .depth_fail_op = vulkanStencilOp(ds.stencil_back.depth_fail_op),
                .pass_op = vulkanStencilOp(ds.stencil_back.pass_op),
                .compare_op = vulkanCompareOp(ds.stencil_back.compare),
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

fn vulkanTextureFormat(fmt: gpu.Texture.Format) vk.Format {
    return switch (fmt) {
        .undef => .undefined,
        .r8_unorm => .r8_unorm,
        .r8_snorm => .r8_snorm,
        .r8_uint => .r8_uint,
        .r8_sint => .r8_sint,
        .r16_uint => .r16_uint,
        .r16_sint => .r16_sint,
        .r16_float => .r16_sfloat,
        .rg8_unorm => .r8g8_unorm,
        .rg8_snorm => .r8g8_snorm,
        .rg8_uint => .r8g8_uint,
        .rg8_sint => .r8g8_sint,
        .r32_float => .r32_sfloat,
        .r32_uint => .r32_uint,
        .r32_sint => .r32_sint,
        .rg16_uint => .r16g16_uint,
        .rg16_sint => .r16g16_sint,
        .rg16_float => .r16g16_sfloat,
        .rgba8_unorm => .r8g8b8a8_unorm,
        .rgba8_unorm_srgb => .r8g8b8a8_srgb,
        .rgba8_snorm => .r8g8b8a8_snorm,
        .rgba8_uint => .r8g8b8a8_uint,
        .rgba8_sint => .r8g8b8a8_sint,
        .bgra8_unorm => .b8g8r8a8_unorm,
        .bgra8_unorm_srgb => .b8g8r8a8_srgb,
        .rgb10_a2_unorm => .a2r10g10b10_unorm_pack32,
        .rg11_b10_ufloat => .b10g11r11_ufloat_pack32,
        .rgb9_e5_ufloat => .e5b9g9r9_ufloat_pack32,
        .rg32_float => .r32g32_sfloat,
        .rg32_uint => .r32g32_uint,
        .rg32_sint => .r32g32_sint,
        .rgba16_uint => .r16g16b16a16_uint,
        .rgba16_sint => .r16g16b16a16_sint,
        .rgba16_float => .r16g16b16a16_sfloat,
        .rgba32_float => .r32g32b32a32_sfloat,
        .rgba32_uint => .r32g32b32a32_uint,
        .rgba32_sint => .r32g32b32a32_sint,
        .stencil8 => .s8_uint,
        .depth16_unorm => .d16_unorm,
        .depth24_plus => .x8_d24_unorm_pack32,
        .depth24_plus_stencil8 => .d24_unorm_s8_uint,
        .depth32_float => .d32_sfloat,
        .depth32_float_stencil8 => .d32_sfloat_s8_uint,
        .bc1_rgba_unorm => .bc1_rgba_unorm_block,
        .bc1_rgba_unorm_srgb => .bc1_rgba_srgb_block,
        .bc2_rgba_unorm => .bc2_unorm_block,
        .bc2_rgba_unorm_srgb => .bc2_srgb_block,
        .bc3_rgba_unorm => .bc3_unorm_block,
        .bc3_rgba_unorm_srgb => .bc3_srgb_block,
        .bc4_runorm => .bc4_unorm_block,
        .bc4_rsnorm => .bc4_snorm_block,
        .bc5_rg_unorm => .bc5_unorm_block,
        .bc5_rg_snorm => .bc5_snorm_block,
        .bc6_hrgb_ufloat => .bc6h_ufloat_block,
        .bc6_hrgb_float => .bc6h_sfloat_block,
        .bc7_rgba_unorm => .bc7_unorm_block,
        .bc7_rgba_unorm_srgb => .bc7_srgb_block,
        .etc2_rgb8_unorm => .etc2_r8g8b8_unorm_block,
        .etc2_rgb8_unorm_srgb => .etc2_r8g8b8_srgb_block,
        .etc2_rgb8_a1_unorm => .etc2_r8g8b8a1_unorm_block,
        .etc2_rgb8_a1_unorm_srgb => .etc2_r8g8b8a1_srgb_block,
        .etc2_rgba8_unorm => .etc2_r8g8b8a8_unorm_block,
        .etc2_rgba8_unorm_srgb => .etc2_r8g8b8a8_srgb_block,
        .eacr11_unorm => .eac_r11_unorm_block,
        .eacr11_snorm => .eac_r11_snorm_block,
        .eacrg11_unorm => .eac_r11g11_unorm_block,
        .eacrg11_snorm => .eac_r11g11_snorm_block,
        .astc4x4_unorm => .astc_4x_4_unorm_block,
        .astc4x4_unorm_srgb => .astc_4x_4_srgb_block,
        .astc5x4_unorm => .astc_5x_4_unorm_block,
        .astc5x4_unorm_srgb => .astc_5x_4_srgb_block,
        .astc5x5_unorm => .astc_5x_5_unorm_block,
        .astc5x5_unorm_srgb => .astc_5x_5_srgb_block,
        .astc6x5_unorm => .astc_6x_5_unorm_block,
        .astc6x5_unorm_srgb => .astc_6x_5_srgb_block,
        .astc6x6_unorm => .astc_6x_6_unorm_block,
        .astc6x6_unorm_srgb => .astc_6x_6_srgb_block,
        .astc8x5_unorm => .astc_8x_5_unorm_block,
        .astc8x5_unorm_srgb => .astc_8x_5_srgb_block,
        .astc8x6_unorm => .astc_8x_6_unorm_block,
        .astc8x6_unorm_srgb => .astc_8x_6_srgb_block,
        .astc8x8_unorm => .astc_8x_8_unorm_block,
        .astc8x8_unorm_srgb => .astc_8x_8_srgb_block,
        .astc10x5_unorm => .astc_1_0x_5_unorm_block,
        .astc10x5_unorm_srgb => .astc_1_0x_5_srgb_block,
        .astc10x6_unorm => .astc_1_0x_6_unorm_block,
        .astc10x6_unorm_srgb => .astc_1_0x_6_srgb_block,
        .astc10x8_unorm => .astc_1_0x_8_unorm_block,
        .astc10x8_unorm_srgb => .astc_1_0x_8_srgb_block,
        .astc10x10_unorm => .astc_1_0x_10_unorm_block,
        .astc10x10_unorm_srgb => .astc_1_0x_10_srgb_block,
        .astc12x10_unorm => .astc_1_2x_10_unorm_block,
        .astc12x10_unorm_srgb => .astc_1_2x_10_srgb_block,
        .astc12x12_unorm => .astc_1_2x_12_unorm_block,
        .astc12x12_unorm_srgb => .astc_1_2x_12_srgb_block,
        .r8_bg8_biplanar420_unorm => .g8_b8r8_2plane_420_unorm,
    };
}

fn vulkanVertexFormat(format: gpu.VertexFormat) vk.Format {
    return switch (format) {
        .undef => .undefined,

        .uint8x2 => .r8g8_uint,
        .uint8x4 => .r8g8b8a8_uint,
        .sint8x2 => .r8g8_sint,
        .sint8x4 => .r8g8b8a8_sint,
        .unorm8x2 => .r8g8_unorm,
        .unorm8x4 => .r8g8b8a8_unorm,
        .snorm8x2 => .r8g8_snorm,
        .snorm8x4 => .r8g8b8a8_snorm,

        .uint16x2 => .r16g16_uint,
        .uint16x4 => .r16g16b16a16_uint,
        .sint16x2 => .r16g16_sint,
        .sint16x4 => .r16g16b16a16_sint,
        .unorm16x2 => .r16g16_unorm,
        .unorm16x4 => .r16g16b16a16_unorm,
        .snorm16x2 => .r16g16_snorm,
        .snorm16x4 => .r16g16b16a16_snorm,

        .float16x2 => .r16g16_sfloat,
        .float16x4 => .r16g16b16a16_sfloat,

        .float32 => .r16_sfloat,
        .float32x2 => .r16g16_sfloat,
        .float32x3 => .r16g16b16_sfloat,
        .float32x4 => .r16g16b16a16_sfloat,

        .uint32 => .r32_uint,
        .uint32x2 => .r32g32_uint,
        .uint32x3 => .r32g32b32_uint,
        .uint32x4 => .r32g32b32a32_uint,
        .sint32 => .r32_sint,
        .sint32x2 => .r32g32_sint,
        .sint32x3 => .r32g32b32_sint,
        .sint32x4 => .r32g32b32a32_sint,
    };
}

fn vulkanCompareOp(op: gpu.CompareFunction) vk.CompareOp {
    return switch (op) {
        .undef => unreachable,
        .never => vk.CompareOp.never,
        .less => .less,
        .less_equal => .less_or_equal,
        .greater => .greater,
        .greater_equal => .greater_or_equal,
        .equal => .equal,
        .not_equal => .not_equal,
        .always => .always,
    };
}

fn vulkanStencilOp(op: gpu.StencilOperation) vk.StencilOp {
    return switch (op) {
        .keep => .keep,
        .zero => .zero,
        .replace => .replace,
        .invert => .invert,
        .increment_clamp => .increment_and_clamp,
        .decrement_clamp => .decrement_and_clamp,
        .increment_wrap => .increment_and_wrap,
        .decrement_wrap => .decrement_and_wrap,
    };
}

fn vulkanBlendFactor(fac: gpu.BlendFactor) vk.BlendFactor {
    return switch (fac) {
        .zero => .zero,
        .one => .one,
        .src => .src_color,
        .one_minus_src => .one_minus_src_color,
        .src_alpha => .src_alpha,
        .one_minus_src_alpha => .one_minus_src_alpha,
        .dst => .dst_color,
        .one_minus_dst => .one_minus_dst_color,
        .dst_alpha => .dst_alpha,
        .one_minus_dst_alpha => .one_minus_dst_alpha,
        .src_alpha_saturated => .src_alpha_saturate,
        .constant => .constant_color,
        .one_minus_constant => .one_minus_constant_color,
    };
}
fn vulkanBlendOp(op: gpu.BlendOperation) vk.BlendOp {
    return switch (op) {
        .add => .add,
        .subtract => .subtract,
        .reverse_subtract => .reverse_subtract,
        .min => .min,
        .max => .max,
    };
}

pub fn deinit(self: *RenderPipeline) void {
    self.device.dispatch.destroyRenderPass(self.device.device, self.pass, null);
    self.device.dispatch.destroyPipeline(self.device.device, self.pipeline, null);
    self.device.allocator().destroy(self);
}
