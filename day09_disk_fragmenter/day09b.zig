const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();
    const file_reader = file.reader();
    var files = std.ArrayList(FileEntry).init(allocator);
    defer files.deinit();
    var free_slots = std.ArrayList(FileEntry).init(allocator);
    defer free_slots.deinit();

    var expect_file = true;
    var pos: usize = 0;
    while (file_reader.readByte()) |digit| {
        const count: usize = switch (digit) {
            '0'...'9' => digit - '0',
            else => unreachable
        };
        const entry = FileEntry{.pos = pos, .size = count};
        if (expect_file) {
            try files.append(entry);
        } else {
            if (count > 0) {
                try free_slots.append(entry);
            }
        }
        pos += count;
        expect_file = !expect_file;
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    var file_id = files.items.len - 1;
    while (true) {
        var f = &files.items[file_id];
        for (free_slots.items) |*slot| {
            if (slot.pos >= f.pos) {
                break;
            }
            if (slot.size >= f.size) {
                f.pos = slot.pos;
                slot.size -= f.size;
                slot.pos += f.size;
                break;
            }
        }
        if (file_id == 0) {
            break;
        }
        file_id -= 1;
    }

    var check_sum: u64 = 0;
    for (files.items, 0..) |f, f_id| {
        for (f.pos..(f.pos + f.size)) |p| {
            check_sum += p * f_id;
        }
    }

    std.debug.print("{d}\n", .{check_sum});
}

const FileEntry = struct {
    pos: usize,
    size: usize
};