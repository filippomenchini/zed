pub const Action = enum {
    quit,
    // Movement
    moveCursorUp,
    moveCursorDown,
    moveCursorLeft,
    moveCursorRight,
    // Modals
    setInsertMode,
    setNormalMode,
};
