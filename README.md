# ZED: a simple Zig text EDitor

A minimalist terminal text editor built with Zig, inspired by the classic Kilo editor. ZED focuses on simplicity, performance, and educational value while providing a solid foundation for understanding low-level terminal programming.

## 🚀 Quick Start

```bash
git clone https://github.com/filippomenchini/zed.git
cd zed
zig build run
```

Press `Ctrl+C` to quit.

## 🎓 What You'll Learn

This project serves as an educational resource for understanding terminal programming fundamentals:

### Core Concepts

- **Raw vs Canonical Mode**: How terminals handle input processing
- **VT100 Escape Sequences**: The universal standard for terminal control
- **POSIX System Calls**: Low-level interfaces for terminal manipulation
- **Control Characters**: The bit manipulation behind Ctrl+C and friends

### Historical Context

The techniques used here trace back to 1960s-70s teletypes and early computer terminals. These fundamentals still power every terminal emulator today, making this knowledge both historical and immediately practical.

### Code Quality

Every module is extensively documented with:

- Clear explanations of "mysterious" low-level concepts
- Historical background for why things work the way they do
- Bit manipulation examples with binary representations
- Cross-references to standards and specifications

## 🏗️ Design Philosophy

ZED prioritizes:

- **Educational Value**: Code that teaches while it works
- **Modularity**: Clean separation of concerns
- **Documentation**: Extensive comments explaining the "why" not just the "what"
- **Simplicity**: Minimal dependencies, maximum understanding
- **Compatibility**: VT100 standards ensure universal terminal support

## 🎯 Perfect For

- Learning systems programming in Zig
- Understanding how terminal applications work
- Building your own text editor or console application
- Exploring the intersection of modern programming and computing history
- Anyone curious about what happens when you press Ctrl+C

## 🤝 Contributing

Contributions welcome! Please maintain the educational focus:

- Document complex concepts thoroughly
- Include historical context where relevant
- Keep code beginner-friendly
- Explain the "why" behind technical decisions

## 📖 References

- [Kilo Editor](https://github.com/antirez/kilo) - Original inspiration
- [VT100 Technical Manual](https://vt100.net/docs/vt100-ug/) - Escape sequence reference
- [POSIX Terminal Interface](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/termios.h.html) - Terminal standards

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

---

_Because every programmer should understand how their terminal works._
