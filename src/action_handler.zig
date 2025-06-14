const std = @import("std");
const zed = @import("root.zig");
const movement = @import("commands/movement.zig");
const modals = @import("commands/modals.zig");

pub const ActionHandlerContext = struct {
    state: *zed.editor_state.EditorState,
    terminal: *zed.terminal.Terminal,
    output: *zed.output.Output,
};

pub const ActionHandler = struct {
    pub fn execute(
        _: *ActionHandler,
        context: ActionHandlerContext,
        action: zed.action.Action,
    ) !void {
        switch (action) {
            .quit => try quit(context),

            // Movement
            .moveCursorUp => try movement.moveVertically(context, .up),
            .moveCursorDown => try movement.moveVertically(context, .down),
            .moveCursorLeft => try movement.moveHorizontally(context, .left),
            .moveCursorRight => try movement.moveHorizontally(context, .right),

            // Modals
            .setInsertMode => modals.setEditorMode(context, .insert),
            .setNormalMode => modals.setEditorMode(context, .normal),
            .setCommandMode => modals.setEditorMode(context, .command),
        }
    }

    fn quit(context: ActionHandlerContext) !void {
        try context.output.clearScreen();
        try context.terminal.disableRawMode();
        std.posix.exit(0);
    }
};
