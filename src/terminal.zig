const std = @import("std");
const posix = std.posix;

/// Custom error types for terminal operations
const TerminalError = error{
    InitError,
    EnableRawModeError,
    DisableRawModeError,
    ReadingError,
};

/// Terminal management structure for handling raw mode operations
///
/// This struct provides a safe wrapper around POSIX terminal operations,
/// allowing an application to switch between canonical (cooked) and raw modes.
/// Raw mode is essential for terminal-based editors as it allows reading
/// individual keystrokes without waiting for Enter.
pub const Terminal = struct {
    /// Original terminal attributes, saved during initialization
    /// These are restored when raw mode is disabled to return the terminal
    /// to its previous state
    orig_termios: posix.termios,

    /// Initialize the terminal by saving current terminal attributes
    ///
    /// This function captures the current terminal settings so they can be
    /// restored later. It must be called before enabling raw mode.
    ///
    /// Returns: A Terminal instance with saved original settings
    /// Errors: InitError if unable to read current terminal attributes
    pub fn init() TerminalError!Terminal {
        const termios = posix.tcgetattr(posix.STDIN_FILENO) catch {
            return TerminalError.InitError;
        };

        return .{
            .orig_termios = termios,
        };
    }

    /// Enable raw mode for the terminal
    ///
    /// Raw mode disables most terminal processing, allowing the application
    /// to receive individual keystrokes immediately without buffering.
    /// This is essential for editors like vim that need to respond to
    /// single character commands.
    ///
    /// The function modifies several categories of terminal flags:
    ///
    /// INPUT FLAGS (iflag) - Control input processing:
    /// - IXON: Disable XON/XOFF flow control (Ctrl+S/Ctrl+Q)
    /// - ICRNL: Disable carriage return to newline translation
    /// - BRKINT: Disable break signal generation
    /// - INPCK: Disable input parity checking
    /// - ISTRIP: Disable stripping of 8th bit
    ///
    /// OUTPUT FLAGS (oflag) - Control output processing:
    /// - OPOST: Disable all output processing (no \n to \r\n translation)
    ///
    /// CONTROL FLAGS (cflag) - Control hardware settings:
    /// - CSIZE: Set character size to 8 bits (CS8)
    ///
    /// LOCAL FLAGS (lflag) - Control local processing:
    /// - ECHO: Disable echoing of typed characters
    /// - ICANON: Disable canonical mode (line buffering)
    /// - ISIG: Disable signal generation (Ctrl+C, Ctrl+Z)
    /// - IEXTEN: Disable extended input processing
    ///
    /// CONTROL CHARACTERS (cc array):
    /// - VMIN: Minimum characters for non-canonical read (0 = don't wait)
    /// - VTIME: Timeout in tenths of seconds (1 = 100ms timeout)
    ///
    /// Historical Context:
    /// These flags date back to the 1960s-70s era of teletypes and serial
    /// terminals. Many exist for hardware that no longer exists, but are
    /// maintained for compatibility. The "canonical" vs "raw" distinction
    /// comes from early Unix systems where terminals typically operated
    /// in line-oriented mode for efficiency over slow serial connections.
    ///
    /// Errors: EnableRawModeError if unable to set terminal attributes
    pub fn enableRawMode(self: *const Terminal) TerminalError!void {
        var raw = self.orig_termios;

        // === INPUT FLAGS MANIPULATION ===
        // Disable XON/XOFF software flow control
        // XON/XOFF was used to pause/resume data transmission on slow terminals
        // We disable it so Ctrl+S and Ctrl+Q can be used as editor commands
        raw.iflag.IXON = false;

        // Disable automatic carriage return to newline translation
        // On old terminals, Enter sent only \r, which was translated to \n
        // We want raw \r characters for precise control
        raw.iflag.ICRNL = false;

        // Disable break condition signal generation
        // Break was a way to interrupt transmission on serial lines
        raw.iflag.BRKINT = false;

        // Disable input parity checking
        // Parity bits were used for error detection on unreliable connections
        raw.iflag.INPCK = false;

        // Disable stripping of 8th bit from input
        // Old 7-bit systems would strip the high bit; we want full 8-bit input
        raw.iflag.ISTRIP = false;

        // === OUTPUT FLAGS MANIPULATION ===
        // Disable all output processing
        // This prevents the terminal from translating \n to \r\n automatically
        // We want to control exactly what gets sent to the screen
        raw.oflag.OPOST = false;

        // === CONTROL FLAGS MANIPULATION ===
        // Set character size to 8 bits
        // Ensures we can send and receive full 8-bit characters
        raw.cflag.CSIZE = .CS8;

        // === LOCAL FLAGS MANIPULATION ===
        // Disable echo of input characters
        // Prevents typed characters from appearing automatically on screen
        // The editor will control exactly what gets displayed
        raw.lflag.ECHO = false;

        // Disable canonical (line-buffered) input mode
        // In canonical mode, input is buffered until Enter is pressed
        // Raw mode gives us each character immediately
        raw.lflag.ICANON = false;

        // Disable signal generation for interrupt and quit characters
        // Prevents Ctrl+C and Ctrl+\ from sending signals to our process
        // We'll handle these as regular input characters
        raw.lflag.ISIG = false;

        // Disable extended input character processing
        // Disables some special character processing like Ctrl+V literal input
        raw.lflag.IEXTEN = false;

        // === CONTROL CHARACTER SETTINGS ===
        // Set minimum characters for a read to return (0 = don't wait)
        // With VMIN=0, read() will return immediately even if no data available
        raw.cc[@intFromEnum(posix.V.MIN)] = 0;

        // Set timeout for read operations (in tenths of seconds)
        // VTIME=1 means wait up to 100ms for input before timing out
        // This prevents read() from blocking forever when no input is available
        raw.cc[@intFromEnum(posix.V.TIME)] = 1;

        // Apply the new terminal settings
        // TCSA.FLUSH discards any pending input/output before applying changes
        posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.FLUSH, raw) catch {
            return TerminalError.EnableRawModeError;
        };
    }

    /// Disable raw mode and restore original terminal settings
    ///
    /// This function restores the terminal to its state before raw mode
    /// was enabled. It should always be called before the program exits
    /// to ensure the user's terminal is left in a usable state.
    ///
    /// The original settings typically include:
    /// - Line buffering (canonical mode)
    /// - Echo of typed characters
    /// - Signal generation for Ctrl+C, etc.
    /// - Automatic newline processing
    ///
    /// Errors: DisableRawModeError if unable to restore terminal attributes
    pub fn disableRawMode(self: *const Terminal) TerminalError!void {
        posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.FLUSH, self.orig_termios) catch {
            return TerminalError.DisableRawModeError;
        };
    }

    /// Read raw input from the terminal
    ///
    /// In raw mode, this function reads individual characters or escape
    /// sequences directly from the terminal without any processing.
    /// Due to the VMIN=0 and VTIME=1 settings, this function will:
    /// - Return immediately if input is available
    /// - Wait up to 100ms if no input is available
    /// - Return 0 bytes read if timeout expires
    ///
    /// This non-blocking behavior is useful for editors that need to
    /// update the screen periodically even when no input is received.
    ///
    /// Parameters:
    /// - buffer: Slice to store the read data
    ///
    /// Returns: Number of bytes actually read (may be 0 on timeout)
    /// Errors: ReadingError if the read operation fails
    pub fn read(_: *const Terminal, buffer: []u8) TerminalError!usize {
        return posix.read(posix.STDIN_FILENO, buffer) catch {
            return TerminalError.ReadingError;
        };
    }
};
