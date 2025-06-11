const std = @import("std");
const zed = @import("../root.zig");

pub fn setEditorMode(
    context: zed.action_handler.ActionHandlerContext,
    mode: zed.EditorMode,
) void {
    context.state.mode = mode;
    context.state.message = mode.toString();
    context.state.message_time = std.time.timestamp();
}
