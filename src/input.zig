const std = @import("std");
const terminal = @import("terminal.zig");
const config = @import("config.zig");
const output = @import("output.zig");

const posix = std.posix;

/// Error types for input processing operations
///
/// These errors represent different failure modes that can occur
/// during input handling in the editor.
const InputError = error{
    /// Failed to read from the terminal
    /// This can happen if the terminal is in an invalid state or
    /// if there are system-level I/O issues
    ReadError,

    /// Failed to process a keypress
    /// This is a general error for when keypress processing fails
    /// for reasons other than reading from the terminal
    ProcessKeypressError,
};

/// Read a single character from the terminal
///
/// This function provides a low-level interface for reading individual
/// characters from the terminal in raw mode. It handles the conversion
/// from the terminal's byte-oriented interface to a single character.
///
/// In raw mode, characters are available immediately without waiting
/// for Enter to be pressed. Due to the VMIN=0 and VTIME=1 settings
/// in the terminal configuration, this function will:
///
/// - Return immediately if a character is available
/// - Wait up to 100ms if no character is available
/// - Return 0 if the timeout expires (though we treat this as valid input)
///
/// Design note: This function returns the raw byte value, including
/// control characters, escape sequences, and special keys. Higher-level
/// functions are responsible for interpreting these values.
///
/// Parameters:
/// - running_terminal: Pointer to an initialized Terminal instance in raw mode
///
/// Returns: The byte value of the character read (0-255)
///
/// Errors: ReadError if unable to read from the terminal
///
/// Example:
/// ```zig
/// const char = try readKey(&terminal);
/// if (char == 27) {
///     // This might be the start of an escape sequence (arrow keys, etc.)
/// }
/// ```
fn readKey(running_terminal: *const terminal.Terminal) InputError!u8 {
    var character: [1]u8 = .{0};
    _ = running_terminal.read(&character) catch {
        return InputError.ReadError;
    };

    return character[0];
}

/// Process a single keypress and execute the corresponding action
///
/// This function represents the core input handling loop of the editor.
/// It reads a character from the terminal, looks up the associated action
/// in the configuration, and executes that action.
///
/// The function implements a simple but effective input processing pattern:
/// 1. Read raw character from terminal
/// 2. Look up action in configuration
/// 3. Execute action if found
/// 4. Ignore unknown keys (graceful degradation)
///
/// Design philosophy:
/// This function follows the "do one thing well" principle. It handles
/// exactly one keypress and then returns, allowing the caller to control
/// the overall program flow. This makes the code easier to test and debug.
///
/// Error handling strategy:
/// - Terminal read errors are propagated to the caller
/// - Unknown keys are silently ignored (no error)
/// - Action execution errors would be handled here (future expansion)
///
/// Parameters:
/// - running_terminal: Terminal instance for reading input
/// - editor_config: Configuration containing key bindings
///
/// Errors: Any error from readKey() propagates upward
///
/// Example usage:
/// ```zig
/// // Main editor loop
/// while (true) {
///     try processKeypress(&terminal, &config);
///     // The function handles one keypress and returns
///     // Additional logic like screen updates would go here
/// }
pub fn processKeypress(running_terminal: *const terminal.Terminal, editor_config: *const config.Config) !void {
    const character = try readKey(running_terminal);

    if (editor_config.findAction(character)) |action| {
        switch (action) {
            // Immediate program termination
            // Note: This bypasses defer statements and cleanup code
            // For a production editor, consider returning a quit signal instead
            .quit => {
                try output.clearScreen();
                posix.exit(0);
            },
        }
    }

    // If no action is found for this character, we silently ignore it
    // This allows for graceful handling of unknown keys without errors
    // Future: might want to log unknown keys for debugging purposes
}
