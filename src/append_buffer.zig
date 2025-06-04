const std = @import("std");

pub const AppendBuffer = struct {
    buffer: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) AppendBuffer {
        return .{
            .buffer = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *AppendBuffer) void {
        self.buffer.deinit();
    }

    pub fn append(self: *AppendBuffer, data: []const u8) !void {
        try self.buffer.appendSlice(data);
    }

    pub fn flush(self: *AppendBuffer) !void {
        _ = try std.posix.write(std.posix.STDOUT_FILENO, self.buffer.items);
        self.buffer.clearRetainingCapacity();
    }
};
