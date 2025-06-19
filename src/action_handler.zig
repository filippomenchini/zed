const std = @import("std");
const zed = @import("root.zig");
const movement = @import("commands/movement.zig");
const modals = @import("commands/modals.zig");
const command_mode = @import("commands/command_mode.zig");
const editing = @import("commands/editing.zig");

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

            // Movement
            .moveCursorUp => try movement.moveVertically(context, .up),
            .moveCursorDown => try movement.moveVertically(context, .down),
            .moveCursorLeft => try movement.moveHorizontally(context, .left),
            .moveCursorRight => try movement.moveHorizontally(context, .right),

            // Modals
            .setInsertMode => modals.setEditorMode(context, .insert),
            .setNormalMode => modals.setEditorMode(context, .normal),
            .setCommandMode => modals.setEditorMode(context, .command),

            // Command mode
            .commandCancel => modals.setEditorMode(context, .normal),
            .commandRun => try command_mode.runCommand(context),
            .commandInsert => try command_mode.appendToCommandBuffer(context, action),
            .commandDelete => try command_mode.removeFromCommandBuffer(context),

            // Insert mode
            .insertCancel => modals.setEditorMode(context, .normal),
            .insertDelete => try editing.insertBackspace(context),
            .insertNewline => try editing.insertNewline(context),
            .insertWrite => try editing.insertCharacter(context, action.insertWrite),
        }
    }
};
