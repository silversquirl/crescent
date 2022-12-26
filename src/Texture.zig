const std = @import("std");
const gpu = @import("gpu");

const internal = @import("internal.zig");
const helper = @import("helper.zig");
const vk = @import("vk.zig");

const Texture = @This();

manager: helper.Manager(Texture) = .{},
image: vk.Image,
extent: vk.Extent2D,
samples: u32,
device: *internal.Device,

pub fn deinit(self: *Texture) void {
    self.device.dispatch.destroyImage(self.device.device, self.image, null);
    self.device.allocator().destroy(self);
}

pub fn createView(self: *Texture, descriptor: ?*const gpu.TextureView.Descriptor) !*internal.TextureView {
    const view = try self.device.allocator().create(internal.TextureView);
    errdefer self.device.allocator().destroy(view);
    view.* = try internal.TextureView.init(self, descriptor orelse &gpu.TextureView.Descriptor{});
    return view;
}
