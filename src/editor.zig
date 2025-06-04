const std = @import("std");
const zed = @import("root.zig");
const mem = std.mem;

pub const Editor = struct {
    allocator: mem.Allocator,
    config: zed.config.Config,
    terminal: zed.terminal.Terminal,
    input: zed.input.Input,
    output: zed.output.Output,

    pub fn init(
        allocator: mem.Allocator,
        key_bindings: []const zed.config.KeyBinding,
    ) !Editor {
        const config = zed.config.Config{ .key_bindings = key_bindings };
        const terminal = try zed.terminal.Terminal.init();
        const input = zed.input.Input.init(&terminal);
        const output = zed.output.Output.init(allocator, zed.append_buffer.AppendBuffer.init(allocator));

        return Editor{
            .allocator = allocator,
            .config = config,
            .terminal = terminal,
            .input = input,
            .output = output,
        };
    }

    pub fn start(self: *Editor) !void {
        try self.terminal.enableRawMode();
        try self.output.refreshScreen();
    }

    pub fn handleInput(self: *Editor) !void {
        try self.input.processKeypress(&self.config);
    }
};
