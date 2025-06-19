# ZED - A Simple Text Editor in Zig

A basic terminal text editor built with Zig for learning purposes.
Inspired by the [Kilo editor](https://github.com/antirez/kilo) written by [Antirez](https://github.com/antirez) but took an unexpected turn.

## Quick Start

```bash
git clone https://github.com/filippomenchini/zed.git
cd zed
zig build run -- zanluca
```

## Architecture

Clean modular design with dependency injection:
- Terminal abstraction layer
- Action-based command system  
- Separated input/output handling
- Explicit memory management

## How to use

Zed uses "vim motions", modes and commands to operate.
- Use `I` to enter INSERT mode
- Use `:` to enter COMMAND mode
- Use `ESC` to get back to NORMAL mode
- Move with `h j k l` (left, down, up, right) just like in vim
- Save file with `:w`
- Exit with `:q`

## Learning Resources

- [Build Your Own Text Editor](https://viewsourcecode.org/snaptoken/kilo/) - The original Kilo tutorial
- [VT100 User Guide](https://vt100.net/docs/vt100-ug/) - Terminal escape sequences
- [Zig Documentation](https://ziglang.org/documentation/) - Language reference

## What is zanluca?

The correct question is _who is zanluca?_
Zanluca is a friend of mine that was present when I started coding this editor.
I wanted a simple text file to test the program and I did not know what to write
into it.
Zanluca does NOT like setting the table for dinner, but his mom would be really
proud if he really did.

## License

[MIT](LICENSE)
