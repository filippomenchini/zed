pub const Action = union(enum) {

    // Movement
    moveCursorUp,
    moveCursorDown,
    moveCursorLeft,
    moveCursorRight,

    // Modals
    setInsertMode,
    setNormalMode,
    setCommandMode,

    // Command mode
    commandCancel,
    commandDelete,
    commandInsert: u8,
    commandRun,
};
