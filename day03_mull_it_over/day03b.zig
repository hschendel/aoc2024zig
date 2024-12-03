const std = @import("std");
const eql = std.mem.eql;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const file_name = args[1];
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();
    const data = try file.reader().readAllAlloc(allocator, 100000);
    defer allocator.free(data);

    var result: u64 = 0;
    var pos: usize = 0;
    var enabled = true;

    while (pos < data.len) {
        if (enabled) {
            if (parseDont(data, pos)) {
                enabled = false;
                pos += dontLen;
                continue;
            }
            const mul = parseMul(data, pos);
            if (mul == null) {
                pos += 1;
                continue;
            }
            result += mul.?.a * mul.?.b;
            pos += mul.?.chars;
        } else {
            if (parseDo(data, pos)) {
                enabled = true;
                pos += doLen;
            } else {
                pos += 1;
            }
        }
    }

    std.debug.print("{d}", .{result});
}

const doLen = "do()".len;
const dontLen = "don't()".len;

fn parseDo(buffer: []u8, pos: usize) bool {
    return (pos + doLen) <= buffer.len and eql(u8, buffer[pos..pos + doLen], "do()");
}

fn parseDont(buffer: []u8, pos: usize) bool {
    return (pos + dontLen) <= buffer.len and eql(u8, buffer[pos..pos + dontLen], "don't()");
}

const Mul = struct {
    a: u64,
    b: u64,
    chars: usize
};

fn parseMul(buffer: []u8, pos: usize) ?Mul {
    const min_len = 8;
    if ((pos + min_len) > buffer.len) {
        return null;
    }
    if (!eql(u8, buffer[pos..pos+4], "mul(")) {
        return null;
    }
    var posn: usize = pos + 4;
    const a = parseInt(buffer, posn);
    if (a == null) {
        return null;
    }
    posn += a.?.chars;
    if ((posn + 3) >= buffer.len) {
        return null;
    }
    if (buffer[posn] != ',') {
        return null;
    }
    posn += 1;
    const b = parseInt(buffer, posn);
    if (b == null) {
        return null;
    }
    posn += b.?.chars;
    if ((posn + 1) >= buffer.len) {
        return null;
    }
    if (buffer[posn] != ')') {
        return null;
    }
    return Mul{.a = a.?.v, .b = b.?.v, .chars = 6 + a.?.chars + b.?.chars};
}

const Int = struct {
    v: u64,
    chars: usize
};

fn parseInt(buffer: []u8, pos: usize) ?Int {
    var i = Int{.v = 0, .chars = 0};
    var posn = pos;
    while(posn < buffer.len) {
        switch(buffer[posn]) {
            '0' ... '9' => |c| {
                i.v *= 10;
                i.v += (c - '0');
                i.chars += 1;
                if (i.chars > 3) {
                    return null;
                }
            },
            else => {
                if (i.chars == 0) {
                    return null;
                }
                return i;
            }
        }
        posn += 1;
    }
    return i;
}