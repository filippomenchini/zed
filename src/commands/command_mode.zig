const std = @import("std");
const zed = @import("../root.zig");
const modals = @import("modals.zig");

const Command = enum {
    unknown,
    write,
    quit,
};

pub fn appendToCommandBuffer(
    context: zed.ActionHandlerContext,
    action: zed.Action,
) !void {
    try context.state.command_buffer.append(action.commandInsert);
}

pub fn removeFromCommandBuffer(context: zed.ActionHandlerContext) !void {
    _ = context.state.command_buffer.pop();
}

pub fn runCommand(context: zed.ActionHandlerContext) !void {
    const command = parseCommand(context.state.command_buffer.items);
    context.state.command_buffer.clearRetainingCapacity();
    modals.setEditorMode(context, .normal);

    return processCommand(context, command);
}

fn parseCommand(input: []u8) Command {
    const trimmed = std.mem.trim(u8, input, " \t\n\r");
    if (trimmed.len == 0) return Command.unknown;

    var parts = std.mem.splitScalar(u8, trimmed, ' ');
    const cmd = parts.next() orelse return Command.unknown;

    const command = if (std.mem.eql(u8, cmd, "q"))
        Command.quit
    else if (std.mem.eql(u8, cmd, "w"))
        Command.write
    else
        Command.unknown;

    return command;
}

fn processCommand(context: zed.ActionHandlerContext, command: Command) !void {
    return switch (command) {
        .unknown => context.state.setMessage("Unknown command!"),
        .write => try saveFile(context),
        .quit => {
            try context.output.clearScreen();
            try context.terminal.disableRawMode();
            std.posix.exit(0);
        },
    };
}

pub fn saveFile(context: zed.ActionHandlerContext) !void {
    if (context.state.filename.len == 0) {
        context.state.setMessage("No filename");
        return;
    }

    const file = std.fs.cwd().createFile(context.state.filename, .{}) catch {
        context.state.setMessage("Cannot save file");
        return;
    };
    defer file.close();

    for (context.state.rows.items, 0..) |row, i| {
        _ = file.write(row) catch {
            context.state.setMessage("Write error");
            return;
        };

        if (i < context.state.rows.items.len - 1) {
            _ = file.write("\n") catch {
                context.state.setMessage("Write error");
                return;
            };
        }
    }

    context.state.setMessage("File saved");
}
