//! Implementation of mach-gpu GPUInterface

const std = @import("std");
const gpu = @import("gpu");
const vk = @import("vk.zig");
const internal = @import("internal.zig");

pub fn init() void {
    vk.init() catch |err| {
        std.debug.panic("Failed to initialize Vulkan: {s}", .{@errorName(err)});
    };
}

pub inline fn createInstance(descriptor: ?*const gpu.Instance.Descriptor) ?*gpu.Instance {
    return @ptrCast(
        ?*gpu.Instance,
        internal.Instance.create(descriptor) catch return null,
    );
}

pub inline fn getProcAddress(device: *gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
    _ = device;
    _ = proc_name;
    @panic("TODO: implement getProcAddress");
}

pub inline fn adapterCreateDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor) ?*gpu.Device {
    return @ptrCast(
        ?*gpu.Device,
        castOpaque(*internal.Adapter, adapter).createDevice(descriptor) catch return null,
    );
}

pub inline fn adapterEnumerateFeatures(adapter: *gpu.Adapter, features: ?[*]gpu.FeatureName) usize {
    return castOpaque(*internal.Adapter, adapter).enumerateFeatures(features);
}

pub inline fn adapterGetLimits(adapter: *gpu.Adapter, limits: *gpu.SupportedLimits) bool {
    return castOpaque(*internal.Adapter, adapter).getLimits(limits);
}

pub inline fn adapterGetProperties(adapter: *gpu.Adapter, properties: *gpu.Adapter.Properties) void {
    return castOpaque(*internal.Adapter, adapter).getProperties(properties);
}

pub inline fn adapterHasFeature(adapter: *gpu.Adapter, feature: gpu.FeatureName) bool {
    return castOpaque(*internal.Adapter, adapter).hasFeature(feature);
}

pub inline fn adapterRequestDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor, callback: gpu.RequestDeviceCallback, userdata: ?*anyopaque) void {
    return castOpaque(*internal.Adapter, adapter).requestDevice(descriptor, callback, userdata);
}

pub inline fn adapterReference(adapter: *gpu.Adapter) void {
    castOpaque(*internal.Adapter, adapter).manager.reference();
}

pub inline fn adapterRelease(adapter: *gpu.Adapter) void {
    castOpaque(*internal.Adapter, adapter).manager.release();
}

pub inline fn bindGroupSetLabel(bind_group: *gpu.internal.BindGroup, label: [*:0]const u8) void {
    castOpaque(*internal.BindGroup, bind_group).setLabel(label);
}

pub inline fn bindGroupReference(bind_group: *gpu.internal.BindGroup) void {
    castOpaque(*internal.BindGroup, bind_group).manager.reference();
}

pub inline fn bindGroupRelease(bind_group: *gpu.internal.BindGroup) void {
    castOpaque(*internal.BindGroup, bind_group).manager.release();
}

pub inline fn bindGroupLayoutSetLabel(bind_group_layout: *gpu.BindGroupLayout, label: [*:0]const u8) void {
    castOpaque(*internal.BindGroupLayout, bind_group_layout).layoutSetLabel(label);
}

pub inline fn bindGroupLayoutReference(bind_group_layout: *gpu.BindGroupLayout) void {
    castOpaque(*internal.BindGroupLayout, bind_group_layout).layoutReference();
}

pub inline fn bindGroupLayoutRelease(bind_group_layout: *gpu.BindGroupLayout) void {
    castOpaque(*internal.BindGroupLayout, bind_group_layout).layoutRelease();
}

pub inline fn bufferDestroy(buffer: *gpu.Buffer) void {
    castOpaque(*internal.Buffer, buffer).destroy();
}

// TODO: dawn: return value not marked as nullable in dawn.json but in fact is.
pub inline fn bufferGetConstMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*const anyopaque {
    return castOpaque(*internal.Buffer, buffer).getConstMappedRange(offset, size);
}

// TODO: dawn: return value not marked as nullable in dawn.json but in fact is.
pub inline fn bufferGetMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*anyopaque {
    return castOpaque(*internal.Buffer, buffer).getMappedRange(offset, size);
}

pub inline fn bufferGetSize(buffer: *gpu.Buffer) u64 {
    return castOpaque(*internal.Buffer, buffer).getSize();
}

pub inline fn bufferGetUsage(buffer: *gpu.Buffer) gpu.Buffer.UsageFlags {
    return @bitCast(gpu.Buffer.UsageFlags, castOpaque(*internal.Buffer, buffer).getUsage());
}

pub inline fn bufferMapAsync(buffer: *gpu.Buffer, mode: gpu.MapModeFlags, offset: usize, size: usize, callback: gpu.Buffer.MapCallback, userdata: ?*anyopaque) void {
    castOpaque(*internal.Buffer, buffer).mapAsync(mode, offset, size, callback, userdata);
}

pub inline fn bufferSetLabel(buffer: *gpu.Buffer, label: [*:0]const u8) void {
    castOpaque(*internal.Buffer, buffer).setLabel(label);
}

pub inline fn bufferUnmap(buffer: *gpu.Buffer) void {
    castOpaque(*internal.Buffer, buffer).unmap();
}

pub inline fn bufferReference(buffer: *gpu.Buffer) void {
    castOpaque(*internal.Buffer, buffer).manager.reference();
}

pub inline fn bufferRelease(buffer: *gpu.Buffer) void {
    castOpaque(*internal.Buffer, buffer).manager.release();
}

pub inline fn commandBufferSetLabel(command_buffer: *gpu.CommandBuffer, label: [*:0]const u8) void {
    castOpaque(*internal.CommandBuffer, command_buffer).setLabel(label);
}

pub inline fn commandBufferReference(command_buffer: *gpu.CommandBuffer) void {
    castOpaque(*internal.CommandBuffer, command_buffer).manager.reference();
}

pub inline fn commandBufferRelease(command_buffer: *gpu.CommandBuffer) void {
    castOpaque(*internal.CommandBuffer, command_buffer).manager.release();
}

pub inline fn commandEncoderBeginComputePass(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) *gpu.ComputePassEncoder {
    return @ptrCast(*gpu.ComputePassEncoder, castOpaque(*internal.CommandEncoder, command_encoder).beginComputePass(descriptor));
}

pub inline fn commandEncoderBeginRenderPass(command_encoder: *gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) *gpu.internal.RenderPassEncoder {
    return @ptrCast(*gpu.internal.RenderPassEncoder, castOpaque(*internal.CommandEncoder, command_encoder).beginRenderPass(descriptor));
}

pub inline fn commandEncoderClearBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, offset: u64, size: u64) void {
    castOpaque(*internal.CommandEncoder, command_encoder).clearBuffer(castOpaque(*internal.Buffer, buffer), offset, size);
}

pub inline fn commandEncoderCopyBufferToBuffer(command_encoder: *gpu.CommandEncoder, source: *gpu.Buffer, source_offset: u64, destination: *gpu.Buffer, destination_offset: u64, size: u64) void {
    castOpaque(*internal.CommandEncoder, command_encoder).copyBufferToBuffer(
        castOpaque(*internal.Buffer, source),
        source_offset,
        castOpaque(*internal.Buffer, destination),
        destination_offset,
        size,
    );
}

pub inline fn commandEncoderCopyBufferToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
    castOpaque(*internal.CommandEncoder, command_encoder).copyBufferToTexture(source, destination, copy_size);
}

pub inline fn commandEncoderCopyTextureToBuffer(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) void {
    castOpaque(*internal.CommandEncoder, command_encoder).copyTextureToBuffer(source, destination, copy_size);
}

pub inline fn commandEncoderCopyTextureToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
    castOpaque(*internal.CommandEncoder, command_encoder).copyTextureToTexture(source, destination, copy_size);
}

pub inline fn commandEncoderCopyTextureToTextureInternal(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
    castOpaque(*internal.CommandEncoder, command_encoder).copyTextureToTextureInternal(source, destination, copy_size);
}

pub inline fn commandEncoderFinish(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.CommandBuffer.Descriptor) *gpu.CommandBuffer {
    return @ptrCast(*gpu.CommandBuffer, castOpaque(*internal.CommandEncoder, command_encoder).finish(descriptor));
}

pub inline fn commandEncoderInjectValidationError(command_encoder: *gpu.CommandEncoder, message: [*:0]const u8) void {
    castOpaque(*internal.CommandEncoder, command_encoder).injectValidationError(message);
}

pub inline fn commandEncoderInsertDebugMarker(command_encoder: *gpu.CommandEncoder, marker_label: [*:0]const u8) void {
    castOpaque(*internal.CommandEncoder, command_encoder).insertDebugMarker(marker_label);
}

pub inline fn commandEncoderPopDebugGroup(command_encoder: *gpu.CommandEncoder) void {
    castOpaque(*internal.CommandEncoder, command_encoder).popDebugGroup();
}

pub inline fn commandEncoderPushDebugGroup(command_encoder: *gpu.CommandEncoder, group_label: [*:0]const u8) void {
    castOpaque(*internal.CommandEncoder, command_encoder).pushDebugGroup(group_label);
}

pub inline fn commandEncoderResolveQuerySet(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, first_query: u32, query_count: u32, destination: *gpu.Buffer, destination_offset: u64) void {
    castOpaque(*internal.CommandEncoder, command_encoder).resolveQuerySet(
        castOpaque(*internal.QuerySet, query_set),
        first_query,
        query_count,
        castOpaque(*internal.Buffer, destination),
        destination_offset,
    );
}

pub inline fn commandEncoderSetLabel(command_encoder: *gpu.CommandEncoder, label: [*:0]const u8) void {
    castOpaque(*internal.CommandEncoder, command_encoder).setLabel(label);
}

pub inline fn commandEncoderWriteBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
    castOpaque(*internal.CommandEncoder, command_encoder).writeBuffer(castOpaque(*internal.Buffer, buffer), buffer_offset, data, size);
}

pub inline fn commandEncoderWriteTimestamp(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
    castOpaque(*internal.CommandEncoder, command_encoder).writeTimestamp(castOpaque(*internal.QuerySet, query_set), query_index);
}

pub inline fn commandEncoderReference(command_encoder: *gpu.CommandEncoder) void {
    castOpaque(*internal.CommandEncoder, command_encoder).manager.reference();
}

pub inline fn commandEncoderRelease(command_encoder: *gpu.CommandEncoder) void {
    castOpaque(*internal.CommandEncoder, command_encoder).manager.release();
}

pub inline fn computePassEncoderDispatchWorkgroups(compute_pass_encoder: *gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).dispatchWorkgroups(
        workgroup_count_x,
        workgroup_count_y,
        workgroup_count_z,
    );
}

pub inline fn computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: *gpu.ComputePassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).dispatchWorkgroupsIndirect(castOpaque(*internal.Buffer, indirect_buffer), indirect_offset);
}

pub inline fn computePassEncoderEnd(compute_pass_encoder: *gpu.ComputePassEncoder) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).end();
}

pub inline fn computePassEncoderInsertDebugMarker(compute_pass_encoder: *gpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).insertDebugMarker(marker_label);
}

pub inline fn computePassEncoderPopDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).popDebugGroup();
}

pub inline fn computePassEncoderPushDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_label: [*:0]const u8) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).pushDebugGroup(group_label);
}

pub inline fn computePassEncoderSetBindGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_index: u32, group: *gpu.internal.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).setBindGroup(
        group_index,
        castOpaque(*internal.BindGroup, group),
        dynamic_offset_count,
        dynamic_offsets,
    );
}

pub inline fn computePassEncoderSetLabel(compute_pass_encoder: *gpu.ComputePassEncoder, label: [*:0]const u8) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).setLabel(label);
}

pub inline fn computePassEncoderSetPipeline(compute_pass_encoder: *gpu.ComputePassEncoder, pipeline: *gpu.ComputePipeline) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).setPipeline(castOpaque(*internal.ComputePipeline, pipeline));
}

pub inline fn computePassEncoderWriteTimestamp(compute_pass_encoder: *gpu.ComputePassEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).writeTimestamp(castOpaque(*internal.QuerySet, query_set), query_index);
}

pub inline fn computePassEncoderReference(compute_pass_encoder: *gpu.ComputePassEncoder) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).manager.reference();
}

pub inline fn computePassEncoderRelease(compute_pass_encoder: *gpu.ComputePassEncoder) void {
    castOpaque(*internal.ComputePassEncoder, compute_pass_encoder).manager.release();
}

pub inline fn computePipelineGetBindGroupLayout(compute_pipeline: *gpu.ComputePipeline, group_index: u32) *gpu.BindGroupLayout {
    return @ptrCast(*gpu.BindGroupLayout, castOpaque(*internal.ComputePipeline, compute_pipeline).getBindGroupLayout(group_index));
}

pub inline fn computePipelineSetLabel(compute_pipeline: *gpu.ComputePipeline, label: [*:0]const u8) void {
    castOpaque(*internal.ComputePipeline, compute_pipeline).setLabel(label);
}

pub inline fn computePipelineReference(compute_pipeline: *gpu.ComputePipeline) void {
    castOpaque(*internal.ComputePipeline, compute_pipeline).manager.reference();
}

pub inline fn computePipelineRelease(compute_pipeline: *gpu.ComputePipeline) void {
    castOpaque(*internal.ComputePipeline, compute_pipeline).manager.release();
}

pub inline fn deviceCreateBindGroup(device: *gpu.Device, descriptor: *const gpu.internal.BindGroup.Descriptor) *gpu.internal.BindGroup {
    return @ptrCast(*gpu.internal.BindGroup, castOpaque(*internal.Device, device).createBindGroup(descriptor));
}

pub inline fn deviceCreateBindGroupLayout(device: *gpu.Device, descriptor: *const gpu.BindGroupLayout.Descriptor) *gpu.BindGroupLayout {
    return @ptrCast(*gpu.BindGroupLayout, castOpaque(*internal.Device, device).createBindGroupLayout(descriptor));
}

pub inline fn deviceCreateBuffer(device: *gpu.Device, descriptor: *const gpu.Buffer.Descriptor) *gpu.Buffer {
    return @ptrCast(*gpu.Buffer, castOpaque(*internal.Device, device).createBuffer(descriptor));
}

pub inline fn deviceCreateCommandEncoder(device: *gpu.Device, descriptor: ?*const gpu.CommandEncoder.Descriptor) *gpu.CommandEncoder {
    return @ptrCast(*gpu.CommandEncoder, castOpaque(*internal.Device, device).createCommandEncoder(descriptor));
}

pub inline fn deviceCreateComputePipeline(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor) *gpu.ComputePipeline {
    return @ptrCast(*gpu.ComputePipeline, castOpaque(*internal.Device, device).createComputePipeline(descriptor));
}

pub inline fn deviceCreateComputePipelineAsync(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: ?*anyopaque) void {
    castOpaque(*internal.Device, device).createComputePipelineAsync(descriptor, callback, userdata);
}

pub inline fn deviceCreateErrorBuffer(device: *gpu.Device) *gpu.Buffer {
    return @ptrCast(*gpu.Buffer, castOpaque(*internal.Device, device).createErrorBuffer());
}

pub inline fn deviceCreateErrorExternalTexture(device: *gpu.Device) *gpu.ExternalTexture {
    return @ptrCast(*gpu.ExternalTexture, castOpaque(*internal.Device, device).createErrorExternalTexture());
}

pub inline fn deviceCreateErrorTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
    return @ptrCast(*gpu.Texture, castOpaque(*internal.Device, device).createErrorTexture(descriptor));
}

pub inline fn deviceCreateExternalTexture(device: *gpu.Device, external_texture_descriptor: *const gpu.ExternalTexture.Descriptor) *gpu.ExternalTexture {
    return @ptrCast(*gpu.ExternalTexture, castOpaque(*internal.Device, device).createExternalTexture(external_texture_descriptor));
}

pub inline fn deviceCreatePipelineLayout(device: *gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayout.Descriptor) *gpu.PipelineLayout {
    return @ptrCast(*gpu.PipelineLayout, castOpaque(*internal.Device, device).createPipelineLayout(pipeline_layout_descriptor));
}

pub inline fn deviceCreateQuerySet(device: *gpu.Device, descriptor: *const gpu.QuerySet.Descriptor) *gpu.QuerySet {
    return @ptrCast(*gpu.QuerySet, castOpaque(*internal.Device, device).createQuerySet(descriptor));
}

pub inline fn deviceCreateRenderBundleEncoder(device: *gpu.Device, descriptor: *const gpu.RenderBundleEncoder.Descriptor) *gpu.RenderBundleEncoder {
    return @ptrCast(*gpu.RenderBundleEncoder, castOpaque(*internal.Device, device).createRenderBundleEncoder(descriptor));
}

pub inline fn deviceCreateRenderPipeline(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor) *gpu.RenderPipeline {
    return @ptrCast(*gpu.RenderPipeline, castOpaque(*internal.Device, device).createRenderPipeline(descriptor));
}

pub inline fn deviceCreateRenderPipelineAsync(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: ?*anyopaque) void {
    castOpaque(*internal.Device, device).createRenderPipelineAsync(descriptor, callback, userdata);
}

// TODO(self-hosted): this cannot be marked as inline for some reason.
// https://github.com/ziglang/zig/issues/12545
pub fn deviceCreateSampler(device: *gpu.Device, descriptor: ?*const gpu.Sampler.Descriptor) *gpu.Sampler {
    return @ptrCast(*gpu.Sampler, castOpaque(*internal.Device, device).createSampler(descriptor));
}

pub inline fn deviceCreateShaderModule(device: *gpu.Device, descriptor: *const gpu.ShaderModule.Descriptor) *gpu.ShaderModule {
    return @ptrCast(
        *gpu.ShaderModule,
        castOpaque(*internal.Device, device).createShaderModule(descriptor) catch |err| {
            std.debug.panic("Error creating shader: {s}\n", .{@errorName(err)});
        },
    );
}

pub inline fn deviceCreateSwapChain(device: *gpu.Device, surface: ?*gpu.Surface, descriptor: *const gpu.SwapChain.Descriptor) *gpu.SwapChain {
    return @ptrCast(*gpu.SwapChain, castOpaque(*internal.Device, device).createSwapChain(castOpaque(*internal.Surface, surface), descriptor));
}

pub inline fn deviceCreateTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
    return @ptrCast(*gpu.Texture, castOpaque(*internal.Device, device).createTexture(descriptor));
}

pub inline fn deviceDestroy(device: *gpu.Device) void {
    castOpaque(*internal.Device, device).destroy();
}

pub inline fn deviceEnumerateFeatures(device: *gpu.Device, features: ?[*]gpu.FeatureName) usize {
    return castOpaque(*internal.Device, device).enumerateFeatures(features);
}

pub inline fn deviceGetLimits(device: *gpu.Device, limits: *gpu.SupportedLimits) bool {
    return castOpaque(*internal.Device, device).getLimits(limits);
}

pub inline fn deviceGetQueue(device: *gpu.Device) *gpu.Queue {
    return @ptrCast(*gpu.Queue, castOpaque(*internal.Device, device).getQueue());
}

pub inline fn deviceHasFeature(device: *gpu.Device, feature: gpu.FeatureName) bool {
    return castOpaque(*internal.Device, device).hasFeature(feature);
}

pub inline fn deviceInjectError(device: *gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) void {
    castOpaque(*internal.Device, device).injectError(typ, message);
}

pub inline fn deviceLoseForTesting(device: *gpu.Device) void {
    castOpaque(*internal.Device, device).loseForTesting();
}

pub inline fn devicePopErrorScope(device: *gpu.Device, callback: gpu.ErrorCallback, userdata: ?*anyopaque) bool {
    return castOpaque(*internal.Device, device).popErrorScope(callback, userdata);
}

pub inline fn devicePushErrorScope(device: *gpu.Device, filter: gpu.ErrorFilter) void {
    castOpaque(*internal.Device, device).pushErrorScope(filter);
}

pub inline fn deviceSetDeviceLostCallback(device: *gpu.Device, callback: ?gpu.Device.LostCallback, userdata: ?*anyopaque) void {
    castOpaque(*internal.Device, device).setDeviceLostCallback(callback, userdata);
}

pub inline fn deviceSetLabel(device: *gpu.Device, label: [*:0]const u8) void {
    castOpaque(*internal.Device, device).setLabel(label);
}

pub inline fn deviceSetLoggingCallback(device: *gpu.Device, callback: ?gpu.LoggingCallback, userdata: ?*anyopaque) void {
    castOpaque(*internal.Device, device).setLoggingCallback(callback, userdata);
}

pub inline fn deviceSetUncapturedErrorCallback(device: *gpu.Device, callback: ?gpu.ErrorCallback, userdata: ?*anyopaque) void {
    castOpaque(*internal.Device, device).setUncapturedErrorCallback(callback, userdata);
}

pub inline fn deviceTick(device: *gpu.Device) void {
    castOpaque(*internal.Device, device).tick();
}

pub inline fn deviceReference(device: *gpu.Device) void {
    castOpaque(*internal.Device, device).manager.reference();
}

pub inline fn deviceRelease(device: *gpu.Device) void {
    castOpaque(*internal.Device, device).manager.release();
}

pub inline fn externalTextureDestroy(external_texture: *gpu.ExternalTexture) void {
    castOpaque(*internal.ExternalTexture, external_texture).destroy();
}

pub inline fn externalTextureSetLabel(external_texture: *gpu.ExternalTexture, label: [*:0]const u8) void {
    castOpaque(*internal.ExternalTexture, external_texture).setLabel(label);
}

pub inline fn externalTextureReference(external_texture: *gpu.ExternalTexture) void {
    castOpaque(*internal.ExternalTexture, external_texture).manager.reference();
}

pub inline fn externalTextureRelease(external_texture: *gpu.ExternalTexture) void {
    castOpaque(*internal.ExternalTexture, external_texture).manager.release();
}

pub inline fn instanceCreateSurface(instance: *gpu.Instance, descriptor: *const gpu.Surface.Descriptor) *gpu.Surface {
    return @ptrCast(
        *gpu.Surface,
        castOpaque(*internal.Instance, instance).createSurface(descriptor) catch |err| {
            std.debug.panic("Failed to create surface: {s}\n", .{@errorName(err)});
        },
    );
}

pub inline fn instanceRequestAdapter(instance: *gpu.Instance, options: ?*const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: ?*anyopaque) void {
    castOpaque(*internal.Instance, instance).requestAdapter(options, callback, userdata);
}

pub inline fn instanceReference(instance: *gpu.Instance) void {
    castOpaque(*internal.Instance, instance).manager.reference();
}

pub inline fn instanceRelease(instance: *gpu.Instance) void {
    castOpaque(*internal.Instance, instance).manager.release();
}

pub inline fn pipelineLayoutSetLabel(pipeline_layout: *gpu.PipelineLayout, label: [*:0]const u8) void {
    castOpaque(*internal.PipelineLayout, pipeline_layout).setLabel(label);
}

pub inline fn pipelineLayoutReference(pipeline_layout: *gpu.PipelineLayout) void {
    castOpaque(*internal.PipelineLayout, pipeline_layout).manager.reference();
}

pub inline fn pipelineLayoutRelease(pipeline_layout: *gpu.PipelineLayout) void {
    castOpaque(*internal.PipelineLayout, pipeline_layout).manager.release();
}

pub inline fn querySetDestroy(query_set: *gpu.QuerySet) void {
    castOpaque(*internal.QuerySet, query_set).destroy();
}

pub inline fn querySetGetCount(query_set: *gpu.QuerySet) u32 {
    return castOpaque(*internal.QuerySet, query_set).getCount();
}

pub inline fn querySetGetType(query_set: *gpu.QuerySet) gpu.QueryType {
    return @intToEnum(gpu.QueryType, castOpaque(*internal.QuerySet, query_set).getType());
}

pub inline fn querySetSetLabel(query_set: *gpu.QuerySet, label: [*:0]const u8) void {
    castOpaque(*internal.QuerySet, query_set).setLabel(label);
}

pub inline fn querySetReference(query_set: *gpu.QuerySet) void {
    castOpaque(*internal.QuerySet, query_set).manager.reference();
}

pub inline fn querySetRelease(query_set: *gpu.QuerySet) void {
    castOpaque(*internal.QuerySet, query_set).manager.release();
}

pub inline fn queueCopyTextureForBrowser(queue: *gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
    castOpaque(*internal.Queue, queue).copyTextureForBrowser(source, destination, copy_size, options);
}

pub inline fn queueOnSubmittedWorkDone(queue: *gpu.Queue, signal_value: u64, callback: gpu.Queue.WorkDoneCallback, userdata: ?*anyopaque) void {
    castOpaque(*internal.Queue, queue).onSubmittedWorkDone(signal_value, callback, userdata);
}

pub inline fn queueSetLabel(queue: *gpu.Queue, label: [*:0]const u8) void {
    castOpaque(*internal.Queue, queue).setLabel(label);
}

pub inline fn queueSubmit(queue: *gpu.Queue, command_count: u32, commands: [*]*const gpu.CommandBuffer) void {
    castOpaque(*internal.Queue, queue).submit(command_count, commands);
}

pub inline fn queueWriteBuffer(queue: *gpu.Queue, buffer: *gpu.Buffer, buffer_offset: u64, data: *const anyopaque, size: usize) void {
    castOpaque(*internal.Queue, queue).writeBuffer(castOpaque(*internal.Buffer, buffer), buffer_offset, data, size);
}

pub inline fn queueWriteTexture(queue: *gpu.Queue, destination: *const gpu.ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const gpu.Texture.DataLayout, write_size: *const gpu.Extent3D) void {
    castOpaque(*internal.Queue, queue).writeTexture(destination, data, data_size, data_layout, write_size);
}

pub inline fn queueReference(queue: *gpu.Queue) void {
    castOpaque(*internal.Queue, queue).manager.reference();
}

pub inline fn queueRelease(queue: *gpu.Queue) void {
    castOpaque(*internal.Queue, queue).manager.release();
}

pub inline fn renderBundleReference(render_bundle: *gpu.RenderBundle) void {
    castOpaque(*internal.RenderBundle, render_bundle).manager.reference();
}

pub inline fn renderBundleRelease(render_bundle: *gpu.RenderBundle) void {
    castOpaque(*internal.RenderBundle, render_bundle).manager.release();
}

pub inline fn renderBundleEncoderDraw(render_bundle_encoder: *gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderDraw(vertex_count, instance_count, first_vertex, first_instance);
}

pub inline fn renderBundleEncoderDrawIndexed(render_bundle_encoder: *gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderDrawIndexed(
        index_count,
        instance_count,
        first_index,
        base_vertex,
        first_instance,
    );
}

pub inline fn renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderDrawIndexedIndirect(castOpaque(*internal.Buffer, indirect_buffer), indirect_offset);
}

pub inline fn renderBundleEncoderDrawIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderDrawIndirect(castOpaque(*internal.Buffer, indirect_buffer), indirect_offset);
}

pub inline fn renderBundleEncoderFinish(render_bundle_encoder: *gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundle.Descriptor) *gpu.RenderBundle {
    return @ptrCast(*gpu.RenderBundle, castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderFinish(descriptor));
}

pub inline fn renderBundleEncoderInsertDebugMarker(render_bundle_encoder: *gpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderInsertDebugMarker(marker_label);
}

pub inline fn renderBundleEncoderPopDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderPopDebugGroup();
}

pub inline fn renderBundleEncoderPushDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderPushDebugGroup(group_label);
}

pub inline fn renderBundleEncoderSetBindGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_index: u32, group: *gpu.internal.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderSetBindGroup(
        group_index,
        castOpaque(*internal.BindGroup, group),
        dynamic_offset_count,
        dynamic_offsets,
    );
}

pub inline fn renderBundleEncoderSetIndexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderSetIndexBuffer(castOpaque(*internal.Buffer, buffer), format, offset, size);
}

pub inline fn renderBundleEncoderSetLabel(render_bundle_encoder: *gpu.RenderBundleEncoder, label: [*:0]const u8) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderSetLabel(label);
}

pub inline fn renderBundleEncoderSetPipeline(render_bundle_encoder: *gpu.RenderBundleEncoder, pipeline: *gpu.RenderPipeline) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderSetPipeline(castOpaque(*internal.RenderPipeline, pipeline));
}

pub inline fn renderBundleEncoderSetVertexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderSetVertexBuffer(slot, castOpaque(*internal.Buffer, buffer), offset, size);
}

pub inline fn renderBundleEncoderReference(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderReference();
}

pub inline fn renderBundleEncoderRelease(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
    castOpaque(*internal.RenderBundleEncoder, render_bundle_encoder).encoderRelease();
}

pub inline fn renderPassEncoderBeginOcclusionQuery(render_pass_encoder: *gpu.internal.RenderPassEncoder, query_index: u32) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).beginOcclusionQuery(query_index);
}

pub inline fn renderPassEncoderDraw(render_pass_encoder: *gpu.internal.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).draw(
        vertex_count,
        instance_count,
        first_vertex,
        first_instance,
    );
}

pub inline fn renderPassEncoderDrawIndexed(render_pass_encoder: *gpu.internal.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).drawIndexed(
        index_count,
        instance_count,
        first_index,
        base_vertex,
        first_instance,
    );
}

pub inline fn renderPassEncoderDrawIndexedIndirect(render_pass_encoder: *gpu.internal.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).drawIndexedIndirect(castOpaque(*internal.Buffer, indirect_buffer), indirect_offset);
}

pub inline fn renderPassEncoderDrawIndirect(render_pass_encoder: *gpu.internal.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).drawIndirect(castOpaque(*internal.Buffer, indirect_buffer), indirect_offset);
}

pub inline fn renderPassEncoderEnd(render_pass_encoder: *gpu.internal.RenderPassEncoder) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).end();
}

pub inline fn renderPassEncoderEndOcclusionQuery(render_pass_encoder: *gpu.internal.RenderPassEncoder) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).endOcclusionQuery();
}

pub inline fn renderPassEncoderExecuteBundles(render_pass_encoder: *gpu.internal.RenderPassEncoder, bundles_count: u32, bundles: [*]const *const gpu.RenderBundle) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).executeBundles(bundles_count, bundles);
}

pub inline fn renderPassEncoderInsertDebugMarker(render_pass_encoder: *gpu.internal.RenderPassEncoder, marker_label: [*:0]const u8) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).insertDebugMarker(marker_label);
}

pub inline fn renderPassEncoderPopDebugGroup(render_pass_encoder: *gpu.internal.RenderPassEncoder) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).popDebugGroup();
}

pub inline fn renderPassEncoderPushDebugGroup(render_pass_encoder: *gpu.internal.RenderPassEncoder, group_label: [*:0]const u8) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).pushDebugGroup(group_label);
}

pub inline fn renderPassEncoderSetBindGroup(render_pass_encoder: *gpu.internal.RenderPassEncoder, group_index: u32, group: *gpu.internal.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).setBindGroup(
        group_index,
        castOpaque(*internal.BindGroup, group),
        dynamic_offset_count,
        dynamic_offsets,
    );
}

pub inline fn renderPassEncoderSetBlendConstant(render_pass_encoder: *gpu.internal.RenderPassEncoder, color: *const gpu.Color) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).setBlendConstant(color);
}

pub inline fn renderPassEncoderSetIndexBuffer(render_pass_encoder: *gpu.internal.RenderPassEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).setIndexBuffer(castOpaque(*internal.Buffer, buffer), format, offset, size);
}

pub inline fn renderPassEncoderSetLabel(render_pass_encoder: *gpu.internal.RenderPassEncoder, label: [*:0]const u8) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).setLabel(label);
}

pub inline fn renderPassEncoderSetPipeline(render_pass_encoder: *gpu.internal.RenderPassEncoder, pipeline: *gpu.RenderPipeline) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).setPipeline(castOpaque(*internal.RenderPipeline, pipeline));
}

pub inline fn renderPassEncoderSetScissorRect(render_pass_encoder: *gpu.internal.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).setScissorRect(x, y, width, height);
}

pub inline fn renderPassEncoderSetStencilReference(render_pass_encoder: *gpu.internal.RenderPassEncoder, reference: u32) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).setStencilReference(reference);
}

pub inline fn renderPassEncoderSetVertexBuffer(render_pass_encoder: *gpu.internal.RenderPassEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).setVertexBuffer(slot, castOpaque(*internal.Buffer, buffer), offset, size);
}

pub inline fn renderPassEncoderSetViewport(render_pass_encoder: *gpu.internal.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).setViewport(x, y, width, height, min_depth, max_depth);
}

pub inline fn renderPassEncoderWriteTimestamp(render_pass_encoder: *gpu.internal.RenderPassEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).writeTimestamp(castOpaque(*internal.QuerySet, query_set), query_index);
}

pub inline fn renderPassEncoderReference(render_pass_encoder: *gpu.internal.RenderPassEncoder) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).manager.reference();
}

pub inline fn renderPassEncoderRelease(render_pass_encoder: *gpu.internal.RenderPassEncoder) void {
    castOpaque(*internal.RenderPassEncoder, render_pass_encoder).manager.release();
}

pub inline fn renderPipelineGetBindGroupLayout(render_pipeline: *gpu.RenderPipeline, group_index: u32) *gpu.BindGroupLayout {
    return @ptrCast(*gpu.BindGroupLayout, castOpaque(*internal.RenderPipeline, render_pipeline).getBindGroupLayout(group_index));
}

pub inline fn renderPipelineSetLabel(render_pipeline: *gpu.RenderPipeline, label: [*:0]const u8) void {
    castOpaque(*internal.RenderPipeline, render_pipeline).setLabel(label);
}

pub inline fn renderPipelineReference(render_pipeline: *gpu.RenderPipeline) void {
    castOpaque(*internal.RenderPipeline, render_pipeline).manager.reference();
}

pub inline fn renderPipelineRelease(render_pipeline: *gpu.RenderPipeline) void {
    castOpaque(*internal.RenderPipeline, render_pipeline).manager.release();
}

pub inline fn samplerSetLabel(sampler: *gpu.Sampler, label: [*:0]const u8) void {
    castOpaque(*internal.Sampler, sampler).setLabel(label);
}

pub inline fn samplerReference(sampler: *gpu.Sampler) void {
    castOpaque(*internal.Sampler, sampler).manager.reference();
}

pub inline fn samplerRelease(sampler: *gpu.Sampler) void {
    castOpaque(*internal.Sampler, sampler).manager.release();
}

pub inline fn shaderModuleGetCompilationInfo(shader_module: *gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: ?*anyopaque) void {
    castOpaque(*internal.ShaderModule, shader_module).getCompilationInfo(callback, userdata);
}

pub inline fn shaderModuleSetLabel(shader_module: *gpu.ShaderModule, label: [*:0]const u8) void {
    castOpaque(*internal.ShaderModule, shader_module).setLabel(label);
}

pub inline fn shaderModuleReference(shader_module: *gpu.ShaderModule) void {
    castOpaque(*internal.ShaderModule, shader_module).manager.reference();
}

pub inline fn shaderModuleRelease(shader_module: *gpu.ShaderModule) void {
    castOpaque(*internal.ShaderModule, shader_module).manager.release();
}

pub inline fn surfaceReference(surface: *gpu.Surface) void {
    castOpaque(*internal.Surface, surface).manager.reference();
}

pub inline fn surfaceRelease(surface: *gpu.Surface) void {
    castOpaque(*internal.Surface, surface).manager.release();
}

pub inline fn swapChainConfigure(swap_chain: *gpu.SwapChain, format: gpu.Texture.Format, allowed_usage: gpu.Texture.UsageFlags, width: u32, height: u32) void {
    castOpaque(*internal.SwapChain, swap_chain).configure(format, allowed_usage, width, height);
}

pub inline fn swapChainGetCurrentTextureView(swap_chain: *gpu.SwapChain) *gpu.TextureView {
    return @ptrCast(*gpu.TextureView, castOpaque(*internal.SwapChain, swap_chain).getCurrentTextureView());
}

pub inline fn swapChainPresent(swap_chain: *gpu.SwapChain) void {
    castOpaque(*internal.SwapChain, swap_chain).present();
}

pub inline fn swapChainReference(swap_chain: *gpu.SwapChain) void {
    castOpaque(*internal.SwapChain, swap_chain).manager.reference();
}

pub inline fn swapChainRelease(swap_chain: *gpu.SwapChain) void {
    castOpaque(*internal.SwapChain, swap_chain).manager.release();
}

pub inline fn textureCreateView(texture: *gpu.Texture, descriptor: ?*const gpu.TextureView.Descriptor) *gpu.TextureView {
    return @ptrCast(*gpu.TextureView, castOpaque(*internal.Texture, texture).createView(descriptor));
}

pub inline fn textureDestroy(texture: *gpu.Texture) void {
    castOpaque(*internal.Texture, texture).destroy();
}

pub inline fn textureGetDepthOrArrayLayers(texture: *gpu.Texture) u32 {
    return castOpaque(*internal.Texture, texture).getDepthOrArrayLayers();
}

pub inline fn textureGetDimension(texture: *gpu.Texture) gpu.Texture.Dimension {
    return @intToEnum(gpu.Texture.Dimension, castOpaque(*internal.Texture, texture).getDimension());
}

pub inline fn textureGetFormat(texture: *gpu.Texture) gpu.Texture.Format {
    return @intToEnum(gpu.Texture.Format, castOpaque(*internal.Texture, texture).getFormat());
}

pub inline fn textureGetHeight(texture: *gpu.Texture) u32 {
    return castOpaque(*internal.Texture, texture).getHeight();
}

pub inline fn textureGetMipLevelCount(texture: *gpu.Texture) u32 {
    return castOpaque(*internal.Texture, texture).getMipLevelCount();
}

pub inline fn textureGetSampleCount(texture: *gpu.Texture) u32 {
    return castOpaque(*internal.Texture, texture).getSampleCount();
}

pub inline fn textureGetUsage(texture: *gpu.Texture) gpu.Texture.UsageFlags {
    return @bitCast(gpu.Texture.UsageFlags, castOpaque(*internal.Texture, texture).getUsage());
}

pub inline fn textureGetWidth(texture: *gpu.Texture) u32 {
    return castOpaque(*internal.Texture, texture).getWidth();
}

pub inline fn textureSetLabel(texture: *gpu.Texture, label: [*:0]const u8) void {
    castOpaque(*internal.Texture, texture).setLabel(label);
}

pub inline fn textureReference(texture: *gpu.Texture) void {
    castOpaque(*internal.Texture, texture).manager.reference();
}

pub inline fn textureRelease(texture: *gpu.Texture) void {
    castOpaque(*internal.Texture, texture).manager.release();
}

pub inline fn textureViewSetLabel(texture_view: *gpu.TextureView, label: [*:0]const u8) void {
    castOpaque(*internal.TextureView, texture_view).setLabel(label);
}

pub inline fn textureViewReference(texture_view: *gpu.TextureView) void {
    castOpaque(*internal.TextureView, texture_view).manager.reference();
}

pub inline fn textureViewRelease(texture_view: *gpu.TextureView) void {
    castOpaque(*internal.TextureView, texture_view).manager.release();
}

fn castOpaque(comptime T: type, ptr: anytype) T {
    comptime {
        std.debug.assert(std.meta.trait.is(.Opaque)(std.meta.Child(@TypeOf(ptr))));
    }
    const alignment = @alignOf(std.meta.Child(T));
    const aligned = @alignCast(alignment, ptr);
    return @ptrCast(T, aligned);
}
