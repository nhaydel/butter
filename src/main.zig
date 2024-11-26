const std = @import("std");
const tty = @import("tty.zig");
const debug = std.debug;
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const os = std.os;
const math = std.math;

var i: usize = 0;
var size: Size = undefined;

const Size = struct { width: usize, height: usize };

const Position = struct { x: usize, y: usize };

const Border = struct {
    width: usize,
    height: usize,
    pos: Position,
    fn draw(self: Border, term: *tty.Terminal) !void {
        // Draw left side
        for (1..self.height) |curr_y| {
            try term.moveCursor(self.pos.y + curr_y, self.pos.x);
            try term.writer.writeAll("\u{23B8}");
        }
        // Draw Top
        try term.moveCursor(self.pos.y, self.pos.x);
        for (0..self.width) |_| {
            try term.writer.writeAll("\u{23AF}");
        }

        // Draw Right side
        for (1..self.height) |curr_y| {
            try term.moveCursor(self.pos.y + curr_y, self.pos.x + self.width);
            try term.writer.writeAll("\u{23B8}");
        }

        // Draw bottom
        try term.moveCursor(self.pos.y + self.height, self.pos.x);
        for (0..self.width) |_| {
            try term.writer.writeAll("\u{23AF}");
        }
    }
};

pub fn main() !void {
    var term = try tty.newTerminal();
    defer term.deinit() catch {};
    try term.prepareRawTTY();
    // size = try getSize();

    // try posix.sigaction(posix.SIG.WINCH, &posix.Sigaction{
    //    .handler = .{ .handler = handleSigWinch },
    //    .mask = posix.empty_sigset,
    //    .flags = 0,
    // }, null);

    while (true) {
        try render(&term);

        var buffer: [1]u8 = undefined;
        _ = try term.tty.read(&buffer);

        if (buffer[0] == 'q') {
            return;
        }
        // else if (buffer[0] == '\x1B') {
        //    raw.cc[@intFromEnum(posix.system.V.TIME)] = 1;
        //    raw.cc[@intFromEnum(posix.system.V.MIN)] = 0;
        //    try posix.tcsetattr(tty.handle, .NOW, raw);

        //    var esc_buffer: [8]u8 = undefined;
        //    const esc_read = try tty.read(&esc_buffer);

        //    raw.cc[@intFromEnum(posix.system.V.TIME)] = 0;
        //    raw.cc[@intFromEnum(posix.system.V.MIN)] = 1;
        //    try posix.tcsetattr(tty.handle, .NOW, raw);

        //    if (mem.eql(u8, esc_buffer[0..esc_read], "[A")) {
        // Up arrow press
        //        i -|= 1;
        //    } else if (mem.eql(u8, esc_buffer[0..esc_read], "[B")) {
        // Down error pressed, min prevents overflow
        //      i = @min(i + 1, 3);
        //    }
        //}
    }
}

// fn handleSigWinch(_: c_int) callconv(.C) void {
//    size = getSize() catch return;
//    render() catch return;
//}

fn render(term: *tty.Terminal) !void {
    const box = Border{ .width = 30, .height = 10, .pos = Position{ .x = 10, .y = 10 } };
    try box.draw(term);
}

//fn getSize() !Size {
//    const win_size = mem.zeroes(posix.system.winsize);
//    _ = posix.system.ioctl(tty.handle, posix.system.T.IOCGWINSZ, @intFromPtr(&win_size));
//    return Size{
//        .height = win_size.ws_row,
//        .width = win_size.ws_col,
//    };
//}
