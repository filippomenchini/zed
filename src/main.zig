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

    var current_editor = try zed.editor.Editor.init(allocator, &key_bindings);

    try current_editor.start();
    while (true) {
        try current_editor.handleInput();
    }
}
