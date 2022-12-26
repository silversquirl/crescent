# Crescent

Crescent is a simple WebGPU implementation written in Zig.
It is designed to be used with [`mach/gpu`][gpu], a WebGPU API wrapper for Zig.

For simplicity, Crescent has only one backend: Vulkan.
This is unusual, as most WebGPU implementations support other backends, such as DirectX, Metal and sometimes OpenGL.
Crescent prefers to focus on optimizations for one backend, improving speed and keeping the implementation smaller and simpler.

[gpu]: https://github.com/hexops/mach-gpu

## Status: under construction

Crescent doesn't yet implement the full WebGPU API, however it can already run a [simple triangle example][example]!

[example]: https://github.com/silversquirl/crescent-example

## Security

Crescent does **not** provide any security guarantees and is **not** suitable for sandboxed environments, such as web browsers.
While most WebGPU implementations are designed for browsers and hence have a heavy focus on security, Crescent optimizes for speed and code size instead, resulting in a much smaller implementation suitable for use by trusted code in native applications.
