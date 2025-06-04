const std = @import("std");
const zed = @import("zed");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Memory leak detected!");
    }

    const key_bindings = [_]zed.config.KeyBinding{
        .{ .key = zed.config.Config.ctrlKey('c'), .action = zed.config.Action.quit },
    };
    var config = zed.config.Config{ .key_bindings = &key_bindings };
    var terminal = try zed.terminal.Terminal.init();
    var output = zed.output.Output.init(allocator);
    var input = zed.input.Input.init(&terminal, &output);

    var current_editor = try zed.editor.Editor.init(
        &config,
        &terminal,
        &input,
        &output,
    );

    try current_editor.start();
    while (true) {
        try current_editor.handleInput();
    }
}
