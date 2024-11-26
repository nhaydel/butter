const std = @import("std");
const fs = std.fs;
const posix = std.posix;

pub const Terminal = struct {
    tty: fs.File = undefined,
    writer: fs.File.Writer = undefined,
    originalTerm: posix.termios = undefined,
    raw: posix.termios = undefined,

    pub fn prepareRawTTY(self: *Terminal) !void {
        self.originalTerm = try posix.tcgetattr(self.tty.handle);
        errdefer self.resetTTY() catch {};

        self.raw = self.originalTerm;
        self.raw.lflag.ECHO = false;
        self.raw.lflag.ICANON = false;
        self.raw.lflag.ISIG = false;
        self.raw.lflag.IEXTEN = false;
        self.raw.iflag.IXON = false;
        self.raw.iflag.ICRNL = false;
        self.raw.iflag.BRKINT = false;
        self.raw.iflag.INPCK = false;
        self.raw.iflag.ISTRIP = false;
        self.raw.oflag.OPOST = false;
        self.raw.cc[@intFromEnum(posix.system.V.TIME)] = 0;
        self.raw.cc[@intFromEnum(posix.system.V.MIN)] = 1;
        try posix.tcsetattr(self.tty.handle, .FLUSH, self.raw);

        try self.hideCursor();
        try self.enterAlt();
        try self.clear();
    }

    pub fn resetTTY(self: *Terminal) !void {
        try self.clear();
        try self.leaveAlt();
        try self.showCursor();
        try self.attributeReset();
        try posix.tcsetattr(self.tty.handle, .FLUSH, self.originalTerm);
    }

    pub fn moveCursor(self: *Terminal, row: usize, col: usize) !void {
        _ = try self.writer.print("\x1B[{};{}H", .{ row + 1, col + 1 });
    }

    fn enterAlt(self: *Terminal) !void {
        try self.writer.writeAll("\x1B[s"); // Save cursor position.
        try self.writer.writeAll("\x1B[?47h"); // Save screen.
        try self.writer.writeAll("\x1B[?1049h"); // Enable alternative buffer.
    }

    fn leaveAlt(self: *Terminal) !void {
        try self.writer.writeAll("\x1B[?1049l"); // Disable alternative buffer.
        try self.writer.writeAll("\x1B[?47l"); // Restore screen.
        try self.writer.writeAll("\x1B[u"); // Restore cursor position.
    }

    fn hideCursor(self: *Terminal) !void {
        try self.writer.writeAll("\x1B[?25l");
    }

    fn showCursor(self: *Terminal) !void {
        try self.writer.writeAll("\x1B[?25h");
    }

    fn attributeReset(self: *Terminal) !void {
        try self.writer.writeAll("\x1B[0m");
    }

    fn clear(self: *Terminal) !void {
        try self.writer.writeAll("\x1B[2J");
    }

    pub fn deinit(self: *Terminal) !void {
        try self.resetTTY();
        self.tty.close();
    }
};

pub fn newTerminal() !Terminal {
    var term = Terminal{};
    term.tty = try fs.cwd().openFile("/dev/tty", .{ .mode = fs.File.OpenMode.read_write });
    errdefer term.tty.close();
    term.writer = term.tty.writer();
    return term;
}
