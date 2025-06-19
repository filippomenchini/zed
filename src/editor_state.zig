const std = @import("std");

pub const EditorMode = enum {
    normal,
    insert,
    command,

    pub fn toString(self: *const EditorMode) []const u8 {
        return switch (self.*) {
            EditorMode.normal => "-- NORMAL --",
            EditorMode.insert => "-- INSERT --",
            EditorMode.command => "-- COMMAND --",
        };
    }
};

pub const EditorState = struct {
    allocator: std.mem.Allocator,
    rows: std.ArrayList([]const u8),
    filename: []const u8,
    row_index: usize,
    col_index: usize,
    preferred_col_index: ?usize,
    message: []const u8,
    message_time: i64,
    mode: EditorMode,
    command_buffer: std.ArrayList(u8),

    pub fn init(
        allocator: std.mem.Allocator,
        filename: []const u8,
    ) EditorState {
        return .{
            .allocator = allocator,
            .rows = std.ArrayList([]const u8).init(allocator),
            .filename = filename,
            .row_index = 0,
            .col_index = 0,
            .preferred_col_index = null,
            .message = "Welcome to ZED! - Type ':q' to quit.",
            .message_time = std.time.timestamp(),
            .mode = .normal,
            .command_buffer = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *EditorState) void {
        for (self.rows.items) |row| {
            self.allocator.free(row);
        }
        self.rows.deinit();
        self.allocator.free(self.filename);
        self.command_buffer.deinit();
    }

    pub fn loadFile(self: *EditorState, filename: []const u8) !void {
        const content = std.fs.cwd().readFileAlloc(self.allocator, filename, std.math.maxInt(usize)) catch {
            self.filename = try self.allocator.dupe(u8, filename);
            return;
        };
        defer self.allocator.free(content);

        var lines = std.mem.splitSequence(u8, content, "\n");
        while (lines.next()) |line| {
            const owned_line = try self.allocator.dupe(u8, line);
            try self.rows.append(owned_line);
        }

        self.filename = try self.allocator.dupe(u8, filename);
    }

    pub fn setMessage(self: *EditorState, message: []const u8) void {
        self.message = message;
        self.message_time = std.time.timestamp();
    }
};
