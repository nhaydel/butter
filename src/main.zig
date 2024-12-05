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

const TextBox = struct {
    width: usize,
    height: usize,
    pos: Position,
    text: []const u8,
    fn draw(self: *const @This(), term: *tty.Terminal) !void {
        const border = Border{ .width = self.width, .height = self.height, .pos = self.pos, .borderChar = '*' };
        try border.draw(term);
        try term.moveCursor(self.pos.y + 1, self.pos.x + 1);
        try term.writer.writeAll(self.text);
    }
};

const Border = struct {
    width: usize,
    height: usize,
    pos: Position,
    borderChar: u8,
    fn draw(self: *const @This(), term: *tty.Terminal) !void {
        const borderString = [1]u8{self.borderChar};
        // Draw left side
        for (1..self.height) |curr_y| {
            try term.moveCursor(self.pos.y + curr_y, self.pos.x);
            try term.writer.writeAll(&borderString);
        }
        // Draw Top
        try term.moveCursor(self.pos.y, self.pos.x);
        for (0..self.width / 2 + 1) |_| {
            try term.writer.writeAll(&borderString);
            try term.writer.writeAll(" ");
        }

        // Draw Right side
        for (1..self.height) |curr_y| {
            try term.moveCursor(self.pos.y + curr_y, self.pos.x + self.width);
            try term.writer.writeAll(&borderString);
        }

        // Draw bottom
        try term.moveCursor(self.pos.y + self.height, self.pos.x);
        for (0..self.width / 2 + 1) |_| {
            try term.writer.writeAll(&borderString);
            try term.writer.writeAll(" ");
        }
    }
};

pub fn main() !void {
    var term = try tty.newTerminal();
    defer term.deinit() catch {};
    try term.prepareRawTTY();

    while (true) {
        try render(&term);

        var buffer: [1]u8 = undefined;
        _ = try term.tty.read(&buffer);

        if (buffer[0] == 'q') {
            return;
        }
    }
}

fn render(term: *tty.Terminal) !void {
    var box = TextBox{ .width = 30, .height = 10, .pos = Position{ .x = 10, .y = 10 }, .text = "Woohoo!" };
    try box.draw(term);
}
