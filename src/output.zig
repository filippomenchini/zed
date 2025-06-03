const std = @import("std");
const posix = std.posix;

/// Error types for terminal output operations
pub const OutputError = error{
    /// Failed to send escape sequence to terminal
    /// This can happen if stdout is redirected, the terminal is disconnected,
    /// or there are system-level I/O issues
    SendEscapeSequenceError,
};

/// VT100/ANSI escape sequences for terminal control
///
/// This enum contains escape sequences that are part of the VT100 standard,
/// which was established by Digital Equipment Corporation (DEC) in 1978.
/// These sequences have become the de facto standard for terminal control
/// and are supported by virtually all modern terminal emulators.
///
/// VT100 compatibility ensures that your editor will work across:
/// - All major terminal emulators (xterm, gnome-terminal, iTerm2, etc.)
/// - SSH sessions to remote servers
/// - Different operating systems (Linux, macOS, Windows with modern terminals)
/// - Terminal multiplexers (tmux, screen)
///
/// Escape sequence format:
/// All sequences start with ESC (0x1B or \x1b) followed by '[' and parameters.
/// This is called "CSI" (Control Sequence Introducer) format.
///
/// The sequences used here are among the most basic and universally supported:
/// - Clear screen: Part of the original VT100 specification
/// - Cursor positioning: Essential for any screen-oriented application
///
/// Historical note:
/// VT100 was revolutionary because it introduced standardized escape sequences
/// that allowed software to control cursor movement and screen clearing without
/// knowing the specific terminal hardware. Before this, each terminal brand
/// had its own incompatible control codes.
const EscapeSequence = enum {
    /// Clear the entire screen buffer
    ///
    /// This sequence clears all text from the terminal screen but does not
    /// move the cursor. The screen will be blank after this operation.
    ///
    /// Technical details:
    /// - \x1b[2J breaks down as:
    ///   - \x1b = ESC character (27 in decimal)
    ///   - [ = Start of CSI sequence
    ///   - 2 = Parameter meaning "entire screen"
    ///   - J = "Erase in Display" command
    ///
    /// Alternative parameters for J command:
    /// - 0J or J = Clear from cursor to end of screen
    /// - 1J = Clear from beginning of screen to cursor
    /// - 2J = Clear entire screen (what we use)
    /// - 3J = Clear entire screen and scrollback buffer (not widely supported)
    clear_entire_screen,

    /// Move cursor to the top-left corner (1,1)
    ///
    /// This positions the cursor at the origin point of the terminal screen.
    /// In terminal coordinates, the top-left corner is position (1,1), not (0,0).
    ///
    /// Technical details:
    /// - \x1b[H breaks down as:
    ///   - \x1b = ESC character
    ///   - [ = Start of CSI sequence
    ///   - H = "Cursor Position" command with default parameters
    ///
    /// The H command can accept row and column parameters:
    /// - \x1b[H = Move to (1,1) - top left
    /// - \x1b[5;10H = Move to row 5, column 10
    /// - \x1b[;10H = Move to row 1, column 10 (default row)
    /// - \x1b[5;H = Move to row 5, column 1 (default column)
    move_cursor_to_origin,

    /// Convert the escape sequence enum to its string representation
    ///
    /// This method provides a clean interface for getting the actual escape
    /// sequence bytes that need to be sent to the terminal. The strings are
    /// compile-time constants, so there's no runtime allocation or copying.
    ///
    /// The escape sequences use hexadecimal notation (\x1b) for the ESC
    /// character instead of octal (\033) for better readability and to match
    /// modern conventions.
    ///
    /// Returns: Compile-time string literal containing the escape sequence
    ///
    /// Example:
    /// ```zig
    /// const seq = EscapeSequence.clear_entire_screen;
    /// const bytes = seq.toString(); // "\x1b[2J"
    /// ```
    pub fn toString(self: EscapeSequence) []const u8 {
        return switch (self) {
            .clear_entire_screen => "\x1b[2J",
            .move_cursor_to_origin => "\x1b[H",
        };
    }
};

/// Send an escape sequence to the terminal
///
/// This function writes the raw bytes of an escape sequence to stdout,
/// which the terminal emulator interprets as control commands rather than
/// text to display.
///
/// The function performs unbuffered output directly to the file descriptor,
/// ensuring that the escape sequence is sent immediately without waiting
/// for a buffer flush. This is important for interactive applications where
/// screen updates need to happen in real-time.
///
/// Error handling:
/// If the write operation fails, it could be due to:
/// - stdout being redirected to a file (escape sequences would be written as text)
/// - Terminal disconnection in SSH sessions
/// - System-level I/O errors
/// - Insufficient permissions
///
/// Parameters:
/// - escape_sequence: The escape sequence to send
///
/// Errors: SendEscapeSequenceError if unable to write to stdout
///
/// Example:
/// ```zig
/// try sendEscapeSequence(.clear_entire_screen);
/// ```
fn sendEscapeSequence(escape_sequence: EscapeSequence) OutputError!void {
    _ = posix.write(posix.STDOUT_FILENO, escape_sequence.toString()) catch {
        return OutputError.SendEscapeSequenceError;
    };
}

/// Clear the terminal screen and reset cursor position
///
/// This function performs a complete screen reset by:
/// 1. Clearing all text from the screen
/// 2. Moving the cursor to the top-left corner
///
/// This two-step process ensures a clean slate for drawing new content.
/// The order is important: clearing first, then positioning, ensures that
/// the cursor ends up in a predictable location regardless of where it
/// started.
///
/// Usage patterns:
/// - Call at program startup to initialize a clean screen
/// - Call when switching between different editor modes
/// - Call when refreshing the entire display after major changes
///
/// Terminal compatibility:
/// This function uses only basic VT100 sequences that are supported by
/// essentially all terminal emulators. It should work reliably across:
/// - Different operating systems
/// - SSH connections
/// - Terminal multiplexers
/// - Various terminal applications
///
/// Performance note:
/// Each escape sequence requires a separate write() system call. For
/// applications that need to send many sequences, consider batching
/// them into a single write operation for better performance.
///
/// Errors: Any error from sendEscapeSequence() propagates upward
///
/// Example:
/// ```zig
/// // At program start
/// try clearScreen();
///
/// // Now the terminal is ready for drawing content
/// ```
pub fn clearScreen() !void {
    try sendEscapeSequence(.clear_entire_screen);
    try sendEscapeSequence(.move_cursor_to_origin);
}
